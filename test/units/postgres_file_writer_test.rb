# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class PostgresFileWriterTest < Test::Unit::TestCase
  attr_accessor :destfile

  def setup
    @destfile = get_temp_file 'mysql2postgres_test_destfile'
  rescue StandardError
    raise 'Failed to initialize integration test db. See README for setup requirements.'
  end

  def teardown
    File.delete destfile
  end

  def test_file_writer
    destination = { filename: '/tmp/test.sql' }
    writer = Mysql2postgres::PostgresFileWriter.new @destfile, destination
    writer.close
    content = File.read destfile

    assert_not_nil content.match("SET client_encoding = 'UTF8'")
    assert_nil content.match('unobtanium')
  end
end
