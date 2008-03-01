#require 'constant'
#require 'mixable'

require 'doodle'

module Scribble
  class Base < Doodle::Base
    def initialize(*args, &block)
      p [Scribble, Module.nesting, self.class, args, block]
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

class C0 < Doodle::Base
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
