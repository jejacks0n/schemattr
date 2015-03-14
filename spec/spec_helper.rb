require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require "active_record"
require "schemattr"

# connect to an in memory db and create our table
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.connection.execute(<<-SQL)
  CREATE TABLE "users" ("id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    "name" string,
    "settings" text,
    "preferences" text,
    "general" text,
    "custom" text,
    "active" boolean,
    "created_at" datetime,
    "updated_at" datetime
  )
SQL

# require support libraries
Dir[File.expand_path("../support/*.rb", __FILE__)].each { |f| require f }

RSpec.configure do |config|
  config.order = "random"
  config.run_all_when_everything_filtered = true

  config.before(:each) do
    # turn on active record logging if needed
    ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  # clean up our table after each spec
  config.after(:each) do
    # turn off active record logging
    # ActiveRecord::Base.logger = nil
    ActiveRecord::Base.connection.execute(<<-SQL)
      DELETE FROM "users";
    SQL
  end
end
