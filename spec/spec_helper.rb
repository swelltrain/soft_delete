require 'bundler/setup'
require 'soft_delete'

require 'database_cleaner'
require 'with_model'

DatabaseCleaner.strategy = :transaction

RSpec.configure do |config|
  config.before :suite do
    ActiveRecord::Base.establish_connection adapter: 'sqlite3', database: ':memory:'
  end

  config.before :each do
    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
  end

  config.extend WithModel

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.order = :random

  Kernel.srand config.seed
end
