require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)
    define_method(name) do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      join_str = "#{through_options.table_name}.#{through_options.primary_key} = #{source_options.table_name}.id"

      results = DBConnection.execute(<<-SQL, self.owner_id)
      SELECT #{source_options.table_name}.*
      FROM #{through_options.table_name}
      JOIN #{source_options.table_name}
      ON #{join_str}
      WHERE #{through_options.table_name}.id = ?

      SQL
      p ["HELLO", results]
      source_options.model_class.parse_all(results).first
    end

  end
end
