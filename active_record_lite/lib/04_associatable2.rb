require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  def has_one_through(name, through_name, source_name)


    define_method name do
      through_options = self.class.assoc_options[through_name]
      source_options = through_options.model_class.assoc_options[source_name]

      start_key = self.send(through_options.foreign_key)
      mid_class = through_options.model_class
      if mid_class.find(start_key)
        mid_object = mid_class.where(id: start_key).first
      else
        return nil
      end

      end_key = mid_object.send(source_options.foreign_key)
      end_class = source_options.model_class
      if end_class.find(end_key)
        end_class.where(id: end_key).first
      else
        nil
      end
    end
  end

  def has_many_through(name, through_name, source_name)

    define_method name do
      end_objects = []
      mid_objects = send(through_name)
      return nil unless mid_objects
      mid_objects.each do |mid_object|
       end_objects = end_objects + mid_object.send(source_name)
      end
      end_objects

    end
  end
end
