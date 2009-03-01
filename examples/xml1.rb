# RUBYLIB=lib xmpfilter

require 'doodle'
require 'doodle/xml'

xml_source = %[<Address where="home"><City>London<Country>UK</Country></City></Address>]

class Base < Doodle
  include Doodle::XML
end
class Country < Base
  has :_text_
end
class City < Base
  has :_text_
  has Country, :default => "UK"
end
class Address < Base
  has :where, :default => "home"
  has City
end

a = Address :where => 'home' do
  city "London", :country => "England" do
    country "UK"
  end
end

a                               # => 
a.to_xml == xml_source          # => 
b = Doodle::XML.from_xml(Base, xml_source)
b                               # => 
b == a                          # => 
puts a.to_xml
