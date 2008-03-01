$:.unshift(File.join(File.dirname(__FILE__), '../.'))
require 'lib/spec_helper'

describe Doodle, 'class attributes' do
  after :each do
    undefine_const(:Bar)
    undefine_const(:Foo)
  end
  before(:each) do
    raise_if_defined(:Foo, :Bar)
    class Foo
      include Doodle::Helper
      class << self
        has :metadata
      end
    end
    @foo = Foo.new
    class Bar < Foo
      include Doodle::Helper
      class << self
        has :doc
      end
    end
    @foo = Foo.new
    @bar = Bar.new
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

  it 'should create Bar class attribute' do
    Bar.metadata = 'Bar metadata'
    Bar.metadata.should == 'Bar metadata'
  end

  it 'should access class attribute via self.class' do
    @bar.class.metadata = '@bar metadata'
    @bar.class.metadata.should == '@bar metadata'
    Bar.metadata.should == '@bar metadata'

    Bar.metadata = 'Bar metadata'
    Bar.metadata.should == 'Bar metadata'
    @bar.class.metadata.should == 'Bar metadata'
  end

  it 'should not allow inherited class attributes to interfere with each other' do
    Foo.metadata = 'Foo metadata'
    @bar.class.metadata = '@bar metadata'
    @bar.class.metadata.should == '@bar metadata'
    Bar.metadata.should == '@bar metadata'

    Bar.metadata = 'Bar metadata'
    Bar.metadata.should == 'Bar metadata'
    @bar.class.metadata.should == 'Bar metadata'

    Foo.metadata.should == 'Foo metadata'
    @foo.class.metadata.should == 'Foo metadata'
  end
  
  it "should list all class's own attributes" do
    Bar.meta.attributes(false).keys.should == [:doc]
  end
  
  it "should list all class's own attributes" do
    Bar.meta.attributes.keys.should == [:metadata, :doc]
  end

end

raise_if_defined(:Foo, :Bar)
