module Dbtodoc
  module Doc
    module Sql
      def self.dump(filename)
        pool =  ActiveRecord::Base.connection_pool
        db_config = pool.db_config
        klass = case db_config.adapter
          when /mysql|trilogy/
            'ActiveRecord::Tasks::MySQLDatabaseTasks'
          when /postgresql/
            'ActiveRecord::Tasks::PostgreSQLDatabaseTasks'
          when /sqlite/
            'ActiveRecord::Tasks::SQLiteDatabaseTasks'
          else
            raise "Unknown adapter: #{db_config.adapter}"
          end
        klass = klass.constantize 
        converted = klass.respond_to?(:using_database_configurations?) && klass.using_database_configurations?
        # db_config = ActiveRecord::Base.configurations.resolve(db_config)
        config = converted ? db_config : db_config.configuration_hash
        task = db_config.adapter =~ /sqlite/ ? klass.new(config, '.') : klass.new(config)

        flags = nil
        # flags = ["--exclude-table-data '*'", '--no-comments', '--no-publications', '--no-subscriptions', '--no-security-labels', '--no-tablespaces', '--no-unlogged-table-data'] if db_config.adapter =~ /postgresql/
        task.structure_dump(filename, flags)
      end
    end
  end
end