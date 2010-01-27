begin
  dir = File.dirname(__FILE__)
  require "#{dir}/dynamo/attribute"
  require "#{dir}/dynamo/accessors"
  require "#{dir}/serialization/yaml"
  require "#{dir}/serialization/marshal"
end
