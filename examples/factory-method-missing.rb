module SpumCo
  class Ren
    def initialize(*args, &block)
      p [args, block]
    end
  end
end

class Stimpy
  def initialize(*args, &block)
    p [args, block]
  end
end

class Horse
  def initialize(*args, &block)
    p [args, block]
  end
end

class Object
  def method_missing(method, *args, &block)
    p [:method_missing, method, self]
    klass = self.kind_of?(Module) ? self : self.class
    klass_name = self.kind_of?(Module) ? self.to_s  : ""
    if klass_name != ""
      dot = '.'
    else
      dot = ''
    end
    p [:method_missing, method, klass, self]
    
    if klass.const_defined?(method)
      if m = klass.const_get(method)
        src = "def #{ klass_name }#{ dot }#{method}(*args, &block); #{ klass_name }::#{method}.new(*args, &block); end"
        p [:module_eval, src, klass]
        #klass.module_eval src
        eval src
        m.new(*args, &block)
      else
        super
      end
    else
      super
    end
  end
end

meths = methods
meths2 = SpumCo.methods

SpumCo::Ren('Hi')
Stimpy('Eediot!')
SpumCo::Ren('Hello again')
Stimpy('Ho!')

puts "METHODS"
puts methods - meths

puts "METHODS"
puts SpumCo.methods - meths2

stimpy = Stimpy('Hello')
p stimpy
begin
  stimpy.instance_eval {
    p Horse('Another')
  }
rescue => e
  p e
end
