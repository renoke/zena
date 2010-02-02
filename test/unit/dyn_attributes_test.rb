require 'test_helper'

class DynDummy < ActiveRecord::Base
  before_save :set_dummy_node_id
  set_table_name 'versions'

  include Dynamo::Attribute
  dynamo :color, String
  dynamo :life, String
  dynamo :shoes, String

  def set_dummy_node_id
    self[:node_id] = 0
    self[:user_id] = 0
  end
end

class ChildDummy < DynDummy
  dynamo :age, Numeric
end

class DynAttributesTest < Test::Unit::TestCase

  context 'creating an object' do
    setup do
      DynDummy.create(:title => 'worn-shoes', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    end

    should_create :dyn_dummy
  end

  context 'Simple test' do
    setup do
      @record = DynDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'', :shoes=>'worn')
    end
    subject {@record}

    should 'create and read dynamo on record' do
      assert_nil subject.dyn[:color]
      subject.dyn[:color] = 'blue'
      assert_equal 'blue', subject.dyn[:color]
      assert_save subject
      subject.reload
      assert_equal 'blue', subject.dyn[:color]
    end

    should 'load dynamo after find' do
      record = DynDummy.find(subject)
      assert_equal 'worn', record.dyn[:shoes]
    end

    should 'update attributes' do
      subject.update_attributes(:title=>'lolipop', :life=>'fun')
      assert_equal 'lolipop', subject.title
      assert_equal 'worn', subject.dyn[:shoes]
      assert_equal 'fun', subject.dyn[:life]
    end

    should 'save updated attributes' do
      subject.update_attributes(:title=>'lolipop', :life=>'fun')
      assert subject.save
      subject.reload
      assert_equal 'lolipop', subject.title
      assert_equal 'worn', subject.dyn[:shoes]
      assert_equal 'fun', subject.dyn[:life]
    end

    should 'delete attribute' do
      subject.dyn.delete :shoes
      assert_nil subject.dyn[:shoes]
      subject.save
      subject.reload
      assert_nil subject.dyn[:shoes]
    end

    should 'delete attributes with update_attributes' do
      subject.update_attributes(:life => nil, :shoes => nil)
      assert_nil subject.dyn[:life]
      assert_nil subject.dyn[:shoes]
    end

    should 'each itarate on object dynamos' do
      subject.update_attributes(:color=>'blue', :life=>'fun', :shoes=>'worn')
      subject.dyn.each do |k,v|
        case k
        when 'color'
          assert_equal 'blue', v
        when 'life'
          assert_equal 'fun', v
        when 'shoes'
          assert_equal 'worn', v
        end
      end
    end
  end

  context 'Advanced test' do
    should 'replace exchange dynamo between object' do
      record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
      record2 = DynDummy.create(:title => 'hulk', :text=>'', :comment=>'', :summary=>'', :lobotomize=>'me')
      record2.dyn = record.dyn
      record2.save
      assert_equal 'blue', record2.dyn[:color]
      assert_nil record2.dyn[:lobotomize]
    end

    should 'replace dynamo' do
      assert record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
      record.dyn = {:color => 'yellow'}
      record.save
      assert_equal 'yellow', record.dyn[:color]
      assert_nil record.dyn[:life]
      assert_nil record.dyn[:shoes]
    end

    should 'destroy object with dynamos' do
      record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :life=>'fun')
      n = DynDummy.count
      assert record.destroy
      assert record.frozen?
      assert_equal n-1, DynDummy.count
    end

    should 'change object' do
      record = DynDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'', :color=>'red', :life => 'in love')
       assert !record.changed?
       record.update_attributes(:color=>'black')
       assert !record.changed?
       record.dyn[:life] = 'in depression'
       assert record.changed?
    end
  end

  context 'Wiht inheritence' do
    should 'child class be able to create parent dynamos' do
      assert record = ChildDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'', :color=>'red', :life => 'in love')
      assert_equal 'red', record.dyn[:color]
    end

    should 'child class be able to own dynamos' do
      assert record = ChildDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'', :color=>'red', :age => 10)
      assert_equal 'red', record.dyn[:color]
      assert_equal 10, record.dyn[:age]
    end
  end

end