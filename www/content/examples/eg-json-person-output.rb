require 'eg-json-person'
#:use
person = Person do
  name "Corum"
  age 999
end
puts person.to_json
#:output
