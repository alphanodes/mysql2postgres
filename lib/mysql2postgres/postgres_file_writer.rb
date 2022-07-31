# frozen_string_literal: true

require 'mysql2postgres/postgres_writer'
require 'fileutils'

class Mysql2postgres
  class PostgresFileWriter < PostgresWriter
    def initialize(file, destination)
      super()

      @filename = file
      @destination = destination

      @f = File.open file, 'w+:UTF-8'
      @f << <<~SQL_HEADER
        -- MySQL 2 PostgreSQL dump\n
        SET client_encoding = 'UTF8';
        SET standard_conforming_strings = off;
        SET check_function_bodies = false;
        SET client_min_messages = warning;

      SQL_HEADER
    end

    def truncate(table)
      serial_key = nil
      maxval = nil

      table.columns.map do |column|
        if column[:auto_increment]
          serial_key = column[:name]
          maxval = column[:maxval].to_i < 1 ? 1 : column[:maxval] + 1
        end
      end

      @f << <<~SQL_TRUNCATE
        -- TRUNCATE #{table.name};
        TRUNCATE #{PG::Connection.quote_ident table.name} CASCADE;

      SQL_TRUNCATE

      return unless serial_key

      @f << <<~SQL_SERIAL
        SELECT pg_catalog.setval(pg_get_serial_sequence('#{table.name}', '#{serial_key}'), #{maxval}, true);
      SQL_SERIAL
    end

    def write_table(table)
      primary_keys = []
      serial_key = nil
      maxval = nil

      columns = table.columns.map do |column|
        if column[:auto_increment]
          serial_key = column[:name]
          maxval = column[:maxval].to_i < 1 ? 1 : column[:maxval] + 1
        end
        primary_keys << column[:name] if column[:primary_key]
        "  #{column_description column}"
      end.join(",\n")

      if serial_key
        @f << <<~SQL_SEQUENCE
          --
          -- Name: #{table.name}_#{serial_key}_seq; Type: SEQUENCE; Schema: public
          --

          DROP SEQUENCE IF EXISTS #{table.name}_#{serial_key}_seq CASCADE;

          CREATE SEQUENCE #{table.name}_#{serial_key}_seq
              INCREMENT BY 1
              NO MAXVALUE
              NO MINVALUE
              CACHE 1;


          SELECT pg_catalog.setval('#{table.name}_#{serial_key}_seq', #{maxval}, true);

        SQL_SEQUENCE
      end

      @f << <<~SQL_TABLE
        -- Table: #{table.name}

        -- DROP TABLE #{table.name};
        DROP TABLE IF EXISTS #{PG::Connection.quote_ident table.name} CASCADE;

        CREATE TABLE #{PG::Connection.quote_ident table.name} (
      SQL_TABLE

      @f << columns

      if (primary_index = table.indexes.find { |index| index[:primary] })
        @f << ",\n  CONSTRAINT #{table.name}_pkey PRIMARY KEY(#{quoted_list primary_index[:columns]})"
      end

      @f << <<~SQL_OIDS
        \n)
        WITHOUT OIDS;
      SQL_OIDS

      table.indexes.each do |index|
        next if index[:primary]

        unique = index[:unique] ? 'UNIQUE ' : nil
        @f << <<~SQL_INDEX
          DROP INDEX IF EXISTS #{PG::Connection.quote_ident index[:name]} CASCADE;
          CREATE #{unique}INDEX #{PG::Connection.quote_ident index[:name]}
          ON #{PG::Connection.quote_ident table.name} (#{quoted_list index[:columns]});
        SQL_INDEX
      end
    end

    def write_indexes(_table); end

    def write_constraints(table)
      table.foreign_keys.each do |key|
        @f << "ALTER TABLE #{PG::Connection.quote_ident table.name} " \
              "ADD FOREIGN KEY (#{quoted_list key[:column]}) " \
              "REFERENCES #{PG::Connection.quote_ident key[:ref_table]}(#{quoted_list key[:ref_column]}) " \
              "ON UPDATE #{key[:on_update]} ON DELETE #{key[:on_delete]};\n"
      end
    end

    def write_contents(table, reader)
      @f << <<~SQL_COPY
        --
        -- Data for Name: #{table.name}; Type: TABLE DATA; Schema: public
        --

        COPY "#{table.name}" (#{quoted_list(table.columns.map { |m| m[:name] })}) FROM stdin;
      SQL_COPY

      reader.paginated_read table, 1000 do |row, _counter|
        process_row table, row
        @f << row.join("\t")
        @f << "\n"
      end
      @f << "\\.\n\n"
    end

    def close
      @f.close
    end

    def inload
      puts "\nSkip import to PostgreSQL DB. SQL file created successfully."
    end

    private

    def quoted_list(list)
      list.map { |c| PG::Connection.quote_ident(c) }.join(', ')
    end
  end
end
