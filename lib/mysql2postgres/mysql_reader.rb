# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'

require 'mysql'
require 'csv'

class Mysql2postgres
  class MysqlReader
    class Table
      attr_reader :name

      def initialize(reader, name)
        @reader = reader
        @name = name
      end

      def columns
        @columns ||= load_columns
      end

      def convert_type(type)
        case type
        when /int.* unsigned/, /bigint/
          'bigint'
        when 'bit(1)', 'tinyint(1)'
          'boolean'
        when /tinyint/
          'tinyint'
        when /int/
          'integer'
        when /varchar/, /set/
          'varchar'
        when /char/
          'char'
        when /decimal/
          'decimal'
        when /(float|double)/
          'double precision'
        else
          type
        end
      end

      def load_columns
        @reader.reconnect
        # mysql_flags = ::Mysql::Field.constants.select { |c| c.to_s.include?('FLAG') }

        fields = []
        @reader.query "EXPLAIN `#{name}`" do |res|
          while (field = res.fetch_row)
            length = field[1][/\((\d+)\)/, 1] if field[1].match?(/\((\d+)\)/)
            length = field[1][/\((\d+),(\d+)\)/, 1] if field[1].match?(/\((\d+),(\d+)\)/)
            desc = {
              name: field[0],
              table_name: name,
              type: convert_type(field[1]),
              length: length&.to_i,
              decimals: field[1][/\((\d+),(\d+)\)/, 2],
              null: field[2] == 'YES',
              primary_key: field[3] == 'PRI',
              auto_increment: field[5] == 'auto_increment'
            }
            desc[:default] = field[4] unless field[4].nil?
            fields << desc
          end
        end

        fields.select { |field| field[:auto_increment] }.each do |field|
          @reader.query "SELECT max(`#{field[:name]}`) FROM `#{name}`" do |res|
            field[:maxval] = res.fetch_row[0].to_i
          end
        end
        fields
      end

      def indexes
        load_indexes unless @indexes
        @indexes
      end

      def foreign_keys
        load_indexes unless @foreign_keys
        @foreign_keys
      end

      def load_indexes
        @indexes = []
        @foreign_keys = []

        @reader.query "SHOW CREATE TABLE `#{name}`" do |result|
          explain = result.fetch_row[1]
          explain.split("\n").each do |line|
            next unless line.include? ' KEY '

            index = {}
            if (match_data = /CONSTRAINT `(\w+)` FOREIGN KEY \((.*?)\) REFERENCES `(\w+)` \((.*?)\)(.*)/.match(line))
              index[:name] = "fk_#{name}_#{match_data[1]}"
              index[:column] = match_data[2].delete!('`').split(', ')
              index[:ref_table] = match_data[3]
              index[:ref_column] = match_data[4].delete!('`').split(', ')

              the_rest = match_data[5]

              if (match_data = /ON DELETE (SET NULL|SET DEFAULT|RESTRICT|NO ACTION|CASCADE)/.match(the_rest))
                index[:on_delete] = match_data[1]
              else
                index[:on_delete] ||= 'RESTRICT'
              end

              if (match_data = /ON UPDATE (SET NULL|SET DEFAULT|RESTRICT|NO ACTION|CASCADE)/.match(the_rest))
                index[:on_update] = match_data[1]
              else
                index[:on_update] ||= 'RESTRICT'
              end

              @foreign_keys << index
            elsif (match_data = /KEY `(\w+)` \((.*)\)/.match(line))
              # index[:name] = 'idx_' + name + '_' + match_data[1]
              # with redmine we do not want prefix idx_tablename_
              index[:name] = match_data[1]
              index[:columns] = match_data[2].split(',').map { |col| col[/`(\w+)`/, 1] }
              index[:unique] = true if line.include? 'UNIQUE'
              @indexes << index
            elsif (match_data = /PRIMARY KEY .*\((.*)\)/.match(line))
              index[:primary] = true
              index[:columns] = match_data[1].split(',').map { |col| col.strip.delete('`') }
              @indexes << index
            end
          end
        end
      end

      def count_rows
        @reader.query "SELECT COUNT(*) FROM `#{name}`" do |res|
          return res.fetch_row[0].to_i
        end
      end

      def id?
        !!columns.find { |col| col[:name] == 'id' }
      end

      def count_for_pager
        query = id? ? 'MAX(id)' : 'COUNT(*)'
        @reader.query "SELECT #{query} FROM `#{name}`" do |res|
          return res.fetch_row[0].to_i
        end
      end

      def query_for_pager
        query = id? ? 'WHERE id >= ? AND id < ?' : 'LIMIT ?,?'

        cols = columns.map do |c|
          if c[:type] == 'multipolygon'
            "AsWKT(`#{c[:name]}`) as `#{c[:name]}`"
          else
            "`#{c[:name]}`"
          end
        end

        "SELECT #{cols.join ', '} FROM `#{name}` #{query}"
      end
    end

    attr_reader :mysql

    def initialize(options)
      @host = options[:mysql][:hostname]
      @user = options[:mysql][:username]
      @passwd = options[:mysql][:password]
      @db = options[:mysql][:database]
      @port = if options[:mysql][:port]
                options[:mysql][:port] unless options[:mysql][:port].to_s.empty?
              else
                3306
              end
      @sock = options[:mysql][:socket] && !options[:mysql][:socket].empty? ? options[:mysql][:socket] : nil
      @flag = options[:mysql][:flag] && !options[:mysql][:flag].empty? ? options[:mysql][:flag] : nil

      connect
    end

    def connect
      @mysql = ::Mysql.connect @host, @user, @passwd, @db, @port, @sock
      # utf8_unicode_ci :: https://rubydoc.info/gems/ruby-mysql/Mysql/Charset
      @mysql.charset = ::Mysql::Charset.by_number 192
      @mysql.query 'SET NAMES utf8'

      var_info = @mysql.query "SHOW VARIABLES LIKE 'query_cache_type'"
      return if var_info.nil? || var_info.first.nil? || var_info.first[1] == 'OFF'

      @mysql.query 'SET SESSION query_cache_type = OFF'
    end

    def reconnect
      @mysql.close
    rescue StandardError
      warn 'could not close previous mysql connection'
    ensure
      connect
    end

    def query(*args, &block)
      mysql.query(*args, &block)
    rescue Mysql::Error => e
      if e.message.match?(/gone away/i)
        reconnect
        retry
      else
        puts "MySQL Query failed '#{args.inspect}' #{e.inspect}"
        puts e.backtrace[0, 5].join("\n")
        []
      end
    end

    def tables
      @tables ||= @mysql.query('SHOW TABLES').map { |row| Table.new(self, row.first) }
    end

    def paginated_read(table, page_size)
      count = table.count_for_pager
      return if count < 1

      statement = @mysql.prepare table.query_for_pager
      counter = 0
      0.upto (count + page_size) / page_size do |i|
        statement.execute(i * page_size, table.id? ? (i + 1) * page_size : page_size)
        while (row = statement.fetch)
          counter += 1
          yield row, counter
        end
      end
      counter
    end
  end
end
