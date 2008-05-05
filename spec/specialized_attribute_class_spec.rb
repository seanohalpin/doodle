require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'specialized attributes' do
  temporary_constant :Foo, :SpecializedAttribute do
    before :each do
      class SpecializedAttribute < Doodle::Attribute
      end
      
      class Foo < Doodle
      end
    end
    
    it 'should allow :using keyword' do
      proc {
        Foo.class_eval do
          has :ivar1, :kind => String, :using => SpecializedAttribute
        end
      }.should_not raise_error
    end

    it 'should interpret :using keyword and return a specialized attribute of correct class' do
      class Foo < Doodle
        rv = has(:ivar1, :kind => String, :using => SpecializedAttribute)
        rv.class.should_be SpecializedAttribute
      end
    end

    it 'should allow additional attributes belonging to specialized attribute of correct class' do
      class SpecializedAttribute
        has :flag, :kind => String
      end
      class Foo < Doodle
        rv = has(:ivar1, :kind => String, :using => SpecializedAttribute, :flag => "sflag")
        rv.class.should_be SpecializedAttribute
        rv.flag.should_be 'sflag'
      end
    end

    it 'should allow additional directives invoking specialized attribute of correct class' do
      class SpecializedAttribute
        has :flag, :kind => String
      end
      class Foo < Doodle
        class << self
          def option(*args, &block)
            # this is how to add extra options onto args array for has
            # - all hashes get merged into one
            args << { :using => SpecializedAttribute }
            has(*args, &block)
          end
        end
        rv = option(:ivar1, :kind => String, :flag => "sflag")
        rv.class.should_be SpecializedAttribute
        rv.flag.should_be 'sflag'
      end
      Foo.attributes[:ivar1].flag.should_be "sflag"
      foo = Foo.new('hi')
      foo.attributes[:ivar1].flag.should_be "sflag"
    end
    
  end
end

