$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'doodle'
require 'pp'
require 'yaml'

def try(&block)
  begin
    block.call
  rescue Exception => e
    e
  end
end

class Foo < Doodle::Base
  has :name, :kind => String
end

params = {
  :name => 1
}

# rv = try {
#   foo = Foo(params)
# }
# pp rv

rv = try {
  Doodle.raise_exception_on_error = false
  foo = Foo(params)
  foo.errors
}
pp rv
