require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'has' do
  temporary_constant :Foo, :SpecializedAttribute do
    before :each do
      class SpecializedAttribute < Doodle::Attribute
      end
      
      class Foo < Doodle
      end
    end
    
    it 'should allow :using keyword' do
      proc {
        Foo.class_eval do
          has :ivar1, :kind => String, :using => SpecializedAttribute
        end
      }.should_not raise_error
    end

    it 'should interpret :using keyword and return a specialized attribute of correct class' do
      class Foo < Doodle
        rv = has(:ivar1, :kind => String, :using => SpecializedAttribute)
        rv.class.should == SpecializedAttribute
      end
    end
  end
end

