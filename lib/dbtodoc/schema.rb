=begin
require 'active_record'
# 方法重写
module ActiveRecord
  class Schema
    class << self
      alias_method :original_get, :'[]'
      def [](version)
        @class_for_version ||= {}
        @class_for_version[version] ||= Class.new do
          # include Definition
        end
      end
    end
  end
end
#TODO
# 方法恢复
module ActiveRecord
  class Schema
    class << self
      ::ActiveRecord::Schema.instance_variable_get('@class_for_version').clear rescue nil
      alias_method :'[]', :original_get
      undef_method :original_get
    end
  end
end
=end
require 'active_record'
require_relative './definition.rb'
module ActiveRecord
  class Schema
    class << self
      alias_method :original_get, :'[]'
      def [](version)
        @class_for_version ||= {}
        @class_for_version[version] ||= Class.new do
          include ::Dbtodoc::Definition
          if @@doc_format_module
            include @@doc_format_module
          end
        end
      end

      def set_doc_format(format)
        @@doc_format_module = case format
          when 'csv'
            require_relative('./doc/csv.rb')
            ::Dbtodoc::Doc::Csv
          when 'excel'
            require_relative './doc/excel.rb'
            ::Dbtodoc::Doc::Excel
          else
            raise ArgumentError, "Invalid doc format: #{format}"
          end
      end
    end
  end
end