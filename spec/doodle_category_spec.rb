require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle::Utils, 'doodle_category' do
  categories =
    [
     [nil, :nil],
     [Class, :class],
     [Object, :class],
     [Module, :class],
     [Object.new, :instance],
     [class << Object; self; end, :singleton_class],
     [class << Object.new; self; end, :singleton_class],
    ]
  categories.each do |thing, category|
    it "should categorize #{thing.inspect} as #{category.inspect}" do
      Doodle::Utils.doodle_category(thing).should == category
    end
  end

end
