require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_statement = []
    params.each do |col, value|
      current_value =  value.is_a?(String) ? "'#{value}'" : value
      where_statement << "#{col} = #{current_value}"
    end

    rows = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_statement.join(" AND ")}
    SQL

    parse_all(rows)
  end
end

class SQLObject
  extend Searchable
end
