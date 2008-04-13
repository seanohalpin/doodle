require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'class attributes:' do
    temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :ivar
        class << self
          has :cvar, :kind => Integer, :init => 1
        end
      end
    end

    it 'should be possible to set a class var without setting an instance var' do
      proc { Foo.cvar = 42 }.should_not raise_error
      Foo.cvar.should == 42
    end
    
    it 'should be possible to set an instance variable without setting a class var' do
      proc { Foo.new :ivar => 42 }.should_not raise_error
    end

    it 'should validate class var' do
      proc { Foo.cvar = "Hello" }.should raise_error(Doodle::ValidationError)
    end

    it 'should be possible to read initialized class var' do
      pending 'getting this working' do
        proc { Foo.cvar == 1 }.should_not raise_error
      end
    end
  end
end
