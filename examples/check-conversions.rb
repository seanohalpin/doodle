$:.unshift(File.join(File.dirname(__FILE__), '../.'))

require 'lib/spec_helper'
require 'date'
  
class Foo < Doodle::Base
  has :start do
    default { d = Date.today; p [:default, d]; d }
    from String do |s|
      p [:converting_from, s]
      Date.parse(s)
    end
  end
end

d = Foo.new
p d.start
p d.start == Date.today
