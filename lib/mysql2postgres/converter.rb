# frozen_string_literal: true

class Mysql2postgres
  class Converter
    attr_reader :reader,
                :writer,
                :options,
                :exclude_tables,
                :only_tables,
                :suppress_data,
                :suppress_ddl,
                :force_truncate,
                :preserve_order,
                :clear_schema

    def initialize(reader, writer, options)
      @reader = reader
      @writer = writer
      @exclude_tables = options[:exclude_tables] || []
      @only_tables = options[:tables]
      @suppress_data = options[:suppress_data] || false
      @suppress_ddl = options[:suppress_ddl] || false
      @force_truncate = options[:force_truncate] || false
      @preserve_order = options[:preserve_order] || false
      @clear_schema = options[:clear_schema] || false
    end

    def convert
      tables = reader.tables
      tables.reject! { |table| exclude_tables.include?(table.name) }
      tables.select! { |table| only_tables ? only_tables.include?(table.name) : true }

      # preserve order only works, if only_tables are specified
      if preserve_order && only_tables
        reordered_tables = []

        only_tables.each do |only_table|
          idx = tables.index { |table| table.name == only_table }
          if idx.nil?
            warn "Specified source table '#{only_table}' does not exist, skiped by migration"
          else
            reordered_tables << tables[idx]
          end
        end

        tables = reordered_tables
      end

      unless suppress_ddl
        tables.each do |table|
          puts "Writing DDL for #{table.name}"
          writer.write_table table
        end
      end

      unless suppress_data
        if force_truncate && suppress_ddl
          tables.each do |table|
            puts "Truncate table #{table.name}"
            writer.truncate table
          end
        end

        tables.each do |table|
          puts "Writing data for #{table.name}"
          writer.write_contents table, reader
        end
      end

      puts 'Writing indices and constraints'
      unless suppress_ddl
        tables.each do |table|
          writer.write_indexes table
        end
      end

      unless suppress_ddl
        tables.each do |table|
          writer.write_constraints table
        end
      end

      writer.close
      writer.clear_schema if clear_schema
      writer.inload
      0
    rescue StandardError => e
      warn "mysql2postgres: Conversion failed: #{e}"
      warn e
      warn e.backtrace[0, 3].join("\n")
      -1
    end
  end
end
