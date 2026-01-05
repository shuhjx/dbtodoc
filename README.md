# DBToDoc

DBToDoc 是一个专门用于将 Rails 项目的数据库 schema 导出为文档的Ruby gem。它支持多种输出格式，包括 schema.rb、CSV 和 Excel，帮助开发者快速生成数据库文档。

## ✨ 功能特性

- 🚀 **多格式支持**：导出为 schema.rb、CSV 或 Excel 格式，默认 Excel
- 🗄️ **多数据库兼容**：支持 MySQL、PostgreSQL、SQLite
- 🌐 **国际化支持**：自动读取 Rails 的 locales 文件进行字段翻译
- 🎨 **美观输出**：Excel 格式支持样式设置和颜色主题
- 🔍 **智能分析**：自动解析数据库配置和表结构
- 📊 **详细文档**：包含字段名、类型、约束、默认值等完整信息

## 📋 系统要求

- Ruby >= 2.6.0
- Rails 项目（包含 config/database.yml）
- 支持的数据库：MySQL、PostgreSQL、SQLite

## 🚀 安装

### 从 Rubygems 安装

```bash
gem install dbtodoc
```

### 从源码安装

```bash
git clone https://github.com/shuhjx/dbtodoc.git
cd dbtodoc
gem build dbtodoc.gemspec
gem install dbtodoc-*.gem
```

## 📖 使用方法

### 基本用法

DBToDoc 提供了一个简单的命令行接口：

```bash
# 导出为 schema.rb 格式
dbtodoc --type=schema

# 导出为 CSV 格式
dbtodoc --type=csv

# 导出为 Excel 格式
dbtodoc --type=excel

# 指定项目路径
dbtodoc --path=/path/to/rails/project --type=excel
```

### 在 Ruby 代码中使用

```ruby
require 'dbtodoc'

# 导出为 schema.rb 格式
Dbtodoc.start(type: 'schema')

# 导出为 CSV 格式
Dbtodoc.start(type: 'csv')

# 导出为 Excel 格式
Dbtodoc.start(type: 'excel')

# 指定项目路径
Dbtodoc.start(path: '/path/to/rails/project', type: 'excel')
```

## 📊 输出格式说明

### CSV 格式
CSV 文件包含以下列：
- 表名
- 字段名
- 类型
- NULL许可
- 默认值
- 日本語名（通过 i18n 获取）
- 说明
- 样本数据
- 索引名

### Excel 格式
Excel 文件具有以下特性：
- 📋 每张表单独分组显示
- 🎨 专业的颜色主题：
  - 蓝色：表名行
  - 绿色：表头
  - 白色：数据行
  - 浅绿色：主键字段
- 📏 自动调整列宽
- 🔤 支持日文字体（MS Pゴシック）
- 📐 完整的边框样式

Excel 输出包含以下列：
- フィールド名（字段名）
- 型（类型）
- NULL許可（NULL许可）
- デフォルト値（默认值）
- 日本語名（日文字段名）
- 説明（说明）
- サンプルデータ（样本数据）
- 索引名（索引名）

## 🌍 国际化支持

DBToDoc 自动读取 Rails 项目的 `config/locales/*.yml` 文件，支持以下国际化特性：

- 📝 **表名翻译**：自动将英文表名转换为本地语言
- 🏷️ **字段名翻译**：为字段名提供多语言支持
- 🔄 **智能复数处理**：自动处理单复数形式转换

示例 locales 配置：

```yaml
# config/locales/ja.yml
ja:
  activerecord:
    models:
      user: ユーザー
      post: 投稿
    attributes:
      user:
        name: 名前
        email: メール
```

## 🔧 技术架构

### 核心组件

1. **Dbtodoc::Schema** - 重写 ActiveRecord::Schema 方法，拦截表定义过程
2. **Dbtodoc::Definition** - 处理表和字段定义的收集
3. **Dbtodoc::I18n** - 提供国际化支持
4. **Dbtodoc::Doc::Csv** - CSV 格式导出
5. **Dbtodoc::Doc::Excel** - Excel 格式导出

### 工作流程

```
读取 database.yml → 连接数据库 → 生成 schema.rb → 转换为目标格式
```

## 📁 文件输出位置

所有输出文件都保存在 Rails 项目的 `tmp/` 目录下：

```
tmp/
├── {database_name}_schema.rb    # schema 格式
├── {database_name}.csv          # CSV 格式
└── {database_name}.xlsx         # Excel 格式
```

## 🛠️ 开发环境设置

### 克隆项目

```bash
git clone https://github.com/shuhjx/dbtodoc.git
cd dbtodoc
```

### 安装依赖

```bash
bundle install
```

### 运行测试(待完成)

```bash
rake spec
```

### 构建 gem

```bash
rake build
```

## 🙏 致谢

感谢以下开源项目：
- [RubyXL](https://rubyxl.github.io/) - Excel 文件处理
- [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html) - 数据库抽象层
- [CLI::UI](https://github.com/shopify/cli-ui) - 用户界面组件