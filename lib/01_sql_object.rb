require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL).first.map(&:to_sym)
  SELECT
    *
  FROM
    #{table_name}
  SQL
  end

  def self.finalize!
    columns.each do |name|
      define_method(name) {self.attributes[name]}
      define_method(name.to_s + "=") do |val|
        self.attributes[name] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.all
    results = DBConnection.execute2(<<-SQL)
  SELECT
    #{table_name}.*
  FROM
    #{table_name}
  SQL
  parse_all(results.drop(1))
  end

  def self.parse_all(results)
    objs = []
    results.each do |row|
      new_row = {}
      row.each_pair{|k,v| new_row[k.to_sym] = v}

      objs << self.new(new_row)
    end
    objs
  end

  def self.find(id)
    result = DBConnection.execute2(<<-SQL, id)
    SELECT
      #{table_name}.*
    FROM
      #{table_name}
    WHERE id = ?
    SQL
    parse_all(result.drop(1)).first
  end

  def initialize(params = {})
    cols = self.class.columns
    params.keys.each do |k|
      raise "unknown attribute '#{k}'" unless cols.include?(k)
    end
    #@attributes = params
    params.each { |k,v| send(:attributes)[k] = v }
    self.class.finalize!
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|col_name| self.send(col_name)}
  end

  def insert
    col_names = self.class.columns.join(", ")
    question_marks = self.class.columns.map{|c| '?'}.join(", ")
    DBConnection.execute2(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks})
    SQL
    self.attributes[:id] = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map { |c| "#{c} = ?" }.join(", ")
    DBConnection.execute2(<<-SQL, *attribute_values, self.id)
    UPDATE
      #{self.class.table_name}
    SET
      #{set_line}
    WHERE id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
