# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__
require 'yaml'

class SettingTest < Test::Unit::TestCase
  def test_options_loaded
    options = options_from_file

    assert_equal false, options[:suppress_data]
    assert_equal 'postgres', options[:destination][:username]
    assert_equal 'somename', options[:destination][:database]
  end
end
