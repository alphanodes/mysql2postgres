# frozen_string_literal: true

lib = File.expand_path '../lib', __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'mysql2postgres/version'

Gem::Specification.new do |s|
  s.name = 'mysql2postgres'
  s.version = Mysql2postgres::VERSION
  s.licenses = ['MIT']

  s.authors = [
    'Max Lapshin <max@maxidoors.ru>',
    'Anton Ageev <anton@ageev.name>',
    'Samuel Tribehou <cracoucax@gmail.com>',
    'Marco Nenciarini <marco.nenciarini@devise.it>',
    'James Nobis <jnobis@jnobis.controldocs.com>',
    'quel <github@quelrod.net>',
    'Holger Amann <keeney@fehu.org>',
    'Maxim Dobriakov <closer.main@gmail.com>',
    'Michael Kimsal <mgkimsal@gmail.com>',
    'Jacob Coby <jcoby@portallabs.com>',
    'Neszt Tibor <neszt@tvnetwork.hu>',
    'Miroslav Kratochvil <exa.exa@gmail.com>',
    'Paul Gallagher <gallagher.paul@gmail.com>',
    'Alex C Jokela <ajokela@umn.edu>',
    'Peter Clark <pclark@umn.edu>',
    'Juga Paazmaya <olavic@gmail.com>',
    'Alexander Meindl <a.meindl@alphanodes.com'
  ]
  s.description = 'Translates MySQL -> PostgreSQL'
  s.email = 'a.meindl@alphanodes.com'
  s.metadata = { 'rubygems_mfa_required' => 'true' }
  s.executables = ['mysql2postgres']
  s.required_ruby_version = '>= 3.1'

  s.files = [
    '.gitignore',
    'MIT-LICENSE',
    'README.md',
    'Rakefile',
    'bin/mysql2postgres',
    'lib/mysql2postgres.rb',
    'lib/mysql2postgres/converter.rb',
    'lib/mysql2postgres/connection.rb',
    'lib/mysql2postgres/mysql_reader.rb',
    'lib/mysql2postgres/postgres_db_writer.rb',
    'lib/mysql2postgres/postgres_file_writer.rb',
    'lib/mysql2postgres/postgres_db_writer.rb',
    'lib/mysql2postgres/postgres_writer.rb',
    'lib/mysql2postgres/version.rb',
    'mysql2postgres.gemspec',
    'test/fixtures/config_all_options.yml',
    'test/fixtures/config_min_options.yml',
    'test/fixtures/config_to_file.yml',
    'test/fixtures/seed_integration_tests.sql',
    'test/integration/convert_to_db_test.rb',
    'test/integration/convert_to_file_test.rb',
    'test/integration/converter_test.rb',
    'test/integration/mysql_reader_connection_test.rb',
    'test/integration/mysql_reader_test.rb',
    'test/integration/postgres_db_writer_test.rb',
    'test/units/mysql_test.rb',
    'test/units/option_test.rb',
    'test/units/postgres_file_writer_test.rb',
    'test/test_helper.rb'
  ]
  s.homepage = 'https://github.com/AlphaNodes/mysql2postgres'
  s.rdoc_options = ['--charset=UTF-8']
  s.require_paths = ['lib']
  s.summary = 'MySQL to PostgreSQL Data Translation'

  s.add_dependency 'pg', '~> 1.5.3'
  s.add_dependency 'rake'
  s.add_dependency 'ruby-mysql', '~> 3.0.1'
end
