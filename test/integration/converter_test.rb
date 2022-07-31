# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class ConverterTest < Test::Unit::TestCase
  class << self
    def startup
      seed_test_database option_file: 'config_to_file'
    end
  end

  def setup
    @options = options_from_file 'config_to_file'
    @options[:suppress_data] = true
    @options[:suppress_ddl] = true

    @destfile = get_temp_file 'mysql2postgres_test'
  end

  def test_new_converter
    assert_nothing_raised do
      reader = get_test_reader @options
      writer = Mysql2postgres::PostgresFileWriter.new @destfile, @options[:destination]
      converter = Mysql2postgres::Converter.new reader, writer, @options
      assert_equal 0, converter.convert
    end
  end
end
