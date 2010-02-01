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

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.send :before_validation, Dynamo::Validator.new
    end
  end
end