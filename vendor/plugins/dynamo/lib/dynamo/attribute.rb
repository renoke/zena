module Dynamo
  module Attribute

    # The Dynamo::Attribute module is included in ActiveRecord model for CRUD operations
    # on the dynamics attributes (the dynamos). These ared stored in a table field called 'dynamo'
    # and accessed with #dynamo and dynamo= methods.
    #
    # The dynamo are encoded et decode with a serialization tool than you need to specify seperatly (for instance
    # Dynamo::Serialization::Marshal).
    #
    # The attributes= method filter columns attributes and dynamic attributes in order to store
    # them apart.
    #

    module InstanceMethods

      def dynamo
        @dynamo ||= decode(read_attribute('dynamo'))
      end

      alias_method :dyn, :dynamo

      def dynamo=(value)
        check_kind_of_hash(value)
        @dynamo = value
        encode_dynamo
      end

      alias_method :dyn=, :dynamo=

      private

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

        def encode_dynamo
          write_attribute('dynamo', encode(@dynamo))
        end

        def check_kind_of_hash(data)
          raise TypeError, 'Argument is not Hash' unless data.kind_of?(Hash)
        end

        def changed_with_dynamo?
          encode_dynamo
          changed_without_dynamo?
        end

        def changed_with_dynamo
          encode_dynamo
          changed_without_dynamo
        end


        def merge_dynamo(new_attributes)
          if @dynamo && !@dynamo.nil? && @dynamo.kind_of?(Hash)
            @dynamo.merge!(new_attributes)
          else
            @dynamo = new_attributes
          end
        end

        def changed_attributes_with_dynamo
          encode_dynamo
          changed_attributes_without_dynamo
        end

    end

    def self.included(receiver)
      receiver.send :include, InstanceMethods
      receiver.send :alias_method_chain, :attributes=,  :dynamo
      # receiver.send :alias_method_chain, :write_attribute,  :dynamo
      # receiver.send :alias_method_chain, :changed,      :dynamo
      # receiver.send :alias_method_chain, :changed?,     :dynamo
      # receiver.send :alias_method_chain, :changed_attributes,  :dynamo
      # receiver.send :before_save, :encode_dynamo
    end
  end
end