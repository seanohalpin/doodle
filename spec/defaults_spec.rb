require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'attributes with defaults' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Helper
        has :name, :default => 'D1'
        class << self
          has :metadata, :default => 'D2'
        end
      end
      @foo = Foo.new
      class << @foo
        has :special, :default => 'D3'
      end
    end
  
    it 'should have instance attribute default via class' do
      Foo.attributes[:name].default.should == 'D1'
    end
    it 'should have instance attribute default via instance' do
      @foo.attributes[:name].default.should == 'D1'
    end
    it 'should have class attribute default via class.meta' do
      Foo.singleton_class.attributes(false)[:metadata].default.should == 'D2'
    end
    it 'should have class attribute default via class.meta' do
      Foo.singleton_class.attributes[:metadata].default.should == 'D2'
    end
    it 'should have singleton attribute default via instance.singleton_class.attributes(false)' do
      @foo.singleton_class.attributes(false)[:special].default.should == 'D3'
    end
    it 'should have singleton attribute default via instance.singleton_class.attributes' do
      @foo.singleton_class.attributes[:special].default.should == 'D3'
    end
    it 'should have singleton attribute name by default' do
      @foo.name.should == 'D1'
    end
    it 'should have singleton attribute name by default' do
      Foo.metadata.should == 'D2'
    end
    it 'should have singleton attribute special by default' do
      @foo.special.should == 'D3'
    end

    it 'should not have a @name instance variable' do
      @foo.instance_variables.include?("@name").should == false
      @foo.instance_variables.sort.should == []
    end
    it 'should not have a @metadata class instance variable' do
      Foo.instance_variables.include?("@metadata").should == false
      Foo.instance_variables.sort.should == []
    end
    it 'should not have @special singleton instance variable' do
      @foo.singleton_class.instance_variables.include?("@special").should == false
      @foo.singleton_class.instance_variables.sort.should == []
    end
  end
end

describe Doodle, 'defaults which have not been set' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :baz
      end
    end

    it 'should raise error if required attributes not passed to new' do
      proc { foo = Foo.new }.should raise_error(ArgumentError)
    end

    it 'should not raise error if required attributes passed to new' do
      proc { foo = Foo.new(:baz => 'Hi' ) }.should_not raise_error
    end
  end
end

describe Doodle, 'defaults which have been set' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :baz, :default => 'Hi!'
        has :start do
          default { Date.today }
        end
      end
      @foo = Foo.new
    end

    it 'should have default value set from hash arg' do
      @foo.baz.should == 'Hi!'
    end

    it 'should have default value set from block' do
      @foo.start.should == Date.today
    end
  end
end

describe Doodle, "overriding inherited defaults" do
  temporary_constant :Text, :Text2, :KeyValue do
    before :each do
      class KeyValue < Doodle::Base
        has :name
        has :value
      end
      class Text < KeyValue
        has :name, :default => "text"
      end
      class Text2 < Text
        has :value, :default => "any2"
      end
    end
  
    it 'should not raise error if initialized with required values' do
      proc { Text.new(:value => 'any') }.should_not raise_error
    end
  
    it 'should allow initialization using defaults' do
      text = Text.new(:value => 'any')
      text.name.should == 'text'
      text.value.should == 'any'
    end
  
    it 'should raise ArgumentError if initialized without all required values' do
      proc { KeyValue.new(:value => 'Enter name:') }.should raise_error(ArgumentError)
    end
  
    it 'should allow initialization using inherited defaults' do
      text = Text2.new
      text.name.should == 'text'
      text.value.should == 'any2'
    end
  end
end
