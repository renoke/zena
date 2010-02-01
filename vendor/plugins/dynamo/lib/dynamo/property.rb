module Dynamo
  class Property
    attr_accessor :name, :type, :options, :default, :indexed

    def initialize(name, type, options={})
      @name, @type = name, type
      self.default = options.delete(:default)
      self.indexed = options.delete(:indexed)
      self.options = options
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