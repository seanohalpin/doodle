require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'instance attributes' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        has :name, :default => nil
      end
      @foo = Foo.new
    end
    after :each do
      remove_ivars :foo
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
end

describe Doodle, 'class attributes(false)' do
  temporary_constant :Foo do
    before(:each) do
      class Foo
        include Doodle::Core
        class << self
          has :metadata
        end
      end
      @foo = Foo.new
    end
    after :each do
      remove_ivars :foo
    end

    it 'should create class attribute' do
      Foo.metadata = 'Foo metadata'
      Foo.metadata.should == 'Foo metadata'
    end

    it 'should access @foo.class attribute via self.class' do
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
  end
end

describe Doodle, 'inherited class attributes(false)' do
  temporary_constant :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
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
    after :each do
      remove_ivars :foo, :bar
    end

    it 'should create inherited class attribute' do
      Foo.metadata = 'Foo metadata'
      Bar.metadata = 'Bar metadata'
      Foo.metadata.should == 'Foo metadata'
      Bar.metadata.should == 'Bar metadata'
      Foo.metadata.should == 'Foo metadata'
    end

    it 'should access @foo.class attribute via self.class' do
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

    it 'should access inherited @foo.class attribute via self.class' do
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
      Foo.singleton_class.attributes(false).keys.should == [:metadata]
    end
  
    it "should list all class's own attributes" do
      Foo.singleton_class.attributes.keys.should == [:metadata]
    end

    it "should list class's own attributes(false)" do
      Bar.singleton_class.attributes(false).keys.should == [:doc]
    end

    it "should list all singleton class attributes" do
      Bar.singleton_class.attributes.keys.should == [:doc]
    end

    it "should list all inherited meta class attributes" do
      Bar.class_attributes.keys.should == [:metadata, :doc]
    end
    
    it "should list all inherited class's attributes" do
      Bar.attributes.keys.should == [:name, :location]
    end
  end
end

describe Doodle, 'singleton class attributes' do
  temporary_constant :Foo do
    before(:each) do
  
      class Foo
        include Doodle::Core
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
    after :each do
      remove_ivars :foo
    end
  
    it 'should allow creation of singleton class attributes' do
      @foo.special = 42
      @foo.special.should == 42
    end

    it 'should list singleton instance attributes(false)' do
      @foo.singleton_class.attributes(false).keys.should == [:special]
    end

    it 'should list singleton instance attributes' do
      @foo.singleton_class.attributes.keys.should == [:special]
    end

    it 'should list instance attributes' do
      @foo.attributes.keys.should == [:name, :special]
    end

  end
end

describe Doodle, 'inherited singleton class attributes' do
  temporary_constant :Foo, :Bar do
    before(:each) do
      class Foo
        include Doodle::Core
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
    
    after :each do
      remove_ivars :foo, :bar, :bar2
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
      @foo.singleton_class.attributes(false).keys.should == [:special]
      @bar.singleton_class.attributes(false).keys.should == [:extra]
    end

    it 'should list singleton attributes only' do
      @foo.singleton_class.attributes.keys.should == [:special]
      @bar.singleton_class.attributes.keys.should == [:extra]
    end
  
    it 'should keep meta attributes separate' do
      @foo.special = 'foo special'
      @foo.special.should == 'foo special'
      @foo.singleton_class.metadata = 'foo meta'
      @foo.singleton_class.metadata.should == 'foo meta'
      # note: you cannot set any other values on @bar until you have set @bar.extra because it's defined as required
      @bar.extra = 'bar extra'
      @bar.extra.should == 'bar extra'
      Foo.metadata = 'Foo meta'
      Foo.metadata.should == 'Foo meta'
      Bar.metadata = 'Bar meta'
      Bar.metadata.should == 'Bar meta'
      Bar.doc = 'Bar doc'
      Bar.doc.should == 'Bar doc'

      # now make sure they haven't bumped each other off
      @foo.special.should == 'foo special'
      @foo.singleton_class.metadata.should == 'foo meta'
      @bar.extra.should == 'bar extra'
      Foo.metadata.should == 'Foo meta'
      Bar.metadata.should == 'Bar meta'
      Bar.doc.should == 'Bar doc'
    end
    
    it 'should behave predictably when setting singleton attributes' do
      @bar.extra = 'bar extra'
      @bar.extra.should == 'bar extra'
      # pending 'working out how to make this work' do
      #   @bar.singleton_class.metadata = 'bar meta metadata'
      #   @bar.singleton_class.metadata.should == 'bar meta metadata'
      #   @bar.singleton_class.doc = 'bar doc'
      #   @bar.singleton_class.doc.should == 'bar doc'
      #   proc { @foo.singleton_class.doc = 1 }.should raise_error(NoMethodError)
      # end
    end
  end
end

