require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Attribute, 'basics' do
  temporary_constants :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
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
    
      @foo = Foo.new
      @bar = Bar.new :info => 'Hi'
    end

    it 'should have attribute :name with default defined' do
      @foo.attributes[:name].default.should == 'Hello'
    end

    it 'should have default name' do
      @foo.name.should == 'Hello'
    end

    it 'should not have an instance variable for a default' do
      @foo.instance_variables.include?('@name').should == false
    end

    it 'should have name required == false (because has default)' do
      @foo.attributes[:name].required?.should == false
    end

    it 'should have info required == true' do
      @bar.attributes[:info].required?.should == true
    end

    it 'should have name.optional? == true (because has default)' do
      @foo.attributes[:name].optional?.should == true
    end

    it 'should inherit attribute from parent' do
      @bar.attributes[:name].should == @foo.attributes[:name]
    end

    it 'should have info.optional? == false' do
      @bar.attributes[:info].optional?.should == false
    end

    it "should have parents in correct order" do
      Bar.parents.should == [Foo, Object]
    end
    
    it "should have Bar's singleton parents in reverse order of definition" do
      @bar.singleton_class.parents.should == [Bar.singleton_class.singleton_class, Bar.singleton_class, Foo.singleton_class]
    end

    it 'should have inherited class attributes in order of definition' do
      Bar.singleton_class.attributes.map { |x| x[0]}.should == [:metadata, :doc]
    end
    
    it 'should have inherited singleton local_attributes in order of definition' do
      @bar.singleton_class.class_eval { collect_inherited(:local_attributes).map { |x| x[0]} }.should == [:metadata, :doc]
    end

    it 'should have inherited singleton attributes(false) in order of definition' do
      @bar.singleton_class.attributes.map { |x| x[0]} .should == [:metadata, :doc]
    end
    
    it 'should have inherited singleton attributes in order of definition' do
      @bar.singleton_class.attributes.keys.should == [:metadata, :doc]
    end
  end
end

describe Doodle::Attribute, 'attribute order' do
  temporary_constants :A, :B, :C do
    before :each do
      class A < Doodle
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
      C.parents.should == [B, A, Doodle, Object]
    end

    it 'should keep order of inherited attributes' do
      C.attributes.keys.should == [:a, :b, :c]
    end
  end
end
