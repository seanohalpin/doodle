require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'kind' do
  temporary_constant :Foo do
    before :each do
      p [:in_spec_each, self, self.object_id, "%x" % (self.object_id << 1)]
      class Foo < Doodle
        has :var1, :kind => [String, Symbol]
        p [:in_spec_Foo, self, self.object_id]
      end
      p [:in_spec_each, self.class, self.object_id, "%x" % (self.object_id << 1)]
    end
    
    it 'should allow multiple kinds' do
      proc { Foo 'hi' }.should_not raise_error
      proc { Foo :hi }.should_not raise_error
      proc { Foo 1 }.should raise_error(Doodle::ValidationError)
    end
  end
end
