require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Factory, " as part of Doodle::Base" do
  temporary_constant :Foo do
    before(:each) do
      class Foo < Doodle::Base
        has :var
      end
    end

    it 'should allow factory function' do
      foo = Foo("abcd")
      foo.var.should == "abcd"
    end
  end
end

describe Doodle::Factory, " included as module" do
  temporary_constant :Baz do
    before(:each) do
      class Baz
        include Doodle::Helper
        include Doodle::Factory
        has :var
      end
    end

    it 'should allow factory function' do
      foo = Baz("abcd")
      foo.var.should == "abcd"
    end
  end
end

