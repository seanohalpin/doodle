$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'date'
require "yaml"
require "pp"

require 'doodle'
require 'doodle/utils'

class Location < Doodle
  has :name, :kind => String
  has :events, :collect => :Event, :key => :name
end

class Event #< Doodle
  # or if you want to inherit from another class
  include Doodle::Core

  has :name, :kind => String
  has :date, :kind => Date do
    default { Date.today }
    from String do |s|
      Date.parse(s)
    end
  end
  has :locations, :collect => {:place => :Location}, :key => :name
end  

event = Event "Festival" do
  date '2018-04-01'
  place "The muddy field"
  place "Beer tent" do
    event "Drinking"
    event "Dancing"
  end
end

yaml = event.to_yaml
puts yaml
# >> --- !ruby/object:Event 
# >> date: 2018-04-01
# >> locations: 
# >>   Beer tent: !ruby/object:Location 
# >>     events: 
# >>       Drinking: !ruby/object:Event 
# >>         locations: {}
# >> 
# >>         name: Drinking
# >>       Dancing: !ruby/object:Event 
# >>         locations: {}
# >> 
# >>         name: Dancing
# >>     name: Beer tent
# >>   The muddy field: !ruby/object:Location 
# >>     events: {}
# >> 
# >>     name: The muddy field
# >> name: Festival
event2 = YAML::load(yaml).validate!

# p event.doodle.values == event2.doodle.values
# pp event.doodle.values
# pp event2.doodle.values

# pp event.locations["Beer tent"].events == event2.locations["Beer tent"].events
# pp event.locations["Beer tent"].events["Drinking"] == event2.locations["Beer tent"].events["Drinking"]

e1 = event.locations["Beer tent"].events["Drinking"]
e2 = event2.locations["Beer tent"].events["Drinking"]
# p e1 == e2
# pp e1
# pp e2

# pp e1.doodle.values 
# pp e2.doodle.values
pp e1.doodle.values == e2.doodle.values
# pp e1.class.ancestors
pp e1.eql?(e2)
pp [:event_event2, event == event2]
# pp e2.class.ancestors
# o = Doodle.new
# pp o.class.ancestors
