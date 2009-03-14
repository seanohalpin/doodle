require 'doodle'
#:definition
class Person < Doodle
  has :name, :kind => String
  has :age, :kind => Integer
end
#:use
person = Person :name => "Corum", :age => 999

#:keys
Person.doodle.keys       # =>
person.doodle.keys       # =>
#:values
person.doodle.values     # =>
#:key_values
person.doodle.key_values # =>
