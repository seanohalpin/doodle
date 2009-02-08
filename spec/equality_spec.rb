require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'equality' do
  temporary_constants :Foo, :Bar, :Baz do
    before(:each) do
      class Bar < Doodle
        has :name
      end
      class Foo < Doodle
        has :id
        has Bar
      end
      class Baz < Doodle
        has :id
        has Bar
      end
      @foo1 = Foo.new do
        id 1
        bar "Hello"
      end
      @foo2 = Foo.new do
        id 1
        bar "Hello"
      end
      @baz = Baz.new do
        id 1
        bar "Hello"
      end
    end

    it 'should be equal to another Doodle with the same class and values' do
      @foo1.should_be @foo2
    end

    it 'should not equal another Doodle with the same values but different class' do
      @foo1.should_not_be @baz
    end
  end
end
