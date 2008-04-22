require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'class attributes' do
  temporary_constants :Bar, :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        class << self
          has :metadata
        end
      end
      @foo = Foo.new
      class Bar < Foo
        include Doodle::Core
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

    it 'should access @foo class attribute via self.class' do
      @foo.class.metadata = '@foo metadata'
      @foo.class.metadata.should == '@foo metadata'
      Foo.metadata.should == '@foo metadata'

      Foo.metadata = 'Foo metadata'
      Foo.metadata.should == 'Foo metadata'
      @foo.class.metadata.should == 'Foo metadata'
    end

    it "should list all class's own attributes" do
      Foo.singleton_class.attributes(false).keys.should == [:metadata]
    end
  
    it "should list all class's own attributes" do
      Foo.singleton_class.attributes.keys.should == [:metadata]
    end

    it 'should create Bar class attribute' do
      Bar.metadata = 'Bar metadata'
      Bar.metadata.should == 'Bar metadata'
    end

    it 'should access @bar class attribute via self.class' do
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
      Bar.singleton_class.attributes(false).keys.should == [:doc]
    end
  
    it "should list all class's singleton attributes" do
      Bar.singleton_class.attributes.keys.should == [:doc]
    end
    it "should list all class's class_attributes" do
      Bar.class_attributes.keys.should == [:metadata, :doc]
    end
  end
end
