require File.dirname(__FILE__) + "/spec_helper.rb"

describe Doodle, "singletons" do
  temporary_constant :Foo do    
    it "should allow creating attributes on classes via inheritance" do
      class Foo < Doodle
        class << self
          has :c1
        end
      end
      Foo.attributes.should == OrderedHash.new
      Foo.singleton_class.attributes.should_not == OrderedHash.new
      Foo.singleton_class.attributes.map{ |name, attr| name }.should == [:c1]
      Foo.c1 = 1
      Foo.c1.should == 1
    end

    it "should allow creating attributes on classes via module inclusion" do
      class Foo
        include Doodle::Core
        class << self
          has :c2
        end
      end
      Foo.attributes.should == OrderedHash.new
      Foo.singleton_class.attributes.should_not == OrderedHash.new
      Foo.singleton_class.attributes.map{ |name, attr| name }.should == [:c2]
      Foo.c2 = 1
      Foo.c2.should == 1
    end

    it "should allow creating attributes on singletons via inheritance" do
      class Foo < Doodle
      end
      foo = Foo.new
      class << foo
        has :i1
      end
      foo.attributes.should == OrderedHash.new
      foo.singleton_class.attributes.should_not == OrderedHash.new
      foo.singleton_class.attributes.map{ |name, attr| name }.should == [:i1]
      foo.i1 = 1
      foo.i1.should == 1
    end

    it "should allow creating attributes on a singleton's singleton via module inclusion" do
      class Foo
        include Doodle::Core
      end
      foo = Foo.new
      class << foo
        class << self
          has :i2
        end
      end
      foo.attributes.should == OrderedHash.new
      foo.singleton_class.singleton_class.attributes.should_not == OrderedHash.new
      foo.singleton_class.singleton_class.attributes.map{ |name, attr| name }.should == [:i2]
      foo.singleton_class.i2 = 1
      foo.singleton_class.i2.should == 1
    end
  end
end
