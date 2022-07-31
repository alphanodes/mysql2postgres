# frozen_string_literal: true

class Mysql2postgres
  class Connection
    attr_reader :conn,
                :hostname,
                :login,
                :password,
                :database,
                :schema,
                :port,
                :copy_manager,
                :stream,
                :is_copying

    def initialize(pg_options)
      @hostname = pg_options[:hostname] || 'localhost'
      @login = pg_options[:username]
      @password = pg_options[:password]
      @database = pg_options[:database]
      @port = (pg_options[:port] || 5432).to_s

      @database, @schema = database.split ':'

      @conn = open
      raise_nil_connection if conn.nil?

      @is_copying = false
      @current_statement = ''
    end

    def open
      @conn = PG::Connection.open dbname: database,
                                  user: login,
                                  password: password,
                                  host: hostname,
                                  port: port
    end

    # ensure that the copy is completed, in case we hadn't seen a '\.' in the data stream.
    def flush
      conn.put_copy_end
    rescue StandardError => e
      warn e
    ensure
      @is_copying = false
    end

    def execute(sql)
      if sql.match(/^COPY /) && !is_copying
        # sql.chomp!   # cHomp! cHomp!
        conn.exec sql
        @is_copying = true
      elsif sql.match(/^(ALTER|CREATE|DROP|SELECT|SET|TRUNCATE) /) && !is_copying
        @current_statement = sql
      elsif is_copying
        if sql.chomp == '\.' || sql.chomp.match(/^$/)
          flush
        else
          begin
            until conn.put_copy_data sql
              warn '  waiting for connection to be writable...'
              sleep 0.1
            end
          rescue StandardError => e
            @is_copying = false
            warn e
            raise e
          end
        end
      elsif @current_statement.length.positive?
        @current_statement << ' '
        @current_statement << sql
      end

      return unless @current_statement.match?(/;$/)

      run_statement @current_statement
      @current_statement = ''
    end

    # we're done talking to the database, so close the connection cleanly.
    def finish
      @conn.finish
    end

    # given a file containing psql syntax at path, pipe it down to the database.
    def load_file(path)
      if @conn
        File.open path, 'r:UTF-8' do |file|
          file.each_line do |line|
            execute line
          end
          flush
        end
        finish
      else
        raise_nil_connection
      end
    end

    def clear_schema
      statements = ['DROP SCHEMA PUBLIC CASCADE', 'CREATE SCHEMA PUBLIC']
      statements.each do |statement|
        run_statement statement
      end
    end

    def raise_nil_connection
      raise 'No Connection'
    end

    def tables
      result = run_statement <<~SQL_TABLES
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
      SQL_TABLES

      result.map { |t| t['table_name'] }
    end

    private

    def run_statement(statement)
      @conn.exec statement
    end
  end
end
