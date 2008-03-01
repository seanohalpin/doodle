$:.unshift(File.join(File.dirname(__FILE__), '../.'))

require 'lib/spec_helper'
require 'date'

describe Doodle, 'defaults which have not been set' do
  after :each do
    undefine_const(:Foo)
  end
  before :each do
    raise_if_defined :Foo

    class Foo < Doodle::Base
      has :baz
      has :start do
        default { Date.today }
      end
    end
  end

  it 'should have raise error if required value not set' do
    proc { Foo.new }.should raise_error(ArgumentError)
  end
end

