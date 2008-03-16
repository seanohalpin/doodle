require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'parents' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :var1, :kind => Integer
        has :var2, :kind => Integer, :default => 1
        must 'have var1 != var2' do
          var1 != var2
        end
      end
    end
    
    it 'should not duplicate validations when accessing them!' do
      foo = Foo 2
      foo.validations.size.should == 1
      foo.validations.size.should == 1
    end
  end
end