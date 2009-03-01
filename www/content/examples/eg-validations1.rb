#: requires
require 'rubygems'
require 'doodle'
#: definitions
class Event < Doodle
  has Date
end
#: use
event = Event.new(:date => "Hello")
#: output
