# frozen_string_literal: true

require 'mysql2postgres/postgres_writer'
require 'mysql2postgres/connection'

class Mysql2postgres
  class PostgresDbWriter < PostgresFileWriter
    attr_reader :connection

    def initialize(file, destination)
      # NOTE: the superclass opens and truncates filename for writing
      super

      @connection = Connection.new destination
    end

    def inload(path = filename)
      connection.load_file path
    end

    def clear_schema
      connection.clear_schema
    end
  end
end
