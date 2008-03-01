# Sean is a Person
require 'lib/doodle'

class Thing < Doodle::Base
  has :name
end

def a(*args)
  args.first
end
def is(*args)
  args.first
end

def make_class(name, *args, &block)
  klass = Object.const_set(name, Class.new)
  klass.send(:include, Doodle::Helper)
  klass.class_eval(&block) if block_given?
  klass
end

def Object.const_missing(const)
  p [:const_missing, const]
  make_class const
end

def method_missing(method, *args, &block)
  p [:method_missing, method, args, block]
  if method.to_s =~ /^[A-Z]/
    make_class(method, *args, &block)
  else
    super
  end
end

Sean is a Person
p Sean
