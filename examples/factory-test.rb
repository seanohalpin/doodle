require 'constant'
require 'mixable'

module Scribble
  module Factory
    def factory(name = self)
      name = self.to_s
      names = name.split(/::/)
      name = names.pop
      if names.empty?
        # top level class - should be available to all
        mklass = klass = Object
        #p [:names_empty, klass, mklass]
        eval src = "def #{ name }(*args, &block); ::#{name}.new(*args, &block); end", ::TOPLEVEL_BINDING
      else
        klass = names.inject(self) {|c, n| c.const_get(n)}
        mklass = class << klass; self; end
        #p [:names, klass, mklass]
        #eval src = "def #{ names.join('::') }::#{name}(*args, &block); #{ names.join('::') }::#{name}.new(*args, &block); end"
        klass.class_eval src = "def self.#{name}(*args, &block); #{name}.new(*args, &block); end"
        #p [:factory, mklass, klass, src]
      end
    end
    def self.included(other)
      raise Exception, "#{self} can only be included in a Class" if !other.kind_of? Class
      super
      other.extend self
      other.module_eval {
        factory
        def self.inherited(other_klass)
          super
          other_klass.module_eval { include Factory }
        end
      }
    end
  end
  module Moo
    # if you want to
    def self.included(other)
      other.send(:include, Factory)
    end
  end
  class Base
    include Moo
    def initialize(*args, &block)
      p [Module.nesting, self.class, args, block]
      instance_eval(&block) if block_given?
    end
  end
  class Foo < Base
  end
  class Bar < Foo
  end
end
# p Scribble.methods.sort

foo = Scribble.Foo 1,2,3 do
  p "Hello"
end

bar = Scribble::Bar 1,2,3 do
  p "Hi"
end
p bar

class Too < Scribble::Base
  #  def self.inherited(other)
  #    other.module_eval { include Factory }
  #  end
end

class Moo < Too
end

bar = Moo 1,2,3 do
  p "Ho"
end
p bar

module Bar
  Moo 4,5,6 do
    p [Module.nesting, self, self.class, "Moo"]
  end
end

class C0
  def initialize(*args, &block)
    p [args, block]
    p [:C0, :initialize, self, self.class]
    instance_eval(&block) if block_given?
  end
end
module M1
  module M2
    class C1 < C0
      class C2 < C1
        Moo "XXXXX" do
          p [Module.nesting, self, self.class, "ZZZ"]
        end
      end
      class C3 < Scribble::Base
      end
    end
  end
end

module M1::M2
  def self.C1(*args, &block)
    C1.new(*args, &block)
  end
  class C1
    def self.C2(*args, &block)
      C2.new(*args, &block)
    end
  end
end

# def M1::M2.C1(*args, &block)
#   M1::M2::C1.new(*args, &block)
# end
M1::M2::C1(1,2,3) { p [:C1, self] }
M1::M2::C1::C2(1,2,3) { p [:C2, self] }
M1::M2::C1::C3(1,2,3) { p [:C3, self] }

include M1::M2
C1::C3(1,2,3) { p [:C3, self] }
class C1
  C3(1,2,3) { p [:C3, self] }
end
