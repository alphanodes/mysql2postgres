# frozen_string_literal: true

require 'zlib'

class Mysql2postgres
  class PostgresWriter
    attr_reader :filename, :destination

    def column_description(column)
      "#{PG::Connection.quote_ident column[:name]} #{column_type_info column}"
    end

    def column_type(column)
      column_type_info(column).split.first
    end

    def column_type_info(column)
      return "integer DEFAULT nextval('#{column[:table_name]}_#{column[:name]}_seq'::regclass) NOT NULL" if column[:auto_increment]

      default = if column[:default]
                  " DEFAULT #{column[:default].nil? ? 'NULL' : "'#{PG::Connection.escape column[:default]}'"}"
                end
      null = column[:null] ? '' : ' NOT NULL'
      type = case column[:type]
             # String types
             when 'char'
               default += '::char' if default
               "character(#{column[:length]})"
             when 'varchar'
               default += '::character varying' if default
               "character varying(#{column[:length]})"
             # Integer and numeric types
             when 'integer'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default].to_i}" if default
               'integer'
             when 'bigint'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default].to_i}" if default
               'bigint'
             when 'tinyint'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default].to_i}" if default
               'smallint'
             when 'boolean'
               default = " DEFAULT #{column[:default].to_i == 1 ? 'true' : 'false'}" if default
               'boolean'
             when 'float', 'float unsigned'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default].to_f}" if default
               'real'
             when 'decimal'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default]}" if default
               "numeric(#{column[:length] || 10}, #{column[:decimals] || 0})"
             when 'double precision'
               default = " DEFAULT #{column[:default].nil? ? 'NULL' : column[:default]}" if default
               'double precision'
             when 'datetime', 'datetime(6)'
               default = nil
               'timestamp without time zone'
             when 'date'
               default = nil
               'date'
             when 'timestamp'
               case column[:default]
               when 'CURRENT_TIMESTAMP'
                 default = ' DEFAULT CURRENT_TIMESTAMP'
               when datetime_zero
                 default = " DEFAULT '#{datetime_zero_fix}'"
               when datetime_zero(with_seconds: true) # rubocop: disable Style/MethodCallWithArgsParentheses
                 default = " DEFAULT '#{datetime_zero_fix with_seconds: true}'"
               end
               'timestamp without time zone'
             when 'time'
               default = ' DEFAULT NOW()' if default
               'time without time zone'
             when 'blob', 'longblob', 'mediumblob', 'tinyblob', 'varbinary'
               'bytea'
             when 'text', 'tinytext', 'mediumtext', 'longtext'
               'text'
             when /^enum/
               default += '::character varying' if default
               enum = column[:type].gsub(/enum|\(|\)/, '')
               max_enum_size = enum.split(',').map { |check| check.size - 2 }.max
               "character varying(#{max_enum_size}) check( \"#{column[:name]}\" in (#{enum}))"
             when 'geometry', 'multipolygon'
               'geometry'
             else
               puts "Unknown #{column.inspect}"
               column[:type].inspect
               return ''
             end

      "#{type}#{default}#{null}"
    end

    def process_row(table, row)
      table.columns.each_with_index do |column, index|
        row[index] = Time.at(row[index]).utc.strftime('%H:%M:%S') if column[:type] == 'time' && row[index]

        if row[index].is_a? Time
          row[index] = row[index].to_s.gsub datetime_zero, datetime_zero_fix
          row[index] = row[index].to_s.gsub datetime_zero(with_seconds: true), datetime_zero_fix(with_seconds: true)
        end

        if column_type(column) == 'boolean'
          row[index] = if row[index] == 1
                         't'
                       elsif row[index]&.zero?
                         'f'
                       else
                         row[index]
                       end
        end

        row[index] = string_data table, row, index, column if row[index].is_a? String

        row[index] = '\N' unless row[index]
      end
    end

    def truncate(_table) end

    def inload
      raise "Method 'inload' needs to be overridden..."
    end

    private

    def datetime_zero(with_seconds: false)
      datetime_value date: '0000-00-00', with_seconds: with_seconds
    end

    def datetime_zero_fix(with_seconds: false)
      datetime_value date: '1970-01-01', with_seconds: with_seconds
    end

    def datetime_value(date:, with_seconds: false)
      value = ["#{date} 00:00"]
      value << '00' if with_seconds
      value.join ':'
    end

    def string_data(table, row, index, column)
      if column_type(column) == 'bytea'
        if column[:name] == 'data'
          with_gzip = false
          table.columns.each_with_index do |column_data, index_data|
            if column_data[:name] == 'compression' && row[index_data] == 'gzip'
              with_gzip = true
              break
            end
          end

          escape_bytea(with_gzip ? Zlib::Inflate.inflate(row[index]) : row[index])
        else
          escape_bytea row[index]
        end
      else
        escape_data(row[index]).gsub("\n", '\n').gsub("\t", '\t').gsub("\r", '\r').gsub(/\0/, '')
      end
    end

    def escape_bytea(data)
      escape_data(PG::Connection.escape_bytea(data)).gsub("''", "'")
    end

    def escape_data(value)
      value.gsub '\\', '\\\\\\'
    end
  end
end
