#: requires
require "doodle"
require "yaml"
#: all
class Foo < Doodle
  has :name
  has :date
end
str = %[
--- !ruby/object:Foo
date: 2000-07-01
]
# load from string
foo = YAML::load(str).validate!
