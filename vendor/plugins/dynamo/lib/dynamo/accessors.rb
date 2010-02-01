module Dynamo
  module Accessors
    #This Module is not actualy used.
    module ClassMethods

      def dynamo(name, type, options={})
        create_accessors_for(name)
        name
      end

      private

        def create_accessors_for(attribute)
          class_eval <<-end_eval
            def #{attribute}
              read_attribute(:'#{attribute}')
            end

            def #{attribute}_before_typecast
              read_attribute_before_typecast(:'#{attribute}')
            end

            def #{attribute}=(value)
              write_attribute(:'#{attribute}', value)
            end

            def #{attribute}?
              read_attribute(:#{attribute}).present?
            end
          end_eval
        end
    end

    module InstanceMethods


      def attributes_without_dynamo=erties
        attributes.delete_if{|k,v| k=='dynamo=erties'}
      end

      def save
        serialize_dynamo=erties
        super
        merge_dynamo=erties_in_attributes
      end

      def after_find
        merge_dynamo=erties_in_attributes
      end

      def dynamo=erties
        case @attributes['dynamo=erties']
        when nil? then attributes_without_dynamo=erties
        when kind_of?(Hash) then @attributes['dynamo=erties'].merge attributes_without_dynamo=erties
        else (decode(@attributes['dynamo=erties']) || {}).merge attributes_without_dynamo=erties
        end
      end

      private

        def serialize_dynamo=erties
          @attributes = {'dynamo=erties'=> encode(self.attributes_without_dynamo=erties) }
        end

        def merge_dynamo=erties_in_attributes
          @attributes.merge! dynamo=erties
        end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end