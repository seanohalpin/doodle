require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'readonly attributes' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :ivar1, :readonly => true
      end
    end
    
    it 'should allow setting readonly attribute during initialization' do
      proc { Foo.new(:ivar1 => "hello") }.should_not raise_error
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo.new(:ivar1 => "hello")
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

    it 'should not allow setting readonly attribute after initialization' do
      foo = Foo do
        ivar1 "hello"
      end
      foo.ivar1.should_be "hello"
      proc { foo.ivar1 = "world"}.should raise_error(Doodle::ReadOnlyError)
    end

  end
end

