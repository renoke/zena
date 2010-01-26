require 'test_helper'
require 'fixtures'

class TestAccessors < Test::Unit::TestCase

  context 'Module inclusion' do

    should 'class respond to dynamo=erty' do
      assert Employee.respond_to?(:dynamo=erty)
    end

    should 'set dynamo=erty with a name and a data type' do
      assert Employee.send :dynamo=erty, :first_name, String
    end

    should 'raise error if no type set' do
      assert_raise(ArgumentError){ Employee.send :dynamo=erty, :first_name }
    end
  end

  context 'Attributes definition' do

    subject { Employee.new }

    should 'instance respond to dynamo=erty getter' do
      assert subject.respond_to?(:first_name)
    end

    should 'instance respond to dynamo=rety setter' do
      assert subject.respond_to?(:first_name=)
    end

    should 'instance check if dynamo=rety is present' do
      assert subject.respond_to?(:first_name?)
    end
  end

  context 'Attributes accessors' do

    setup do
      @employee = Employee.new
    end

    subject { @employee }

    should 'write attribute' do
      assert subject.first_name = 'Jim'
    end

    should 'read attribute' do
      subject.first_name = 'Jim'
      assert_attribute 'Jim', 'first_name'
    end

    should 'read attribute before type cast' do
      subject.first_name = 'Jim'
      assert_equal 'Jim', subject.first_name_before_type_cast
    end

    should 'check if attribute is present' do
      assert !subject.first_name?
      subject.first_name = 'Jim'
      assert subject.first_name?
    end

   should 'raise undefined method if attribute not defined' do
     assert_raise(NoMethodError) {subject.dummy='nothing'}
   end

   should 'return attributes allocated' do
     subject.first_name = 'Jim'
     assert_equal Hash['first_name'=>'Jim'], subject.attributes_without_dynamo=erties
   end

   should 'allocate attributes' do
     subject.attributes=(Hash['first_name'=>'Jo', 'last_name'=>'Dalton'])
     assert_attribute 'Jo', 'first_name'
   end

   should 'instantiate attributes' do
     subject = Employee.new(:first_name=>'Avrel', :last_name=>'Dalton')
     assert_equal 'Avrel', subject.first_name
     assert_equal 'Avrel', subject['first_name']
     assert_equal 'Avrel', subject.attributes['first_name']
     assert_equal 'Avrel', subject.dynamo=erties['first_name']
   end

  end

  context 'Inheritance' do
    setup do
      @developer = Developer.new
    end

    subject { @developer }

    should 'inherite parent dynamo=rety' do
      assert subject.first_name = 'Jimmy'
      assert_equal 'Jimmy', subject.first_name
    end


  end

  context 'Persistance' do
    setup do
       @employee = Employee.new
    end

    should 'save object with dynamo=erties' do
      @employee.first_name = 'Kate'
      assert @employee.save
      assert_equal 'Kate', @employee.first_name
      assert_equal 'Kate', @employee.attributes['first_name']
      assert_equal 'Kate', @employee.dynamo=erties['first_name']
    end

    should 'save! object with dynamo=erties' do
      @employee.first_name = 'Kate'
      assert @employee.save!
      assert_equal 'Kate', @employee.first_name
      assert_equal 'Kate', @employee.attributes['first_name']
      assert_equal 'Kate', @employee.dynamo=erties['first_name']
    end

    should 'create object with dynamo=erties' do
      assert actress = Employee.create(:first_name=>'Eva',:last_name=>'Longoria')
      assert_equal 'Eva', actress.first_name
      assert_equal 'Eva', actress.attributes['first_name']
      assert_equal 'Eva', actress.dynamo=erties['first_name']
    end

    should 'update object attributes with dynamo=erties' do
      pionier = Employee.create(:first_name=>'Ada',:last_name=>'Byron')
      assert pionier.update_attributes(:last_name=>'Lovelace')
      assert_attribute 'Lovelace', 'last_name', pionier
    end

  end

  context 'Find' do
    setup do
      Employee.create(:first_name=>'Martin', :last_name=>'Heidegger')
    end

    subject { Employee.first}

    should 'load first object' do
      assert_attribute 'Martin', 'first_name'
    end
  end


end