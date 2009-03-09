require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'assigned? with default' do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :name, :default => nil
      end
    end

    it 'should return false if attribute not assigned' do
      foo = Foo.new
      foo.assigned?(:name).should_be false
    end

    it 'should return true if attribute assigned' do
      foo = Foo.new('foo')
      foo.assigned?(:name).should_be true
    end

  end
end

describe Doodle, 'assigned? with init' do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :name, :init => ""
      end
    end

    it 'should return true if attribute has init even when not specifically assigned' do
      foo = Foo.new
      foo.assigned?(:name).should_be true
    end

    it 'should return true if attribute has init and has been assigned' do
      foo = Foo.new('foo')
      foo.assigned?(:name).should_be true
    end

  end
end
