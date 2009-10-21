require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::DeferredBlock do
  temporary_constant :Foo do

    before :each do
      class Foo < Doodle
        has :name do
          init { `uname`.chomp }
        end
      end
    end

    it 'should dynamically assign name' do
      foo = Foo.new
      foo.name.should_be `uname`.chomp
    end

  end
end

