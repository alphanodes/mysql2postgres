# frozen_string_literal: true

require File.expand_path '../test_helper', __dir__

class ConvertToFileTest < Test::Unit::TestCase
  attr_reader :content

  class << self
    def startup
      seed_test_database option_file: 'config_to_file'
    end
  end

  def setup
    @mysql2postgres = instance_from_file 'config_to_file'
    @options = @mysql2postgres.options
    @options[:force_truncate] = true
    @options.delete :tables # convert all available tables

    @mysql2postgres.convert
    @content = File.read @mysql2postgres.options[:destination][:filename]
  end

  def test_table_creation
    assert_not_nil content.match('DROP TABLE IF EXISTS "numeric_types_basics" CASCADE')
    assert_not_nil content.include?('CREATE TABLE "numeric_types_basics"')
  end

  def test_basic_numerics_tinyint
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_tinyint" smallint,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_smallint
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_smallint" integer,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_mediumint
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_mediumint" integer,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_int
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_int" integer,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_integer
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_integer" integer,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_bigint
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_bigint" bigint,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_real
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_real" double precision,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_double
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_double" double precision,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_float
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_float" double precision,.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_decimal
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_decimal" numeric\(10, 0\),.*\)', Regexp::MULTILINE)
                         .match(content)
  end

  def test_basic_numerics_numeric
    assert_not_nil Regexp.new('CREATE TABLE "numeric_types_basics".*"f_numeric" numeric\(10, 0\)[\w\n]*\)', Regexp::MULTILINE)
                         .match(content)
  end
end
