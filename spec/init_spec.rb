require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'init' do
  temporary_constant :Foo do
  
    before(:each) do
      class Foo
        include Doodle::Helper
        has :name, :init => 'D1'
        class << self
          has :metadata, :init => 'D2'
        end
      end
      @foo = Foo.new
      class << @foo
        has :special, :init => 'D3'
      end
    end
  
    it 'should have instance attribute init via class' do
      Foo.attributes[:name].init.should == 'D1'
    end
    it 'should have instance attribute init via instance' do
      @foo.attributes[:name].init.should == 'D1'
    end
    it 'should have class attribute init via class.singleton_class' do
      Foo.singleton_class.attributes(false)[:metadata].init.should == 'D2'
    end
    it 'should have class attribute init via class.singleton_class' do
      Foo.singleton_class.attributes[:metadata].init.should == 'D2'
    end
    it 'should have singleton attribute init via instance.singleton_class' do
      @foo.singleton_class.attributes(false)[:special].init.should == 'D3'
    end
    it 'should have singleton attribute init via instance.singleton_class' do
      @foo.singleton_class.attributes[:special].init.should == 'D3'
    end
    it 'should have an attribute :name from init' do
      @foo.name.should == 'D1'
    end
    it 'should have an instance_variable for attribute :name' do
      @foo.instance_variables.include?('@name').should == true
    end
    it 'should have an initialized class attribute :metadata' do
      pending 'deciding how this should work'
      #Foo.metadata.should == 'D2'
    end
    it 'should have an initialized singleton attribute :special' do
      pending 'deciding how this should work'
      #@foo.special.should == 'D3'
    end
  end
end
