require 'lib/spec_helper'

describe 'Doodle', 'singleton superclass == self' do
  after :each do
    undefine_const(:Foo)
  end
  before :each do
    raise_if_defined :Foo

    class Foo < Doodle::Base
    end
    @foo = Foo.new
    @sc = class << @foo; self; end
    @scc = class << @sc; self; end
    @sclass_doodle_root = class << Doodle::Base; self; end
    @sclass_foo = class << @foo; class << self; self; end; end
  end
  
  it 'should have singleton class superclass == self' do
    @sc.parents.should == [@sclass_foo, @sclass_doodle_root]
  end

  it 'should have singleton class superclass == self' do
    @scc.parents.should == []
  end
end

