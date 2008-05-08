require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'init' do
  temporary_constant :Foo do
    
    before(:each) do
      class Foo
        include Doodle::Core
        has :moniker, :init => 'D1'
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
      Foo.doodle_attributes[:moniker].init.should == 'D1'
    end
    it 'should have instance attribute init via instance' do
      @foo.doodle_attributes[:moniker].init.should == 'D1'
    end
    it 'should have class attribute init via class.singleton_class' do
      Foo.singleton_class.doodle_attributes(false)[:metadata].init.should == 'D2'
    end
    it 'should have class attribute init via class.singleton_class' do
      Foo.singleton_class.doodle_attributes[:metadata].init.should == 'D2'
    end
    it 'should have singleton attribute init via instance.singleton_class' do
      @foo.singleton_class.doodle_attributes(false)[:special].init.should == 'D3'
    end
    it 'should have singleton attribute init via instance.singleton_class' do
      @foo.singleton_class.doodle_attributes[:special].init.should == 'D3'
    end
    it 'should have an attribute :moniker from init' do
      @foo.moniker.should == 'D1'
    end
    it 'should have an instance_variable for attribute :moniker' do
      @foo.instance_variables.map{ |x| x.to_sym }.include?(:@moniker).should == true
    end
    it 'should have an initialized class attribute :metadata' do
      #pending 'deciding how this should work' do
        Foo.metadata.should == 'D2'
      #end
    end
    it 'should have an initialized singleton attribute :special' do
      #pending 'deciding how this should work' do
        @foo.special.should == 'D3'
      #end
    end
  end
end

describe Doodle, 'init' do  
  temporary_constant :Foo do
    it 'should accept nil as :init' do
      class Foo < Doodle
        has :value, :init => nil
      end
      foo = Foo.new
      foo.value.should == nil
    end
  end
  temporary_constant :Foo do
    it 'should accept true as :init' do
      class Foo < Doodle
        has :value, :init => true
      end
      foo = Foo.new
      foo.value.should == true
    end
  end
  temporary_constant :Foo do
    it 'should accept Fixnum as :init' do
      class Foo < Doodle
        has :value, :init => 42
      end
      foo = Foo.new
      foo.value.should == 42
    end
  end
  temporary_constant :Foo do
    it 'should not evaluate value when proc given as :init' do
      class Foo < Doodle
        has :value, :init => proc { 42 }
      end
      foo = Foo.new
      foo.value.call.should == 42
    end
  end
  temporary_constant :Foo do
    it 'should evaluate value when block given as :init' do
      class Foo < Doodle
        has :value do
          init do
            42
          end
        end
      end
      foo = Foo.new
      foo.value.should == 42
    end
  end
end
