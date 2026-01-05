require 'active_record'
require_relative './i18n.rb'

module Dbtodoc
  module Definition
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def define(info = {}, &block)
        new.define(info, &block)
      end
    end

    def define(info, &block)
      before_define()
      instance_eval(&block)
    ensure
      after_define()
    end

    def index(column_names, **options)
      @table_columns.each do |row|
        next if !column_names.include?(row[:column_name])
        row[:index_name] = options[:name]
        break if column_names.size == 1
      end
    end

    def i18n
      @_i18n ||= Dbtodoc::I18n.new(File.join(Dir.pwd, 'config/locales/*.yml'))
    end

    def database
      @_database ||= ActiveRecord::Base.connection.current_database
    end
    private
    # 写入文档
    def write_to_doc(table_name, table_columns)
      raise 'Please override write_to_doc method!'
    end
    def before_define
      #TODO 执行scheam.rb前
    end
    def after_define
      #TODO 执行scheam.rb后
    end

    def add_row(column_name, type, **options)
      # puts "table: #{@table_name}, column: #{column_name}, sql_type: #{type}"
      default = options[:default]
      default = default.call if default.respond_to?(:call)
      comment = options[:comment] || i18n.column_name(@table_name, column_name)
      @table_columns << {
        column_name: column_name,
        comment: comment,
        type: type,
        null: options[:null],
        primary_key: options[:primary_key],
        default: default,
        description: nil,
        sample_data: nil,
        index_name: nil
      }
    end

    def add_primary_key_row(options)
      id_options = options[:id]
      return if id_options == false
      id_options ||= {type: :bigint}
      primary_key = options[:primary_key] || :id
      id_options = {type: id_options} unless id_options.is_a?(Hash)
      type = id_options[:type] || :bigint
      id_options[:limit] = type == :bigint ? 8 : nil # 默认bigint
      id_options[:null] = false
      id_options[:comment] ||= 'ID'
      id_options[:primary_key] = true
      send(type, primary_key, **id_options)
    end

    def create_table(table_name, **options, &block)
      @table_name = table_name
      @table_columns = [] #||= Hash.new { |hash, key| hash[key] = [] }
      add_primary_key_row(options)
      block.call(self)
      # 写入文档
      write_to_doc(table_name, @table_columns)
    end

    def add_foreign_key(from_table, to_table, **options)
      #TODO 外键
    end

    def method_missing(name, *args, &block)
      type = case name
        when :bigint
          ActiveRecord::Type.registry.lookup(:big_integer)
        else 
          ActiveRecord::Type.registry.lookup(name.to_sym) rescue nil
        end
      if type
        column = args[0]
        options = args[1] || {}
        # 调用type_to_sql方法
        sql_type = ActiveRecord::Base.connection.schema_creation.send(:type_to_sql, type.type, **options)
        add_row(column, sql_type, **options)
      else
        puts '------------'
        puts "name: #{name}, args: #{args}"
        puts '------------'
        super
      end
    end
  end
end