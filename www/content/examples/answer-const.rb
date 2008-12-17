require 'rubygems'
require 'doodle'

class Life < Doodle
  ANSWER = 42
  has :answer do
    must "be #{ANSWER}" do |value|
      value == ANSWER
    end
    from String do |s|
      s.to_i
    end
  end
end

b = Life(:answer => "42")       # =>
c = Life(41)                    # =>

