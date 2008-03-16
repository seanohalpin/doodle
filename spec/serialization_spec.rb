require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe Doodle, "Serialization" do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
        has :var, :kind => Integer
      end
      @foo = Foo 42 
    end
    after :each do
      remove_ivars :foo
    end
    
    it "should be serializable to yaml" do
      @foo.to_yaml.should == "--- !ruby/object:Foo \nvar: 42\n"
    end
    
    it "should be loadable from yaml" do
      src = @foo.to_yaml
      new_foo = YAML::load(src)
      new_foo.var.should == 42
    end
    
    it "should make it possible to validate already set instance variables" do
      new_foo = YAML::load("--- !ruby/object:Foo \nvar: Hello World!\n")
      proc { new_foo.validate!(true) }.should raise_error(Doodle::ValidationError)
    end
    
  end
end
