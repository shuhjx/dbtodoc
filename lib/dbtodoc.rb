# frozen_string_literal: true

require_relative "dbtodoc/version"
require 'active_record'
require 'yaml'
require 'fileutils'
require 'erb'

if Psych::VERSION >= '4.0'
  module Psych
    class << self
      alias_method :original_safe_load, :safe_load

      def safe_load(*args, **kwargs)
        kwargs[:aliases] = true # 允许使用别名
        original_safe_load(*args, **kwargs)
      end
    end
  end
end

module Dbtodoc
  class Error < StandardError; end
  
  def self.start(options)
    path = options[:path] || '.'

    all_db_configs = {}
    db_config_file = File.join(path, 'config/database.yml')
    if File.exist?(db_config_file)
      # 读取数据库配置文件
      YAML.load_file(db_config_file).each do |_, config|
        next if config['database'].blank?
        next if config['adapter'] =~ /sqlite/
        config.each do |k, v|
          config[k] = ERB.new(v).result if v.is_a?(String)
        end
        all_db_configs[config['database']] = config
      end
    end
    # 查找sqlite数据库 find . -name "*.sqlite3"
    Dir.glob(File.join(path, '**/*.{sqlite,sqlite3}')).each do |file|
      db_name = File.basename(file)
      all_db_configs[db_name] = {
        'adapter' => 'sqlite3',
        'database' => file
      }
    end

    db_name = if all_db_configs.keys.size == 1
        # 如果只有一个数据库，直接使用它
        all_db_configs.keys.first
      else
        require 'cli/ui' #https://github.com/shopify/cli-ui
        # 如果有多个数据库，选择一个
        CLI::UI.ask('Select database:', options: all_db_configs.keys)
      end
    exit if db_name.blank?

    # 读取数据库配置的adapter动态加载对应库
    adapter = all_db_configs[db_name]['adapter']
    case adapter
    when 'mysql2'
      require 'mysql2'
    when 'postgresql'
      require 'pg'
    when 'sqlite3'
      require 'sqlite3'
      _tmp = all_db_configs[db_name].update('database' => File.join(path, db_name))
      db_name = File.basename(db_name)
      all_db_configs[db_name] = _tmp
    else
      puts "Unknown adapter: #{adapter}"
      exit 1
    end

    # 连接数据库
    ActiveRecord::Base.establish_connection(all_db_configs[db_name])

    # 确保tmp目录存在
    FileUtils.mkdir_p File.join(path, 'tmp')
    
    format = options[:format].downcase
    case format
    when 'sql'
      filename = File.join(path, "tmp/#{db_name}.sql")
      require_relative File.join(__dir__, 'dbtodoc/doc/sql.rb')
      Dbtodoc::Doc::Sql.dump(filename)
      puts "SQL file: #{filename}"
    when 'ruby', 'csv', 'excel'
      schema_file = File.join(path, "tmp/#{db_name}.rb")
      require_relative File.join(__dir__, 'dbtodoc/doc/ruby.rb')
      # 生成数据库 schema 文件
      Dbtodoc::Doc::Ruby.dump(schema_file)
      if format == 'ruby'
        puts "Ruby file: #{schema_file}"
        exit
      end
      require_relative File.join(__dir__, 'dbtodoc/schema.rb')
      ActiveRecord::Schema.set_doc_format(options[:format])
      #执行schema.rb文件，生成csv|excel文件
      eval File.read(schema_file)
      puts "CSV file: #{File.join(path, "tmp/#{db_name}.csv")}" if options[:format] == 'csv'
      puts "Excel file: #{File.join(path, "tmp/#{db_name}.xlsx")}" if options[:format] == 'excel'
    else
      puts "Unknown format: #{options[:format]}"
    end
  end
end
