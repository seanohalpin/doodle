require 'lib/doodle'
require 'date'

class Base < Doodle::Base
end
module ModBase
  include Doodle::Helper
end

class Contribution < Base
  has :contributed_to
  has :contributed_by
  has :contribution_type, :default => 'performer'
end

class Contributor < Base
  has :name
end

class Duration < Base
  has :hours, :default => 0
  has :minutes, :default => 0
  has :seconds, :default => 0
  from String do |s|
    if s =~ /^(?:(\d{2}):)?(\d{2}):(\d{2})$/
      p [:rule1, $1, $2, $3]
      new(:hours => $1.to_i, :minutes => $2.to_i, :seconds => $3.to_i)
    elsif s =~ /^(\d+)'\s*(\d+)"$/
      p [:rule2, $1, $2]
      new(:minutes => $1.to_i, :seconds => $2.to_i)
    end
  end
  def to_s
    %[#{minutes}' #{seconds}"] #'
  end
end

# start_time
# composer
# title
# contribution(s)
# label 
# tracks

class ClassicalSegment < Base
  has :start_time, :kind => DateTime
  has :composer, :kind => String
  has :title, :kind => String
  has :contributions, :kind => Array do
    default { [] }
  end
  has :label, :kind => String
  has :tracks, :kind => String
end

class Date
  include Doodle::Helper
  from String do |s|
    Date.parse(s)
  end
end
class DateTime
  include Doodle::Helper
  from String do |s|
    DateTime.parse(s)
  end
end

# cs = ClassicalSegment.new do
#   title "5th Symphony"
#   duration Duration.from(%[2' 30"]) #'
#   start_time DateTime.from("2007-01-01T12:00")
# end

# require 'pp'
# pp cs
# # pp cs.duration
# puts cs.duration
require 'pp'
records = DATA.read.split(/\n\n+/).map{ |x| x.split(/\n/) }.reject{ |x| x.size == 0}
schema = records.shift.map{ |x| x.strip }

# = Canonical Schema
#
# the canonical schema shows the fields we allow in the order we want them
#
# - we know that we are not necessarily going to get all entries or
#   entries in this order (for example, we might not get duration,
#   and/or we might get title before composer) so we need to match up
#   our canonical list with what has been entered
#
# - we need to handle missing fields
#
# - we need to handle fields out of order
#
# - we need to handle repeated performer fields
#
CANONICAL_SCHEMA = %w[
time
title
composer
performer
label 
tracks
duration
].map{ |x| x.strip }

schema_order = Hash[*CANONICAL_SCHEMA.map{ |x| [schema.index(x), x]}.flatten]

pp [:schema, schema, schema_order]
#pp [:records, records]

module Enumerable
  def map_with_index(&block)
    i = -1
    map { |x|
      i += 1
      yield(x, i)
    }
  end
end

sort_order = Hash[*CANONICAL_SCHEMA.map{ |x| [x, schema.index(x)]}.flatten]
pp sort_order
exit

annotated_records = records.map { |record|
  record.map_with_index { |x, i|
    [schema_order[i], x]
  }
}
pp annotated_records

__END__


time
composer
title
performer
label 
tracks


07.03
BACH
Prelude and Fugue in G major BWV541
Christopher Herrick, organ
Hyperion CDD22062 CD 1 
track 10

07.11
GLAZUNOV
The Seasons: Autumn
Minnesota Orchestra
Edo de Waart, conductor
Telarc CD-80347 
Track 4

07.24
TELEMANN
Quartet in E minor
Musica Antiqua Koln
Reinhard Goebbel, conductor
Archiv 4472962 
tracks 17-20

