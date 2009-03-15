#: requires

require 'date'
require 'pp'
require 'doodle'

#: definition
class Location < Doodle
  has :name, :kind => String
  has :events, :collect => :Event
end

class Event
  # or if you want to inherit from another class
  include Doodle::Core
  BASEDATE = Date.civil(2009, 01, 01)

  has :name, :kind => String
  has Date do
    default { Date.today }
    must "be >= #{BASEDATE}" do |value|
      value >= BASEDATE
    end
    from String do |s|
      Date.parse(s)
    end
  end
  has :locations, :collect => { :place => :Location }
end

#: use
event = Event "Festival" do
  date '2009-04-01'
  place "The muddy field"
  place "Beer tent" do
    event "Drinking"
  end
end

#: output
pp event
# >> #<Event:0x111dd4c
# >>  @date=#<Date: 4909115/2,0,2299161>,
# >>  @locations=
# >>   [#<Location:0x1117be0 @events=[], @name="The muddy field">,
# >>    #<Location:0x1114148
# >>     @events=[#<Event:0x11115b0 @locations=[], @name="Drinking">],
# >>     @name="Beer tent">],
# >>  @name="Festival">
