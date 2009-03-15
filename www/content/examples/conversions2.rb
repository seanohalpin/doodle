#: requires

require 'doodle'
#: d1
class Event < Doodle
#: xxx
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
#: class_from
  # ...
  from String do |value|
    args = value.split(' to ')
    new(*args)
  end
#: d2
end
#: use
event = Event.from '2008-03-05 to 2008-03-06'
event.start_date.to_s   # => "2008-03-05"
event.end_date.to_s     # => "2008-03-06"
