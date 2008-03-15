require 'rubygems'
require 'date'
require 'doodle'
require "yaml"
require "pp"

class Location < Doodle::Base
  has :name, :kind => String
  has :events, :init => [], :collect => :Event
end

class Event
  # or if you want to inherit from another class
  include Doodle::Helper
  include Doodle::Factory

  has :name, :kind => String
  has :date do
    kind Date
    default { Date.today }
    must 'be >= today' do |value|
      value >= Date.today
    end
    from String do |s|
      Date.parse(s)
    end
  end
  has :locations, :init => [], :collect => {:place => "Location"}
end  

event = Event "Festival" do
  date '2008-04-01'
  place "The muddy field"
  place "Beer tent" do
    event "Drinking"
  end
end

str = event.to_yaml
puts str
loaded_event = YAML::load(str)
pp loaded_event

another_event = YAML::load(DATA.read)
another_event.validate!(true)

__END__
--- !ruby/object:Event 
date: 2000-04-01
locations: 
- !ruby/object:Location 
  events: []

  name: The muddy field
- !ruby/object:Location 
  events: 
  - !ruby/object:Event 
    locations: []

    name: Drinking
  name: Beer tent
name: Festival
