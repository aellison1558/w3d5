require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    model_class.table_name
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @class_name = options[:class_name] || name.to_s.camelcase
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @name = name
    @self_class_name = self_class_name
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
    @foreign_key = options[:foreign_key] || "#{self_class_name.to_s.downcase}_id".to_sym
    @primary_key = options[:primary_key] || :id
    # ...
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    belongs_options = BelongsToOptions.new(name, options)
    assoc_options[name] = belongs_options
    define_method name do
      foreign = self.send(belongs_options.foreign_key)
      owner_class = belongs_options.model_class
      if owner_class.find(foreign)
        belongs_options.model_class.where(id: foreign).first
      else
        nil
      end
    end
  end

  def has_many(name, options = {})
     options = HasManyOptions.new(name, self, options)
     assoc_options[name] = options
     
    define_method name do
      primary = send(options.primary_key)
      results = options.model_class.where(options.foreign_key => primary)
      results
    end
  end

  def assoc_options
    @options ||= {}
  end
end

class SQLObject
  extend Associatable
end
