class ResourceErrors
  attr_reader :resource, :collection_errors

  def initialize(resource)
    @resource = resource
    # @associations = resource.class.reflect_on_all_associations.map(&:name)#.map(&:to_s)
    @collection_errors = nil
  end

  def formatted_errors
    unless collection_errors
      collection_errors = []

      errors = resource.errors

      resource.errors.messages.each_with_index do |(field, errors), _index|
        field_map = "#{resource.class.model_name.singular.downcase}"
        collection_errors << check_associations(resource, field, field_map, errors)
      end

      collection_errors.flatten!
    end

    { error: collection_errors }
  end

  private

  def check_associations(resource, field, field_map, errors)
    collection_errors = []
    associations = resource.class.reflect_on_all_associations.map(&:name)
    association_object = nil
    field = field.to_s.split('.')

    field.each_with_index do |f, index|
      if association_object
        associations =
          association_object.class.to_s.gsub(
            '::ActiveRecord_Associations_CollectionProxy', ''
          )
                            .constantize.reflect_on_all_associations.map(&:name)
      end

      if associations.include?(f.to_sym)
        resource = association_object if association_object
        if resource.class.method_defined?(:count)
          association_object = resource.first.send(f)
          resource.first.errors.delete(field[index..-1].join('.').to_sym)
        else
          association_object = resource.send(f)
          resource.errors.delete(field[index..-1].join('.').to_sym)
        end
      elsif f == 'base'
        errors.each do |error|
          e = format_error(resource, f, "#{resource.class}[#{f}}]", error)
          collection_errors << e
        end
        break
      else
        break
      end
    end

    field.join('.')

    if association_object
      if association_object.class.method_defined?(:count)
        association_object.each do |object|
          inner_field_map = "#{field_map}[#{association_object.class.to_s.gsub(
            '::ActiveRecord_Associations_CollectionProxy', ''
          )
                                            .constantize.model_name.plural.downcase}_attributes]"
          collection_errors << object_errors(resource, errors, field.last, object, field_map, inner_field_map)
        end
      else
        inner_field_map = "#{field_map}[#{association_object.class.model_name.singular.downcase}_attributes]"
        collection_errors << object_errors(resource, errors, field.last, association_object, field_map, inner_field_map)
      end
    elsif resource.respond_to?(field.last)
      field = field.last
      errors.each do |error|
        e = format_error(resource, field, "#{field_map}[#{field}]", error)
        collection_errors << e
      end
      association_object = nil
    end

    collection_errors
  end

  def object_errors(prev_resource, prev_resource_errors, prev_field, new_resource, prev_field_map, new_field_map)
    collection_errors = []

    if new_resource
      new_resource.errors.messages.each do |field, errors|
        collection_errors << errors.map do |error|
          format_error(new_resource, field, "#{new_field_map}[#{field}]", error)
        end
      end
    else
      collection_errors << prev_resource_errors.map do |error|
        format_error(prev_resource, "#{prev_field_map}[#{prev_field}]", error)
      end
    end

    collection_errors
  end

  def format_error(res, field, field_map, error)
    e = {
      model: res.class.to_s,
      model_human: res.class.model_name.human,
      field: field_map,
      attribute: (field.to_s == 'base' ? res.class.name : field.to_s),
      attribute_human: (
        if field.to_s == 'base'
          res.class.model_name.human
        else
          res.class.human_attribute_name(field.to_sym)
        end
      ),
      id: res.id,
      message: error,
      full_message: (
        "#{res.class.model_name.human}: " +
        "#{field.to_s == 'base' ? '' : res.class.human_attribute_name(field.to_sym)} #{error}"
      )
    }
    puts "#{res.class.model_name.human}: #{res.class.human_attribute_name(field.to_sym)} #{error}"
    # puts "#{e}"
    e
  end
end
