require File.dirname(__FILE__) + '/spec_helper.rb'

describe 'Doodle', 'parents' do
  temporary_constant :Foo do
    before :each do
      class Foo < Doodle
      end
      @foo = Foo.new
      @sc = class << @foo; self; end
      @scc = class << @sc; self; end
      @sclass_doodle_root = class << Doodle; self; end
      @sclass_foo = class << @foo; class << self; self; end; end
    end
  
    it 'should have no singleton parents ' do
      @sc.parents.should == []
    end

    it "should have singleton class's singleton class parents == []" do
      expected_parents = RUBY_VERSION <= "1.8.6" ? [] : [Module, Object, BasicObject]
      @scc.parents.should == expected_parents
    end
  end
end

