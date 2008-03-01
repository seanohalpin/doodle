#ENV['DEBUG_DOODLE'] = "1"
require 'doodle'
require 'date'

a = Doodle::Attribute.new :name => :fullname do
  default {'hello'}
end
p a
p a.default.call


class DateRange < Doodle::Base 
  has :start_date, :kind => Date do
    default { Date.today }
  end
end

dr = DateRange.new
#p dr.start_date.call
p dr.start_date
# a = Doodle::Attribute.new do
#   name { :fullname }
  
# end
# p a
