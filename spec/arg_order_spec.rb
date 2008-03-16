require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'arg_order' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :name
        has :extra
        has :value
        arg_order :value, :name
      end
    end
    it 'should specify order of positional arguments' do
      foo = Foo.new 1, 2, 3
      foo.value.should == 1
      foo.name.should == 2
      foo.extra.should == 3
    end

    it 'should allow only symbols as arguments to arg_order' do
      proc { Foo.arg_order Foo}.should raise_error(Doodle::InvalidOrderError)
      proc { Foo.arg_order 1}.should raise_error(Doodle::InvalidOrderError)
      proc { Foo.arg_order Date.new}.should raise_error(Doodle::InvalidOrderError)
    end

    it 'should not allow invalid positional arguments' do
      proc { Foo.arg_order :smoo}.should raise_error(Doodle::InvalidOrderError)
      proc { Foo.arg_order :name, :value}.should_not raise_error
    end
  end
end

describe 'arg_order' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle::Base
        has :name
      end
      class Bar < Foo
        has :value
      end
    end
    it 'should specify order of positional arguments' do
      f = Bar.new 1, 2
      f.name.should == 1
      f.value.should == 2
    end
  end
end

describe 'arg_order' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle::Base
        has :name
      end
      class Bar < Foo
        has :value
        arg_order :value, :name
      end
    end
    it 'should specify order of positional arguments' do
      f = Bar.new 1, 2
      f.value.should == 1
      f.name.should == 2
    end  
  end
end

describe 'arg_order' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle::Base
        has :name, :default => proc { self.class.to_s.downcase }
      end
      class Bar < Foo
        has :value
        arg_order :value, :name
      end
    end
  
    it 'should specify order of positional arguments' do
      f = Bar.new 1
      f.value.should == 1
      f.name.should == "bar"
    end  
  end
end

describe 'arg_order' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle::Base
        has :name
      end
      class Bar < Foo
        has :value
        arg_order :value, :name
      end
    end
  
    it 'should specify order of positional arguments' do
      f = Bar.new 1, "bar"
      f.value.should == 1
      f.name.should == "bar"
    end  
  end
end
