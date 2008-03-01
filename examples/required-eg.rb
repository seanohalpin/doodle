#ENV['DEBUG_DOODLE'] = "1"
require 'doodle'
class Goo
  include Doodle::Helper
  has :name, :default => 'Hello'
end

p Goo
p Goo.attributes[:name]

goo = Goo.new
p goo.name
p goo.attributes[:name].required?
p goo

#a = Doodle::Attribute.new :fullname, 'hello'
#a = Doodle::Attribute.new :name => :fullname, :default => 'hello'
#a = Doodle::Attribute.new :fullname, :default => 'hello'
#a = Doodle::Attribute.new :fullname, :default => 'hello'
#p a
