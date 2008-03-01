require 'doodle'

class Foo < Doodle::Base
  has :baz
end

begin
  foo = Foo.new
  p foo.baz
rescue => e
  p [e]
end

