$:.unshift(File.join(File.dirname(__FILE__), '../.'))

require 'doodle'

class Foo < Doodle::Base
  has :hope, :default => 'Ren'
  has :name, :default => 'Stimpy'
end

p Foo.attributes
foo = Foo.new
p foo.hope
p foo.name


ren = Foo.new :name => 'Ren', :hope => 'eternal'
p ren
stimpy = Foo.new 'none', 'Stimpy'
p stimpy
