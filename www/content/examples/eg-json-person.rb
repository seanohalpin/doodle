#:requires
require 'rubygems'
require 'doodle'
require 'doodle/json'
#:definitions
class Name < Doodle
  has :value, :kind => String
end
class Age < Doodle
  has :value, :kind => Integer
end
class Person < Doodle
  has Name
  has Age
end
