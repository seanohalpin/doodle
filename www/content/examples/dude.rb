#: require
require 'doodle'
#: definition
class Dude < Doodle
  # the attribute has an ~attribute~ validation, i.e. it must be a
  # String
  has :name, :kind => String
  has :cool, :default => false
  # whereas this is an ~object~ level validation
  must "be cool if name contains 'Dude'" do
    !(name =~ /Dude/ && !cool)
  end
  must "not be cool if name does not contains 'Dude'" do
    !(cool && name !~ /Dude/)
  end
end

