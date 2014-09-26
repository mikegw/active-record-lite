require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_arr = []
    params.each_key {|k| where_arr << "#{k} = ?"}
    where_line = where_arr.join(" AND ")
    p params.values
    results = DBConnection.execute(<<-SQL, *params.values)
    SELECT
    *
    FROM
    #{table_name}
    WHERE
    #{where_line}
    SQL

    p results
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
