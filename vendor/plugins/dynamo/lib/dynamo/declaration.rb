module Dynamo
  module Declaration
    module ClassMethods

      def dynamo(name, type, options={})
        prop = Dynamo::Property.new(name, type, options)
        if dynamos[name].blank?
          dynamos[name] = prop
        end
      end

      def dynamos
        @dynamos ||= if parent = parent_model
          parent.dynamos.dup
        else
          Hash.new
        end
      end

      def parent_model
        (ancestors - [self, Dynamo::Attribute]).find do |parent|
          parent.include?(Dynamo::Attribute)
        end
      end

    end

    module InstanceMethods

      def dynamos_declared
        @dynamos_declared ||= self.class.dynamos
      end

      protected

        def dynamo_property_validation
          @dynamo.each do |dyn, value|
            declaration_validation(dyn)
            data_type_validation(dyn, value)
          end
        end

        def declaration_validation(dyn)
          unless dynamos_declared.has_key?(dyn)
            errors.add("#{dyn}", "dynamo is not declared")
          end
        end

        def data_type_validation(dyn, value)
          if declared_dyn = dynamos_declared[dyn]
            if !value.kind_of?( type = declared_dyn.data_type)
              errors.add("#{dyn}", "dynamo has wrong data type. Received #{value.class}, expected #{type}")
            end
          end
        end

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :validate, :dynamo_property_validation
    end
  end
end