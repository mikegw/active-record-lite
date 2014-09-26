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
    self.class_name.constantize
  end

  def table_name
    self.model_class.table_name || self.class_name.to_s.tableize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @name = name
    @foreign_key = options[:foreign_key] || "#{name.to_s}_id".to_sym
    @class_name = options[:class_name] || name.to_s.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase.to_s}_id".to_sym
    @class_name = options[:class_name] || name.to_s.singularize.camelcase
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    define_method(name) do
      options.model_class.where(id: self.send(options.foreign_key).to_s).first
    end

    options
  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)

    define_method(name) do
      options.model_class.where(options.foreign_key => self.id.to_s)
    end

    options
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
