module Dynamo
  module Declaration
    module ClassMethods

      def dynamo(name, type, options)
        prop = Property.new(name, type, options)
      end

      def properties
        @properties ||= if parent
          parent.keys.dup
        else
          Hash.new
        end
      end

      def parent
        (ancestors - [self]).find do |parent|
          parent.include?(Dynamo::Attribute)
        end
      end

    end

    module InstanceMethods

    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
    end
  end
end