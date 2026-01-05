require 'csv'
module Dbtodoc
  module Doc
    module Csv
      DOC_HEADER = %w(表名 字段名 类型 NULL許可 默认値 日本語名 説明 样本数据 索引名)

      private
      def before_define
        file_path = File.join(Dir.pwd, "tmp/#{database}.csv")
        @csv = File.open(file_path, 'w:utf-8') # 以写入模式打开文件，覆盖原有内容
      end

      def after_define
        @csv.close if @csv # 确保文件关闭
      end

      def write_to_doc(table_name, table_columns)
        #以追加模式打开文件
        row = CSV.generate_line(DOC_HEADER)
        @csv.write(row)
        table_columns.each do |rows|
          row = CSV.generate_line([table_name, rows[:column_name], rows[:type], rows[:null], rows[:default], rows[:comment], rows[:description], rows[:sample_data], rows[:index_name]])
          @csv.write(row)
        end
        @csv.write("\n")
      end
    end
  end
end