require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'applying Doodle type conversions' do
  temporary_constant :Foo, :Name do
    before :each do
      class Name < String
        include Doodle::Core
        from String do |s|
          Name.new(s)
        end
        must "be > 3 chars long" do
          size > 3
        end
      end

      class Foo < Doodle
        has Name do
          must "start with A" do |s|
            s =~ /^A/
          end
        end
      end
    end

    it 'should convert a value based on conversions in doodle class' do
      proc { foo = Foo 'Arthur' }.should_not raise_error
    end
    
    it 'should convert a value based on conversions in doodle class to the correct class' do
      foo = Foo 'Arthur'
      foo.name.class.should_be Name
    end

    it 'should apply validations from attribute' do
      proc { Foo 'Zaphod' }.should raise_error(Doodle::ValidationError)
    end

    it 'should apply validations from doodle type' do
      proc { Foo 'Art' }.should raise_error(Doodle::ConversionError)
    end
    
  end
end
