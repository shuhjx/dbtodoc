require 'rubyXL'
require 'rubyXL/convenience_methods'
require 'fileutils'
module Dbtodoc
  module Doc
    module Excel
      DOC_HEADER = %w(フィールド名 型 NULL許可 デフォルト値 日本語名 説明 サンプルデータ 索引名)

      private
      def before_define
        @file_path = File.join(Dir.pwd, "tmp/#{database}.xlsx")
        File.delete(@file_path) if File.exist?(@file_path) # 如果文件存在，则删除
        @workbook = RubyXL::Workbook.new # 创建新的 Excel 工作簿
        @worksheet = @workbook.worksheets.first # 获取第一个工作表
        @max_row = 0 # 最大行索引
        @col_max_widths = Hash.new { |h, k| h[k] = 0 } # 列索引 => 最大宽度
      end

      def after_define
        # 设置列宽（Excel 列宽单位 ≈ 字符数 + 一些边距）
        @col_max_widths[0] = 1 # 第一列（索引列）宽度设为 1 * 1.5 + 2 = 3.5
        @col_max_widths.each do |col_index, width|
          # 限制最大宽度（避免过宽），例如不超过 50
          adjusted_width = [width * 1.5 + 2, 50].min # +2 为边距
          @worksheet.change_column_width(col_index, adjusted_width)
        end
        # 保存Excel文件
        @workbook.write @file_path
      end

      # 实现将数据库 schema 导出到 Excel 文件的方法
      def write_to_doc(table_name, table_columns)
        # 写入2行空行
        add_blank_row(2)
        # 写入表名
        add_table_name_row(table_name)
        # 写入表头
        add_header_row
        # 写入数据
        table_columns.each_with_index do |rows, index|
          a_row = [rows[:column_name].to_s, rows[:type], rows[:null], rows[:default], rows[:comment], rows[:description], rows[:sample_data], rows[:index_name]]
          add_column_row(a_row, rows[:primary_key] ? :id_column : :column)
        end
      end

      def add_table_name_row(table_name)
        [table_name, i18n.table_name(table_name), *Array.new(DOC_HEADER.size - 2, nil)].each_with_index do |value, col|
          cell = @worksheet.add_cell(@max_row, col + 1, value)
          # 设置背景颜色（蓝色）
          set_cell_style(cell, :table_name)
        end
        @max_row += 1
      end

      def add_blank_row(count = 1)
        count.times do
          @worksheet.add_cell(@max_row, 0, nil)
          @max_row += 1
        end
      end

      def add_header_row
        DOC_HEADER.each_with_index do |value, col|
          @col_max_widths[col+1] = [@col_max_widths[col+1], value.to_s.length].max if value
          cell = @worksheet.add_cell(@max_row, col + 1, value)
          # 设置背景颜色（浅绿色）
          set_cell_style(cell, :header)
        end
        @max_row += 1
      end

      def add_column_row(cols, cell_type = :column)
        cols.each_with_index do |value, col|
          @col_max_widths[col+1] = [@col_max_widths[col+1], value.to_s.length].max if value
          cell = @worksheet.add_cell(@max_row, col + 1, value)
          # 设置背景颜色（白色）
          set_cell_style(cell, cell_type)
        end
        @max_row += 1
      end

      # 辅助方法：设置单元格背景颜色
      def set_cell_style(cell, cell_type)
        @h_style_index ||= Hash.new { |h, k| h[k] = create_style_index(k) }
        style_index = @h_style_index[cell_type]
        
        # 应用样式到单元格
        cell.style_index = style_index
      end

      def create_style_index(cell_type)
        rgb_color = case cell_type
        when :header then '4EE257'
        when :table_name then '000090'
        when :column then 'FFFFFF'
        when :id_column then 'CCFFCC'
        else raise "Unknown cell type: #{cell_type}"
        end
        fill = RubyXL::Fill.new
        pattern_fill = RubyXL::PatternFill.new
        pattern_fill.pattern_type = 'solid'
        pattern_fill.fg_color = RubyXL::Color.new(rgb: rgb_color)
        pattern_fill.bg_color = RubyXL::Color.new(rgb: rgb_color)
        fill.pattern_fill = pattern_fill
        # 添加到工作簿的样式表
        @workbook.stylesheet.fills << fill
        # 获取新的 fill_id
        fill_id = @workbook.stylesheet.fills.size - 1

        # 创建新的 XF 样式
        xf = RubyXL::XF.new
        xf.fill_id = fill_id
        xf.apply_fill = 1  # 使用1而不是true
        # 添加到工作簿的单元格样式
        @workbook.stylesheet.cell_xfs << xf

        # 设置字体「ＭＳ Ｐゴシック」
        font = RubyXL::Font.new
        font.name = RubyXL::StringValue.new(val: 'ＭＳ Ｐゴシック')
        font.sz = RubyXL::FloatValue.new(val: 12)
        if cell_type == :table_name
          font.color = RubyXL::Color.new(rgb: 'FFFFFF')
          font.b = RubyXL::BooleanValue.new(val: true)
        else
          font.color = RubyXL::Color.new(rgb: '000000')
          font.b = RubyXL::BooleanValue.new(val: false)
        end
        @workbook.stylesheet.fonts << font
        font_id = @workbook.stylesheet.fonts.size - 1
        xf.font_id = font_id

        if @cell_border_index.nil?
          border = RubyXL::Border.new
          # 边框样式，可选值：hairline, thin, medium, thick
          border.left = RubyXL::BorderEdge.new(style: 'medium')
          border.right = RubyXL::BorderEdge.new(style: 'medium')
          border.top = RubyXL::BorderEdge.new(style: 'medium')
          border.bottom = RubyXL::BorderEdge.new(style: 'medium')
          edge_color = '000000' # 黑色边框
          border.set_edge_color(:left, edge_color)
          border.set_edge_color(:right, edge_color)
          border.set_edge_color(:top, edge_color)
          border.set_edge_color(:bottom, edge_color)
          @workbook.stylesheet.borders << border
          @cell_border_index = @workbook.stylesheet.borders.size - 1
        end
        xf.border_id = @cell_border_index
        
        # 获取新的 style_index
        style_index = @workbook.stylesheet.cell_xfs.size - 1
        return style_index
      end
    end
  end
end