require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe 'Doodle', 'block initialization of scalar attributes' do
  temporary_constant :Foo, :Bar, :Farm, :Barn, :Animal do
    before :each do
      class ::Animal < Doodle
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
      farm = Farm.new do
        barn do
          animal "pig"
        end
      end
      farm.barn.animals[0].species.should_be "pig"
    end
    it 'should fail trying to initialize an inappropriate attribute (not a Doodle or Proc) from a block' do
      proc {
        foo = Foo.new do
          ivar1 { "hello" }
        end
      }.should raise_error(ArgumentError)
    end
    it 'should initialize a Proc attribute from a block' do
      bar = Bar.new do
        block do
          "hello"
        end
      end
      bar.block.class.should_be Proc
      bar.block.call.should_be "hello"
    end
  end
end

