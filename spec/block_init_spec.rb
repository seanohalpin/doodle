require File.dirname(__FILE__) + '/spec_helper.rb'
require 'yaml'

describe 'Doodle', 'block initialization of scalar attributes' do
  temporary_constant :Foo, :Bar, :Farm, :Barn, :Animal do
    before :each do
      class Animal < Doodle
        has :species
      end
      class Barn < Doodle
        has :animals, :collect => Animal
      end
      class Farm < Doodle
        has Barn
      end
      class Foo < Doodle
        has :ivar1, :kind => String
      end
      class Bar < Doodle
        has :block, :kind => Proc
      end
    end
    
    it 'should initialize an scalar attribute from a block' do
      farm = Farm do
        barn do
          animal "pig"
        end
      end
      farm.barn.animals[0].species.should == "pig"
    end
    it 'should fail trying to initialize an inappropriate attribute (not a Doodle or Proc) from a block' do
      proc { 
        foo = Foo do
          ivar1 do
            "hello"
          end
        end
      }.should raise_error(ArgumentError)
    end
    it 'should initialize a Proc attribute from a block' do
      bar = Bar do
        block do
          "hello"
        end
      end
      bar.block.class.should == Proc
      bar.block.call.should == "hello"
    end
  end
end

