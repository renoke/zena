require 'test_helper'
require 'fixtures'

class DeclarationDirty < Test::Unit::TestCase


  context 'Ancestors' do

    should ' parent class ' do
      assert_equal 'Employee', Developer.parent.name
      assert_equal 'Developer', WebDeveloper.parent.name
    end

    should 'parent include Dynama::Attribute' do
      assert Developer.parent.include?(Dynamo::Attribute)
    end



  end


end