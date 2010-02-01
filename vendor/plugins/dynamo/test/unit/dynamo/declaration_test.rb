require 'test_helper'
require 'fixtures'

class DeclarationDirty < Test::Unit::TestCase

  context 'Parent model' do
    should 'return parent class' do
      assert_equal 'Employee', Developer.parent_model.name
      assert_equal 'Developer', WebDeveloper.parent_model.name
    end

    should 'be nil if parents doesnt include Dynamo' do
      assert_nil Employee.parent_model
    end

    should 'include Dynama::Attribute' do
      assert Developer.parent_model.include?(Dynamo::Attribute)
    end
  end

  context 'dynamos' do
    should 'return an empty Hash by default' do
      AnonClass = Class.new(Version)
      assert_equal Hash[], AnonClass.dynamos
    end

    should 'return list of dynamo properties when declared' do
      assert_kind_of Hash, Employee.dynamos
      assert_kind_of Dynamo::Property, Employee.dynamos[:first_name]
    end

    should 'return parents dynamo' do
      assert_equal :first_name, Developer.dynamos[:first_name].name
    end
  end


end