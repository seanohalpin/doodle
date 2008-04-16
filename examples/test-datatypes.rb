$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'datatypes'

class DateRange < Doodle::Base
  doodle do
    date :start
    date :end do
      default { start + 1 }
    end
    version :version, :default => "0.0.1"
  end
end

#pp DateRange.instance_methods(false)

class Person < Doodle::Base
  doodle do
    #    string :name, :max => 10
    name :name, :size => 3..10
    integer :age
    email :email, :default => ''
  end
end

def try(&block)
  begin
    block.call
  rescue Exception => e
    e
  end
end

require 'pp'

pp try { DateRange "2007-01-18", :version => [0,0,9] }
pp try { Person 'Sean', '45', 'someone@example.com' }
pp try { Person 'Sean', '45' }
pp try { Person 'Sean', 'old' }
pp try { Person 'Sean', 45, 'this is not an email address' }
pp try { Person 'This name is too long', 45 }
pp try { Person 'Sean', 45, 42 }
pp try { Person 'A', 45 }
pp try { Person '123', 45 }
pp try { Person '', 45 }
#   pp try {
#     person = Person 'Sean', 45
#     person.name.silly
#   }
