begin
  dir = File.dirname(__FILE__)
  require "#{dir}/dynamo/accessors"
  require "#{dir}/dynamo/core"
  require "#{dir}/serialization/yaml"
  require "#{dir}/serialization/marshal"
end
