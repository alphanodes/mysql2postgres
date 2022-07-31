# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class PostgresDbWriterTest < Test::Unit::TestCase
  class << self
    def startup
      seed_test_database
    end
  end

  def setup
    @options = options_from_file
    @options[:suppress_data] = true
    @options[:suppress_ddl] = true
  end

  def test_pg_connection
    assert_nothing_raised do
      Mysql2postgres::PostgresDbWriter.new Tempfile.new('mysql2postgres_test_').path,
                                           @options[:destination]
    end
  end
end
