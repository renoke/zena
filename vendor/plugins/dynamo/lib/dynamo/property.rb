module Dynamo
  class Property
    attr_accessor :name, :type, :options, :default_value

    def initialize(name, type, options={})
      @name, @type = name, type
      self.options = options.symbolize_keys
      self.default_value = self.options.delete(:default)
    end

    def ==(other)
      @name == other.name && @type == other.type
    end

    def get(value)
      if value.nil? && !default_value.nil?
        return default_value
      end

      type_cast(value)
    end
  end
end