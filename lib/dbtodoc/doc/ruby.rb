module Dbtodoc
  module Doc
    module Ruby
      def self.dump(filename)
        File.open(filename, 'w:utf-8') do |file|
          if ActiveRecord.version >= '7.1'
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, file)
          else
            ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
          end
        end
      end
    end
  end
end