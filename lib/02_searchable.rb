require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable

  def where(params)
    LazyWhere.new(self, params)
  end



  def where!(params)
    where_arr = []
    params.each_key {|k| where_arr << "#{k} = ?"}
    where_line = where_arr.join(" AND ")

    results = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      *
    FROM
      #{table_name}
    WHERE
      #{where_line}
    SQL

    parse_all(results)
  end

end


class LazyWhere

  attr_accessor :params

  def initialize(obj, params)
    @obj = obj
    @params = params
  end

  def where(params)
    self.params.merge!(params)
    self
  end

  def method_missing(method_name, *args)
    #p "#{self.class.name} called #{method_name}"
    @obj.send(:where!, self.params).send(method_name, *args)
  end

end

class SQLObject
  extend Searchable
end
