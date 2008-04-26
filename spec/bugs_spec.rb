require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'parents' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :var1, :kind => Integer
        has :var2, :kind => Integer, :default => 1
        must 'have var1 != var2' do
          var1 != var2
        end
      end
    end
    
    it 'should not duplicate validations when accessing them!' do
      foo = Foo 2
      foo.validations.size.should == 1
      foo.validations.size.should == 1
    end
  end
end

describe 'Doodle', ' loading good data from yaml' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :date, :kind => Date do
          from String do |s|
            Date.parse(s)
          end
        end
      end      
      @str = %[
      --- !ruby/object:Foo
      date: "2000-7-01"
      ]
      
    end

    it 'should succeed without validation' do
      proc { foo = YAML::load(@str)}.should_not raise_error
    end

    it 'should validate ok' do
      proc { foo = YAML::load(@str).validate! }.should_not raise_error
    end
    
    it 'should apply conversions' do
      foo = YAML::load(@str).validate!
      foo.date.should == Date.new(2000, 7, 1)
      foo.date.class.should == Date
    end
  end
end

describe 'Doodle', ' loading bad data from yaml' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :date, :kind => Date do
          from String do |s|
            Date.parse(s)
          end
        end
      end
      @str = %[
      --- !ruby/object:Foo
      date: "2000"
      ]      
    end

    it 'should succeed without validation' do
      proc { foo = YAML::load(@str)}.should_not raise_error
    end

    it 'should fail with ConversionError when it cannot convert' do
      proc { foo = YAML::load(@str).validate! }.should raise_error(Doodle::ConversionError)
    end
  end
end

describe Doodle, 'class attributes:' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
        has :ivar
        class << self
          has :cvar
        end
      end
    end

    it 'should be possible to set a class var without setting an instance var' do
      proc { Foo.cvar = 42 }.should_not raise_error
    end
  end
end

describe Doodle, 'initializing from hashes and yaml' do
  temporary_constants :AddressLine, :Person do
    before :each do
      class AddressLine < Doodle
        has :text, :kind => String
      end

      class Person < Doodle
        has :name, :kind => String
        has :address, :collect => { :line => AddressLine }
      end
    end

    it 'should validate ouput from to_yaml' do

      yaml = %[
---
:address: 
- Henry Wood House
- London
:name: Sean
]

      person = Person(YAML.load(yaml))
      yaml = person.to_yaml
      # be careful here - Ruby yaml is finicky (spaces after class names)
      yaml.should == %[--- !ruby/object:Person 
address: 
- !ruby/object:AddressLine 
  text: Henry Wood House
- !ruby/object:AddressLine 
  text: London
name: Sean
]
      person = YAML.load(yaml)
      proc { person.validate! }.should_not raise_error
      person.address.all?{ |x| x.kind_of? AddressLine }.should == true

    end
  end
end

describe 'Doodle', 'hiding @__doodle__' do
  temporary_constant :Foo, :Bar, :DString, :DHash, :DArray do
    before :each do
      class Foo < Doodle
        has :var1, :kind => Integer
      end
      class Bar
        include Doodle::Core
        has :var2, :kind => Integer
      end
      class DString < String
        include Doodle::Core
      end
      class DHash < Hash
        include Doodle::Core
      end
      class DArray < Array
        include Doodle::Core
      end
    end
    
    it 'should not reveal @__doodle__ in inspect string' do
      foo = Foo 2
      foo.inspect.should_not =~ /@__doodle__/
    end
    it 'should not include @__doodle__ in instance_variables' do
      foo = Foo 2
      foo.instance_variables.size.should == 1
      foo.instance_variables.first.should =~ /^@var1$/
    end
    it 'should not reveal @__doodle__ in inspect string' do
      foo = Bar 2
      foo.inspect.should_not =~ /@__doodle__/
    end
    it 'should not include @__doodle__ in instance_variables' do
      foo = Bar 2
      foo.instance_variables.size.should == 1
      foo.instance_variables.first.should =~ /^@var2$/
    end
    it 'should correctly inspect when using included module' do
      foo = Bar 2
      foo.inspect.should =~ /#<Bar:0x[a-z0-9]+ @var2=2>/
    end
    it 'should correctly inspect string' do
      foo = DString("Hello")
      foo.inspect.should == '"Hello"'
    end
    it 'should correctly inspect hash' do
      foo = DHash.new(2)
      foo[:a] = 1
      foo.inspect.should == '{:a=>1}'
      foo[:b].should == 2
    end
    it 'should correctly inspect array' do
      foo = DArray(3, 2)
      foo.inspect.should == '[2, 2, 2]'
    end
  end
end
