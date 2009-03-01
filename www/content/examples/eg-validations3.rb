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
  has :end_date, :kind => Date do
    default { start_date }
  end

  must "have end_date >= start_date" do
    end_date >= start_date
  end
end

event = Event :start_date => Date.today
event.end_date = Date.parse('2001-01-01')
