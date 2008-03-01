require 'lib/spec_helper'

describe Doodle::Attribute, 'basics' do
  after :each do
    undefine_const(:Bar)
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined(:Foo, :Bar)
    
    class Foo
      include Doodle::Helper
      has :name, :default => 'Hello'
      class << self
        has :metadata
      end
    end
    class Bar < Foo
      has :info
      class << self
        has :doc
      end
    end
    
    @goo = Foo.new
    @baz = Bar.new :info => 'Hi'
  end

  it 'should have default name' do
    #pending 'making it work'
    #p [:name, :default, @goo.attributes[:name].default]
    @goo.attributes[:name].default.should == 'Hello'
  end

  it 'should have default name' do
    #pending 'making it work'
    @goo.name.should == 'Hello'
  end

  it 'should have name required == false (because has default)' do
    #pending 'to do required/optional'
    @goo.attributes[:name].required?.should == false
  end

  it 'should have info required == true' do
    #pending 'to do required/optional'
    @baz.attributes[:info].required?.should == true
  end

  it 'should have name.optional? == true (because has default)' do
    #pending 'to do required/optional'
    @goo.attributes[:name].optional?.should == true
  end

  it 'should have info.optional? == false' do
    #pending 'to do required/optional'
    @baz.attributes[:info].optional?.should == false
  end

  it "should have parents in order" do
    Bar.parents.should == [Foo, Object]
  end
    
  it "should have Bar's meta parents in reverse order of definition" do
    @baz.meta.parents.should == [Bar.singleton_class.singleton_class, Bar.singleton_class, Foo.singleton_class]
  end

  it 'should have inherited meta local_attributes in order of definition' do
    @baz.meta.class_eval { collect_inherited(:local_attributes).map { |x| x[0]} }.should == [:metadata, :doc]
  end

  it 'should have inherited meta attributes in order of definition' do
    @baz.meta.attributes.keys.should == [:metadata, :doc]
  end
end

describe Doodle::Attribute, 'attribute order' do
  before :each do
    undefine_const(:A)
    undefine_const(:B)
    undefine_const(:C)

    class A < Doodle::Base
      has :a
    end

    class B < A
      has :b
    end

    class C < B
      has :c
    end

  end

  it 'should keep order of inherited attributes' do
    C.parents.should == [B, A, Doodle::Base, Object]
  end

  it 'should keep order of inherited attributes' do
    C.attributes.keys.should == [:a, :b, :c]
  end
end

raise_if_defined(:Foo, :Bar, :A, :B, :C)
