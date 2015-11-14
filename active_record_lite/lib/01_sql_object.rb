require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @columns ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns.first.map {|el| el.to_sym}
  end

  def self.finalize!
    columns.each do |column_name|
      define_method column_name do
        attributes[column_name]
      end

      define_method "#{column_name}=" do |value|
        attributes[column_name] = value
      end
    end
  end

  def self.class_to_table
    # name = self.to_s
    name.tableize
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= class_to_table
  end

  def self.all
    rows = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(rows)
  end

  # def self.variables(attributes)
  #   #parses query results to make
  #   #column names into symbols
  #   variables = {}
  #   attributes.each do |key, value|
  #     variables[key.to_sym] = value
  #   end
  #   variables
  # end

  def self.parse_all(results)
    objects = []
    results.each do |attrs|
      objects << self.new(attrs)
    end
    objects
  end

  def self.find(id)
    object = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        id = ?
    SQL
    # return nil if object.empty?
    object.empty? ? nil : self.new(object.first)
  end

  def initialize(params = {})
    # debugger
    params.each do |key, value|
      sym = key.to_sym
      raise "unknown attribute '#{sym}'" unless self.class.columns.include?(sym)
      self.send("#{key}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    @attributes.values
  end

  def columns_and_values
    col_names = self.class.columns.map{|name| name.to_s}
    col_names.shift

    attr_values = []
    attribute_values.map do |value|
      current = value.is_a?(String) ? "'#{value}'" : value
      attr_values << current
    end

    [col_names, attr_values]
  end

  def insert
    col_names = columns_and_values[0].join(", ")
    attr_values = columns_and_values[1].join(", ")
    DBConnection.execute(<<-SQL)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{attr_values})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = columns_and_values[0]
    attr_values = columns_and_values[1]
    attr_values.shift

    update_statement = []
    col_names.each_with_index { |col, i| update_statement << "#{col} = #{attr_values[i]}" }


    DBConnection.execute(<<-SQL)
      UPDATE
        #{self.class.table_name}
      SET
      #{update_statement.join(", ")}
      WHERE
        id = #{attribute_values.first}
    SQL
  end

  def save
    self.class.validations.each do |validation|
      self.class.send(validation)
    end
    self.class.validations_of_variables.each do |validation, variables|
      vars = variables.map {|variable| send(variable)}
      self.class.send(validation, vars)
    end
    if id
      update
    else
      insert
    end
  end
end

# load 'lib/01_sql_object.rb'
# class Cat < SQLObject
#   self.finalize!
# end
