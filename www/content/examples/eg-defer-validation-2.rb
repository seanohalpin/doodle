#: requires
require 'rubygems'
require 'doodle'
require 'event'
#: use
event = Event.new
event.doodle.defer_validation do |event|
  event.end_date = Date.parse('2009-01-01')
  event.start_date = Date.parse('2008-01-01')
end
