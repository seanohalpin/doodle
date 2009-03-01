#: requires
require 'rubygems'
require 'doodle'
#: all
class Event < Doodle
  has :start_date, :kind => Date do
    must "be >= today" do |value|
      value >= Date.today
    end
  end
end

event = Event :start_date => Date.today
event.start_date = Date.parse('2001-01-01')
