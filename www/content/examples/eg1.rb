
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

a = Life.new(:answer => "42")   # => #<Life:0x10aba6c @answer=42>
a = Life.new(42)                # => #<Life:0x10aba6c @answer=42>
a = Life(42)                    # => #<Life:0x10aba6c @answer=42>
# the next line will cause an exception
b = Life(41)
