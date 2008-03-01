require 'date'
require 'doodle'
class Base < Doodle::Base
end

class DateRange < Base 
  has :start_date, :kind => Date do
    default { Date.today }
  end
  has :end_date, :kind => Date do
    default { start_date }
  end
end

class Event < Base
  has :date_range, :kind => DateRange do
    default DateRange.new
  end
end

e = Event.new
p e.date_range.start_date       # =>
p e.date_range.end_date         # =>

