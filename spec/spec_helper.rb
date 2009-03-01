begin
  require 'spec'
rescue LoadError
  require 'rubygems'
  gem 'rspec'
  require 'spec'
end

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'doodle'
require 'date'

class Object
  # try to get rid of those annoying warnings about useless ==
  def should_be(other)
    should == other
  end
  def should_not_be(other)
    should_not == other
  end
end

# functions to help clean up namespace after defining classes
def undefine_const(*consts)
  consts.each do |const|
    if Object.const_defined?(const)
      Object.send(:remove_const, const)
    end
  end
end

def raise_if_defined(*args)
  defined = args.select{ |x| Object.const_defined?(x)}
  raise "Namespace pollution: #{defined.join(', ')}" if defined.size > 0
end

def temporary_constants(*args, &block)
  before :each do
    raise_if_defined(*args)
  end
  after :each do
    undefine_const(*args)
  end
  raise_if_defined(*args)
  yield
  raise_if_defined(*args)
end
alias :temporary_constant :temporary_constants

def remove_ivars(*args)
  args.each do |ivar|
    remove_instance_variable "@#{ivar}"
  end
end

def no_error(&block)
  proc(&block).should_not raise_error
end
