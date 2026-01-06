# frozen_string_literal: true

require_relative "lib/dbtodoc/version"

Gem::Specification.new do |spec|
  spec.name = "dbtodoc"
  spec.version = Dbtodoc::VERSION
  spec.authors = ["shuhjx"]
  spec.email = ["shuh_jx@163.com"]

  spec.summary = "将 Rails 项目的数据库 schema 导出为文档"
  spec.description = "将 Rails 项目的数据库 schema 导出为文档，支持 ruby, sql, csv, excel 格式"
  spec.homepage = "https://github.com/shuhjx/dbtodoc"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.executable = 'dbtodoc'
  spec.require_paths = ["lib"]

  # 配置 gem 依赖
  spec.add_dependency "activerecord", ">= 5.0.0"
  spec.add_dependency "mysql2"
  spec.add_dependency "pg"
  spec.add_dependency "sqlite3"
  spec.add_dependency "csv" # 生成 CSV 文件
  spec.add_dependency "rubyXL", ">= 3.4" # 生成 Excel 文件
  spec.add_dependency "yaml" # 解析数据库配置文件、I18n配置文件
  spec.add_dependency "optparse" # 解析命令行参数
  spec.add_dependency "cli-ui" # 命令行界面工具

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
