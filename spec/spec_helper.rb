$:.unshift(File.join(File.dirname(__FILE__), '../lib'))
require 'molic_orderedhash'
require 'doodle'
require 'date'

def undefine_const(*consts)
  consts.each do |const|
    if Object.const_defined?(const)
      Object.send(:remove_const, const)
    end
  end
end

def raise_if_defined(*args)
  defined, undefined = args.partition{ |x| Object.const_defined?(x)}
  raise "Namespace pollution: #{defined.join(', ')}" if defined.size > 0
end

def temporary_constants(*args, &block)
  before :each do
    raise_if_defined *args
  end
  after :each do
    undefine_const *args
  end
  raise_if_defined *args
  yield
  raise_if_defined *args
end
alias :temporary_constant :temporary_constants

def remove_ivars(*args)
  args.each do |ivar|
    remove_instance_variable "@#{ivar}"
  end
end 
