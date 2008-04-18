require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, ' unspecified attributes' do
  temporary_constants :Foo do
    before :each do 
      class Foo < Doodle
      end
    end
  
    it 'should raise Doodle::UnknownAttributeError for unspecified attributes' do
      proc { foo = Foo(:name => 'foo') }.should raise_error(Doodle::UnknownAttributeError)
    end
  end
end

describe Doodle::Attribute, ' unspecified attributes' do  
  it 'should raise Doodle::UnknownAttributeError for unspecified attributes' do
    proc { foo = Doodle::Attribute(:name => 'foo', :extra => 'unwanted') }.should raise_error(Doodle::UnknownAttributeError)
  end
end