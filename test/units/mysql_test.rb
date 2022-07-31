# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class MysqlTest < Test::Unit::TestCase
  def test_mysql_charset
    charset = ::Mysql::Charset.by_number 192
    assert_equal 'utf8mb3', charset.name
  end
end
