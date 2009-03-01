#: requires
# $:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'doodle'
#: require_xml
require 'doodle/xml'
#: require_other
require 'pp'

# example document stolen from http://xml-mapping.rubyforge.org/
# (in turn stolen from http://www.castor.org/xml-mapping.html)

#: definition
module Orders
  class Base < Doodle
    include Doodle::XML
  end
  class TextValue < Base
    has :value
    def format_for_xml(s)
      s
    end
    # override to_xml (otherwise appears as <TextValue value="value" />)
    def to_xml
      format_tag(tag, { }, format_for_xml(value))
    end
  end
  class FloatValue < TextValue
    has :value do
      from String do |s|
        Float(s)
      end
    end
    def format_for_xml(value)
      "%02.02f" % value
    end
  end
  class IntegerValue < TextValue
    has :value do
      from String do |s|
        Integer(s)
      end
    end
  end
  class Name < TextValue
  end
  class City < TextValue
  end
  class State < TextValue
  end
  class ZIP < TextValue
  end
  class Street < TextValue
  end
  class Address < Base
    # note: use init if you want this attribute to appear, even if the user does not set it
    #has :where, :init => "home"
    has :where, :default => "home"
    has City
    has State
    has ZIP
    has Street
  end
  class Client < Base
    has Name
    has :addresses, :collect => Address
  end
  class Description < TextValue
  end
  class Quantity < IntegerValue
  end
  class UnitPrice < FloatValue
  end
  class Item < Base
    has :reference, :kind => String do
      must "be of form RF-nnnn" do |v|
        v =~ /^RF-\d{4}$/
      end
    end
    has Description
    has Quantity
    has UnitPrice
  end
  class Position < TextValue
  end
  class Signature < Base
    has Name
    has Position, :default => nil
  end
  class SignedBy  < Base
    has :signatures, :collect => Signature
    # override ~output~ tag
    # (input tag is converted to 'SignedBy')
    def tag
      "Signed-By"
    end
  end
  class Order < Base
    has :reference
    has Client
    has :items, :collect => Item
    has SignedBy
  end
end
#:enddef
base_dir = Dir.pwd

if __FILE__ == $0
  src = File.read(File.join(base_dir, "content", "examples", "castor-xml-example.xml"))
#: use
  order = Doodle::XML.from_xml(Orders, src)
  puts order.pretty_inspect
#:end
end
#:output
