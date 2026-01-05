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
    Dir.chdir(path) if path != '.' # 切换到目标目录

    db_config_file = File.join(path, 'config/database.yml')
    unless File.exist?(db_config_file)
      puts "#{db_config_file}: 文件或目录不存在"
      exit 1
    end
    # 读取数据库配置文件
    all_db_configs = YAML.load_file(db_config_file).each_with_object({}) do |(_, config), h|
      next if config['database'].blank?
      config.each do |k, v|
        config[k] = ERB.new(v).result if v.is_a?(String)
      end
      h[config['database']] = config
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
    when 'pg'
      require 'pg'
    when 'sqlite3'
      require 'sqlite3'
    else
      puts "Unknown adapter: #{adapter}"
      exit 1
    end

    # 连接数据库
    ActiveRecord::Base.establish_connection(all_db_configs[db_name])

    # 确保tmp目录存在
    FileUtils.mkdir_p File.join(path, 'tmp')

    # 生成数据库 schema 文件
    schema_file = File.join(path, "tmp/#{db_name}_schema.rb")
    File.open(schema_file, 'w:utf-8') do |file|
      if ActiveRecord.version >= '7.1'
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, file)
      else
        ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
      end
    end

    case options[:type].downcase
    when 'schema'
      puts "Schema file: #{schema_file}"
    when 'csv', 'excel'
      require_relative File.join(__dir__, 'dbtodoc/schema.rb')
      ActiveRecord::Schema.set_doc_type(options[:type])
      #执行schema.rb文件，生成csv|excel文件
      eval File.read(schema_file), binding
      puts "CSV file: #{File.join(path, "tmp/#{db_name}.csv")}" if options[:type] == 'csv'
      puts "Excel file: #{File.join(path, "tmp/#{db_name}.xlsx")}" if options[:type] == 'excel'
    else
      puts "Unknown type: #{options[:type]}"
    end
  end
end
