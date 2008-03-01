top_level = 'doodle'
require 'scripts/rtd'
stats = RubyToDot.new
stats.hide_current_state    # ignore all loaded classes+modules
require top_level           # load new classes

class Foo < Doodle::Root
end

open("|dot -Tsvg >scratch/#{top_level}.svg", 'wb') do |f|
  f.puts stats.generate     # generate dot output
end
