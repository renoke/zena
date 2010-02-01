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

      def dynamo_property_for!(name)
         dynamos_declared[name] || raise(NameError)
      end

      protected

        def dynamo_property_validation
          @dynamo.each do |dyn, value|
            self.errors.add("#{dyn}", "dynamo is not declared") unless dynamos_declared.has_key?(dyn)
            self.errors.add("#{dyn}", "dynamo has wrong data type") unless valid_data_type_for?(dyn)
          end
        end

        def valid_data_type_for?(dyn)
          dynamos_declared.has_key?(dyn) && dyn.kind_of?(dynamos_declared[dyn].data_type)
        end


    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :validate, :dynamo_property_validation
    end
  end
end