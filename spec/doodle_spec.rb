$:.unshift(File.join(File.dirname(__FILE__), '../.'))

# require 'relpath'
# loaddir_parent(__FILE__)
require 'lib/spec_helper'

describe Doodle, 'basics' do
  after :each do
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined :Foo
    class Foo
      include Doodle::Helper
    end
    @foo = Foo.new
  end

  it 'should have meta as synonym for singleton_class' do
    Foo.singleton_class.should == Foo.meta
    @foo.singleton_class.should == @foo.meta
  end
end

describe Doodle, 'instance attributes' do
  after :each do
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined :Foo
    class Foo
      include Doodle::Helper
      has :name, :default => nil
    end
    @foo = Foo.new
  end

  it 'should create attribute' do
    @foo.name = 'Smee'
    @foo.name.should == 'Smee'
  end

  it 'should create attribute using getter_setter' do
    @foo.name 'Smee'
    @foo.name.should == 'Smee'
  end

  it 'should list instance attributes(false)' do
    @foo.attributes(false).keys.should == []
  end

  it 'should list instance attributes' do
    @foo.attributes.keys.should == [:name]
  end
  
  it 'should list all instance attributes(false) at class level' do
    Foo.attributes(false).keys.should == [:name]
  end
  
end

describe Doodle, 'class attributes(false)' do
  after :each do
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined :Foo
    class Foo
      include Doodle::Helper
      class << self
        has :metadata
      end
    end
    @foo = Foo.new
  end

  it 'should create class attribute' do
    Foo.metadata = 'Foo metadata'
    Foo.metadata.should == 'Foo metadata'
  end

  it 'should access class attribute via self.class' do
    @foo.class.metadata = '@foo metadata'
    @foo.class.metadata.should == '@foo metadata'
    Foo.metadata.should == '@foo metadata'

    Foo.metadata = 'Foo metadata'
    Foo.metadata.should == 'Foo metadata'
    @foo.class.metadata.should == 'Foo metadata'
  end

  it "should list all class's own attributes" do
    Foo.meta.attributes(false).keys.should == [:metadata]
  end
  
  it "should list all class's own attributes" do
    Foo.meta.attributes.keys.should == [:metadata]
  end

end

describe Doodle, 'inherited class attributes(false)' do
  after :each do
    undefine_const(:Foo)
    undefine_const(:Bar)
  end
  before(:each) do
    raise_if_defined :Foo, :Bar
  
    class Foo
      include Doodle::Helper
      has :name, :default => nil
      class << self
        has :metadata
      end
    end
    class Bar < Foo
      has :location, :default => nil
      class << self
        has :doc
      end
    end
    @foo = Foo.new
    @bar = Bar.new
  end

  it 'should create inherited class attribute' do
    Foo.metadata = 'Foo metadata'
    Bar.metadata = 'Bar metadata'
    Foo.metadata.should == 'Foo metadata'
    Bar.metadata.should == 'Bar metadata'
    Foo.metadata.should == 'Foo metadata'
  end

  it 'should access class attribute via self.class' do
    @foo.class.metadata = '@foo metadata'
    @foo.class.metadata.should == '@foo metadata'
    Foo.metadata.should == '@foo metadata'

    Foo.metadata = 'Foo metadata'
    Bar.metadata = 'Bar metadata'
    Foo.metadata.should == 'Foo metadata'
    Bar.metadata.should == 'Bar metadata'
    Foo.metadata.should == 'Foo metadata'
    @foo.class.metadata.should == 'Foo metadata'
    @bar.class.metadata.should == 'Bar metadata'
  end

  it 'should access inherited class attribute via self.class' do
    @foo.class.metadata = '@foo metadata'
    @foo.class.metadata.should == '@foo metadata'
    Foo.metadata.should == '@foo metadata'
    Foo.metadata = 'Foo metadata'

    Bar.metadata = 'Bar metadata'
    Bar.metadata.should == 'Bar metadata'
    @bar.class.metadata.should == 'Bar metadata'

    Foo.metadata.should == 'Foo metadata'
    @foo.class.metadata.should == 'Foo metadata'
  end
  
  it "should list class's own attributes" do
    Foo.meta.attributes(false).keys.should == [:metadata]
  end
  
  it "should list all class's own attributes" do
    Foo.meta.attributes.keys.should == [:metadata]
  end

  it "should list class's own attributes(false)" do
    Bar.meta.attributes(false).keys.should == [:doc]
  end

  it "should list all inherited meta class attributes" do
    Bar.meta.attributes.keys.should == [:metadata, :doc]
  end

  it "should list all inherited class's attributes" do
    Bar.attributes.keys.should == [:name, :location]
  end
end

describe Doodle, 'singleton class attributes' do
  after :each do
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined :Foo
  
    class Foo
      include Doodle::Helper
      has :name, :default => nil
      class << self
        has :metadata
      end
    end
    @foo = Foo.new
    class << @foo
      has :special, :default => nil
    end
  end
  
  it 'should allow creation of singleton class attributes' do
    @foo.special = 42
    @foo.special.should == 42
  end

  it 'should list instance attributes' do
    @foo.meta.attributes(false).keys.should == [:special]
  end

  it 'should list instance attributes' do
    @foo.meta.attributes.keys.should == [:metadata, :special]
  end
  
end

describe Doodle, 'inherited singleton class attributes' do
  after :each do
    undefine_const(:Foo)
    undefine_const(:Bar)
  end
  before(:each) do
    raise_if_defined :Foo, :Bar
    
    class Foo
      include Doodle::Helper
      has :name, :default => nil
      class << self
        has :metadata
      end
    end
    class Bar < Foo
      has :info, :default => nil
      class << self
        has :doc
      end
    end

    @foo = Foo.new
    class << @foo
      has :special, :default => nil # must give default because already initialized
    end
    @bar = Bar.new
    @bar2 = Bar.new
    class << @bar
      has :extra
    end
  end
  
  it 'should allow creation of singleton class attributes' do
    @foo.special = 42
    @foo.special.should == 42
    @bar.extra = 84
    @bar.extra.should == 84
    proc { @foo.extra = 1 }.should raise_error(NoMethodError)
    proc { @bar2.extra = 1 }.should raise_error(NoMethodError)
    proc { @bar.special = 1 }.should raise_error(NoMethodError)
  end

  it 'should list instance attributes' do
    @foo.class.attributes(false).keys.should == [:name]
    @bar.class.attributes(false).keys.should == [:info]
    @bar2.class.attributes(false).keys.should == [:info]
  end

  it 'should list instance meta attributes' do
    @foo.meta.attributes(false).keys.should == [:special]
    @bar.meta.attributes(false).keys.should == [:extra]
  end

  it 'should list instance attributes' do
    @foo.meta.attributes.keys.should == [:metadata, :special]
    @bar.meta.attributes.keys.should == [:metadata, :doc, :extra]
  end
  
  it 'should keep meta attributes separate' do
     @foo.special = 'foo special'
     @foo.meta.metadata = 'foo meta'
#     @bar.meta.metadata = 'bar meta'
#     @bar.meta.doc = 'bar doc'
#     Foo.metadata = 'Foo meta'
#     Bar.metadata = 'Bar meta'
#     Bar.doc = 'Bar doc'

#     @foo.meta.metadata.should == 'foo meta'
#     @bar.meta.metadata.should == 'bar meta'
#     @bar.meta.doc.should == 'bar doc'
#     Foo.metadata.should == 'Foo meta'
#     Bar.metadata.should == 'Bar meta'
#     Bar.doc.should == 'Bar doc'

#     proc { @foo.meta.doc = 1 }.should raise_error(NoMethodError)
  end
end

