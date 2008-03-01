require 'lib/doodle'

class KeyValue < Doodle::Base
  has :value
  has :name
  def to_s
    %[--#{name}="#{value}"]
  end
end

#ENV['DEBUG_DOODLE'] = "1"
class Text < KeyValue
  has :name, :default => "text"
end

#puts "inherited"
#pp Text.collect_inherited(:attributes)

#puts "Local"
#Text.attributes(false).each do |name, attribute|
#  pp [name, attribute]
#end
# puts "All"
# Text.attributes.each do |name, attribute|
#  pp [name, attribute]
# end
# pp Text.attributes[:name].default_defined?

text = Text.new(:value => 'Enter name:')
#p text
puts text.to_s
#puts text.name
