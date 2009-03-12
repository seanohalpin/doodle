#: requires
require 'doodle'
require 'dude'

#: use
dude = Dude("Dude", true)

#: eg1-comment
# using object.doodle.update, you can temporarily set attributes to
# values which would invalidate the object
#: eg1
dude.doodle.update do
  name "Bozo"
  name "The Dude"
end
dude # =>

dude.doodle.update do
  cool false
  name "Bozo"
end
dude # =>

#: eg2-comment
# values set in the block will override values set in argument list
#: eg2
dude.doodle.update :cool => false do
  cool true
  name "The Dude"
end
dude # =>

#: eg3-comment
# but you can't escape individual attribute validations
#: eg3
res = Doodle::Utils.try {
  dude.doodle.update do
    name 123
    name "Dude"
  end
}
res  # =>
# the attribute is still valid, even after capturing the exception
dude # =>

#: eg4-comment
# update will not prevent you invalidating the ~object~ if you capture
# the exception
#: eg4
res = Doodle::Utils.try {
  dude.doodle.update do
    name "Jeff"
  end
}
res  # =>
dude # =>

