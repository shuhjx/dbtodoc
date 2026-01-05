require 'yaml'
require 'active_support/core_ext/string/inflections'
module Dbtodoc
  class I18n
    def initialize(path)
      @models = Hash.new { |h, k| h[k] = {} }
      @attributes = Hash.new { |h, k| h[k] = {} }
      Dir.glob(path).each do |f|
        yaml = YAML.load_file(f)
        lang = yaml.keys[0]
        next if yaml[lang]['activerecord'].blank?
        if data = yaml[lang]['activerecord']['models']
          @models[lang].merge!(data)
        end
        if data = yaml[lang]['activerecord']['attributes']
          @attributes[lang].merge!(data)
        end
      end
    end

    def table_name(name)
      # 单词复数转单数
      name = name.singularize if name.end_with?('s')
      # 尝试从i18n配置中获取表名
      @models.map do |lang, models|
        models.key?(name.downcase) ? models[name.downcase] : nil
      end.compact.join("\n").presence || name.titleize
    end

    def column_name(tablename, name)
      tablename = tablename.singularize if tablename.end_with?('s')
      # 尝试从i18n配置中获取列名
      @attributes.map do |lang, attrs|
        attrs.key?(tablename.downcase) && attrs[tablename.downcase].key?(name.downcase) ? attrs[tablename.downcase][name.downcase] : nil
      end.compact.join("\n").presence || name.titleize
    end
  end
end