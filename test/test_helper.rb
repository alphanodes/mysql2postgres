# frozen_string_literal: true

require 'rubygems'
require 'test/unit'
require 'debug' if ENV.fetch('ENABLE_DEBUG', nil) == '1'

require File.expand_path('lib/mysql2postgres')

def load_yaml_file(file = 'config_all_options')
  YAML.load_file "#{__dir__}/fixtures/#{file}.yml"
end

def instance_from_file(file = 'config_all_options')
  Mysql2postgres.new load_yaml_file(file)
end

def options_from_file(file = 'config_all_options')
  instance_from_file(file).options
end

def seed_test_database(option_file: 'config_all_options', sql_file: 'seed_integration_tests.sql')
  options = options_from_file option_file
  seedfilepath = File.expand_path "test/fixtures/#{sql_file}"
  system 'mysql ' \
         "--host #{options[:mysql][:hostname]} " \
         "--port #{options[:mysql][:port]} " \
         "-u#{options[:mysql][:username]} " \
         "-p#{options[:mysql][:password]} " \
         "#{options[:mysql][:database]} < #{seedfilepath}", exception: true
rescue StandardError
  raise 'Failed to seed integration test db. See README for setup requirements.'
end

def get_test_reader(options)
  Mysql2postgres::MysqlReader.new options
rescue StandardError
  raise 'Failed to initialize integration test db. See README for setup requirements.'
end

def get_temp_file(basename)
  require 'tempfile'
  f = Tempfile.new basename
  path = f.path
  f.close!
  path
end
