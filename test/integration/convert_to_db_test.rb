# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class ConvertToDbTest < Test::Unit::TestCase
  class << self
    def startup
      seed_test_database
    end
  end

  def setup
    @mysql2postgres = instance_from_file
    @options = @mysql2postgres.options
    @options[:force_truncate] = true
    @options.delete :tables # convert all available tables

    @mysql2postgres.convert
    @mysql2postgres.writer.connection.open
  end

  def teardown
    @mysql2postgres&.writer&.connection&.finish
  end

  def test_table_creation
    tables = @mysql2postgres.writer.connection.tables
    assert tables.include?('numeric_types_basics')
  end
end
