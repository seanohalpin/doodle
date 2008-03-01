require 'lib/doodle'

module Enumerable
  def to_doodle
    '[' + map{ |x| x.to_doodle }.join(', ') + ']'
  end
end

module Doodle::BaseMethods
  def qq(txt)
    %["#{txt.gsub(/\"/, '\\\\"')}"] #'
  end

  def q(txt)
    %['#{txt.gsub(/\'/, "\\\\'")}'] #"
  end

  # display object in canonical form
  def to_doodle
    #p [self.to_s, :to_doodle, arg_order]
    attrs = arg_order.map{ |attr|
      v = send(attr)
      #p [:to_doodle, attr, v]
      ":#{attr} => #{v.respond_to?(:to_doodle) ? v.to_doodle : q(v.to_s) }"
    }
    "#{self.class}(#{attrs.join(', ')})"
  end
end

class GBase < Doodle::Base
end

class Node < GBase
end

class Edge < GBase
  has :source, :kind => Node
  has :label
  has :target, :kind => Node
  def inspect
    "#{source.name} #{label} #{target.name}"
  end
end

class Node < GBase
  has :name
  has :connections do
    default { [] }
  end
  meta do
    # connect A => B => C
    def connect(a, b)
      a.connections << Edge(a, 'is connected to', b)
      b.connections << Edge(b, 'is connected from', a)
    end
  end
end

n1 = Node("a")
n2 = Node("b")
n3 = Node("c")
Node.connect(n1, n2)
Node.connect(n2, n3)
Node.connect(n3, n1)
p n1
puts
puts
p n1.connections
p n2.connections
p n3.connections

