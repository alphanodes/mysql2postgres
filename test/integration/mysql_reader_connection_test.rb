# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class MysqlReaderConnectionTest < Test::Unit::TestCase
  class << self
    def startup
      seed_test_database option_file: 'config_to_file'
    end
  end

  def setup
    @options = options_from_file 'config_to_file'
  end

  def test_mysql_connection
    assert_nothing_raised do
      Mysql2postgres::MysqlReader.new @options
    end
  end

  def test_mysql_reconnect
    assert_nothing_raised do
      reader = Mysql2postgres::MysqlReader.new @options
      reader.reconnect
    end
  end

  def test_mysql_connection_without_port
    assert_nothing_raised do
      @options[:mysql][:port] = ''
      @options[:mysql][:socket] = ''
      Mysql2postgres::MysqlReader.new @options
    end
  end
end
