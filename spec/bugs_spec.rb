require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'parents' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle::Base
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
      class Foo < Doodle::Base
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
      class Foo < Doodle::Base
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