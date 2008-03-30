require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, ' unspecified attributes' do
  temporary_constants :Foo do
    before :each do 
      class Foo < Doodle::Base
      end
    end
  
    it 'should raise Doodle::ValidationError for unspecified attributes' do
      proc { foo = Foo(:name => 'foo') }.should raise_error(Doodle::ValidationError)
    end
  end
end