module Dynamo
  module Core

    module ClassMethods

    end

    module InstanceMethods

      def dynamo
        @dynamo || decode_dynamo
      end

      alias_method :dyn, :dynamo

      def dynamo=(new_attributes)
        check_kind_of_hash(new_attributes)
        @dynamo = new_attributes
        encode_dynamo
      end

      alias_method :dyn=, :dynamo=

      def attributes_with_dynamo=(new_attributes, guard_protected_attributes = true)
        column_attributes, dynamo_attributes = {}, {}
        columns = self.class.column_names

        new_attributes.each do |k,v|
          if columns.include?(k)
            column_attributes[k] = v
          else
            dynamo_attributes[k] = v
          end
        end
        self.attributes_without_dynamo=(column_attributes) unless column_attributes.empty?

        merge_dynamo(dynamo_attributes)
        encode_dynamo
      end

      def read_attribute_with_dynamo(attr_name)
        if attr_name == 'dynamo'
          decode_dynamo
        else
          read_attribute_without_dynamo(attr_name)
        end
      end

      private

        def encode_dynamo
          write_attribute('dynamo', encode(@dynamo))
        end

        def decode_dynamo
          decode(@attributes['dynamo'])
        end

        def check_kind_of_hash(data)
          raise TypeError, 'Argument is not Hash' unless data.kind_of?(Hash)
        end

      protected

        def merge_dynamo(new_attributes)
          if @dynamo && !@dynamo.nil? && @dynamo.kind_of?(Hash)
            @dynamo.merge!(new_attributes)
          else
            @dynamo = new_attributes
          end
        end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :alias_method_chain, :attributes=,    :dynamo
      #receiver.send :alias_method_chain, :read_attribute, :dynamo
      receiver.send :before_save, :encode_dynamo
    end
  end
end