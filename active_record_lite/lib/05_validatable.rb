require_relative '04_associatable2'

module Validatable
  def validations_of_variables
    @validations_of_variables ||= {}
  end

  def validations
    @validations ||= []
  end

  def validates(variables, validations)
    validations.each do |validation|
      validations_of_variables[validation] = variables
    end
  end

  def validate(*methods)
    methods.each do |method|
      validations << method
    end
  end

  def presence(variables)
    variables.each do |variable|
      raise "Must have #{variable}" unless send(variable)
      if variable.is_a?(String) || variable.is_a?(Array)
        raise "#{variable} cannot be empty" if variable.empty?
      end
    end

  end


end

class SQLObject
  extend Validatable
end
