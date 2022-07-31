# frozen_string_literal: true

require 'yaml'

require 'pg'
require 'pg_ext'
require 'pg/exceptions'
require 'pg/constants'
require 'pg/connection'
require 'pg/result'

require 'mysql2postgres/version'
require 'mysql2postgres/converter'
require 'mysql2postgres/mysql_reader'
require 'mysql2postgres/postgres_writer'
require 'mysql2postgres/postgres_file_writer'
require 'mysql2postgres/postgres_db_writer'

require 'debug' if ENV.fetch('ENABLE_DEBUG', nil) == '1'

class Mysql2postgres
  attr_reader :options, :config_file, :reader, :writer

  def initialize(yaml, config_file = nil)
    @config_file = config_file
    @options = build_options yaml
  end

  def convert
    @reader = MysqlReader.new options

    puts "mysql2postgres #{Mysql2postgres::VERSION}"
    puts "Config file: #{config_file}"
    puts "Dumpfile: #{dump_file}"

    @writer = if to_file?
                puts 'Target: File'
                PostgresFileWriter.new dump_file, options[:destination]
              else
                puts "Target: PostgreSQL DB (#{adapter})"
                PostgresDbWriter.new dump_file, options[:destination]
              end

    Converter.new(reader, writer, options).convert
    File.delete dump_file if options[:remove_dump_file] && File.exist?(dump_file)
  end

  private

  def adapter
    if options[:destination][:adapter].nil? || options[:destination][:adapter].empty?
      'postgresql'
    else
      options[:destination][:adapter]
    end
  end

  def environment
    if ENV['MYSQL2POSTGRES_ENV']
      ENV['MYSQL2POSTGRES_ENV']
    elsif ENV['RAILS_ENV']
      ENV['RAILS_ENV']
    else
      'development'
    end
  end

  def to_file?
    adapter == 'file'
  end

  def build_options(yaml)
    yaml.transform_keys(&:to_sym).tap do |opts|
      opts[:mysql].transform_keys!(&:to_sym)

      destinations = opts.delete :destinations
      opts[:destination] = destinations[environment]&.transform_keys(&:to_sym)

      if opts[:destination].nil? || opts[:destination].empty?
        raise "no configuration for environment '#{environment}' in destinations available. Use MYSQL2POSTGRES_ENV or RAILS_ENV."
      end
    end
  end

  def dump_file
    @dump_file ||= if to_file? && options[:destination][:filename] && options[:destination][:filename] != ''
                     options[:destination][:filename]
                   else
                     tag = Time.new.strftime '%Y%m%d-%H%M%S'
                     path = options[:dump_file_directory] || './'
                     File.expand_path File.join(path, "output_#{tag}.sql")
                   end
  end
end
