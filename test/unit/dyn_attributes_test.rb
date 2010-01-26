require 'test_helper'

class DynDummy < ActiveRecord::Base
  before_save :set_dummy_node_id
  set_table_name 'versions'
  #include Zena::Use::DynAttributes::ModelMethods
  #dynamic_attributes_setup :nested_alias => {%r{^d_(\w+)} => ['dyn']}
  include Dynamo::Core
  include Dynamo::Serialization::Marshal

  def set_dummy_node_id
    self[:node_id] = 0
    self[:user_id] = 0
  end
end

class DynStrictDummy < ActiveRecord::Base
  set_table_name 'versions'
  # include Zena::Use::DynAttributes::ModelMethods
  # dynamic_attributes_setup :only => [:bio, :phone], :nested_alias => {%r{^d_(\w+)} => ['dyn']}
  include Dynamo::Core
  include Dynamo::Serialization::Marshal

  def before_save
    self[:node_id] = 123
    self[:user_id] = 123
  end
end

class DynSubStrictDummy < DynStrictDummy
end

class DynSub2StrictDummy < DynStrictDummy
  include Zena::Use::DynAttributes::ModelMethods
  dynamic_attributes_setup :only => [:hell]
end

class AttrDummy < ActiveRecord::Base
  set_table_name 'dyn_attributes'
end

class DynAttributesTest < Test::Unit::TestCase

  context 'creating an object' do
    setup do
      DynDummy.create(:title => 'worn-shoes', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    end

    should_create :dyn_dummy
  end

  def test_simple
    assert record = DynDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'')
    assert_nil record.dyn['color']
    record.dyn['color'] = 'blue'
    assert_equal 'blue', record.dyn['color']
    assert_nil record.dyn[:color]
    assert record.save

    record = DynDummy.find(record[:id]) # reload
    assert_equal 'blue', record.dyn['color']
  end

  def test_find
    record = DynDummy.create(:title => 'worn-shoes', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    assert record = DynDummy.find(record)
    assert_equal 'worn', record.dyn[:shoes]
  end

  def test_update_attributes
    assert record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    assert record.update_attributes(:life => 'hell', :heidegger => 'Martin')
    assert_equal 'Martin', record.dyn[:heidegger]
    assert_equal 'blue', record.dyn[:color]
  end

  def test_delete
    assert record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :d_color=>'blue', :d_life=>'fun', :d_shoes=>'worn')
    proxy = record.dyn
    keys = proxy.instance_variable_get(:@keys)
    assert record.update_attributes(:d_life => nil)
    assert_nil record.dyn['life']
    assert_nil AttrDummy.find_by_id(keys['life'])
  end

  def test_delete_many
    assert record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    assert record.update_attributes(:life => nil, :shoes => nil)
    assert_nil record.dyn[:life]
    assert_nil record.dyn[:shoes]
  end

  def test_each
    assert record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :d_color=>'blue', :d_life=>'fun', :d_shoes=>'worn')
    record.dyn.each do |k,v|
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

  def test_dyn_equal
    assert record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    assert record2 = DynDummy.create(:title => 'hulk', :text=>'', :comment=>'', :summary=>'', :lobotomize=>'me')
    record2.dyn = record.dyn
    record2.save

    record2 = DynDummy.find(record2[:id]) # reload
    assert_equal 'blue', record2.dyn[:color]
    assert_nil record2.dyn[:lobotomize]
  end

  def test_dyn_update_with
    assert record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :color=>'blue', :life=>'fun', :shoes=>'worn')
    record.dyn = {:color => 'yellow', :lobotomize=>'me'}
    record.save

    record = DynDummy.find(record[:id]) # reload
    assert_equal 'yellow', record.dyn[:color]
    assert_equal 'me', record.dyn[:lobotomize]
    assert_nil record.dyn[:life]
    assert_nil record.dyn[:shoes]
  end

  def test_set_with_hash
    assert record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'')
    record.dyn = {'fingers' => 'hurt'}
    assert record.save, "Can save"

    record = DynDummy.find(record[:id]) # reload
    assert_equal 'hurt', record.dyn['fingers']
  end

  def test_delete
    assert record  = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :life=>'fun', :joy=>'weird')
    assert_equal 'weird', record.dyn.delete(:joy)
    assert_nil record.dyn[:joy]
    assert record.save
    record = DynDummy.find(record) # reload
    assert_nil record.dyn[:joy]
    assert_equal 'fun', record.dyn[:life]
  end

  def test_destroy
    record = DynDummy.create(:title => 'lolipop', :text=>'', :comment=>'', :summary=>'', :life=>'fun', :joy=>'weird')
    n = DynDummy.count
    assert record.destroy
    assert record.frozen?
    assert_equal n-1, DynDummy.count
  end

  def test_changed
    record = DynDummy.create(:title => 'this is my title', :text=>'', :comment=>'', :summary=>'', :bio=>'biography', :hell => 'blind love')
    assert !record.changed?
    record.attributes={:bio=>'biography'}
    assert !record.changed?
    record.attributes={:bio=>'Gemüse'}
    assert record.changed?
  end
end