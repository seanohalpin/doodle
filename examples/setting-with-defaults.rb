require 'lib/doodle'
require 'date'

module AttributeDate
  def date(*a, &b)
#    if a.size > 0
      name = a.shift
#    else
#      name = :date
#    end
    td = has(name, :kind => Date, *a) do
      # it is a bit clumsy to define these conversions &
      # conditions for every attribute/typedef could define a
      # subclass of Typedef which does this by default (so we
      # instances can override or defer to class level
      # conversions and conditions)
      from String do |s|
        Date.parse(s)
      end
      from Array do |y,m,d|
        #p [:from, Array, y, m, d]
        Date.new(y, m, d)
      end
      from Integer do |jd|
        d { [:converting_from, Integer, jd] }
        Date.new(*Date.jd_to_civil(jd))
      end
    end
    d { [:date, td] }
    td.instance_eval(&b) if block_given? # user's block should override default
  end
end

class Base < Doodle::Base
  extend AttributeDate
end

class DateRange < Base
  date :start_date do
    d { [:start_date, self, self.class] }
    default { Date.today }
  end
  date :end_date do
    default { start_date }
  end
  must "have end_date >= start_date" do
    end_date >= start_date
  end
end

dr = DateRange.new
dr.start_date = dr.start_date + 1
#dr.end_date = dr.start_date + 1
