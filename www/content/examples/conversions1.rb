#: requires
require 'rubygems'
require 'doodle'
#: definition
class Event < Doodle
  has :start_date, :kind => Date do
    from String do |value|
      Date.parse(value)
    end
  end
  has :end_date, :kind => Date  do
    from String do |value|
      Date.parse(value)
    end
  end
end
#: use
event = Event '2008-03-05', '2008-03-06'
event                           # =>
event.start_date.to_s           # => "2008-03-05"
event.end_date.to_s             # => "2008-03-06"
event.start_date = '2001-01-01'
event.start_date                # => #<Date: 4903821/2,0,2299161>
event.start_date.to_s           # => "2001-01-01"
