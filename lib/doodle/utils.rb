# doodle/utils.rb
# - not part of main lib but useful tidbits
# Sean O'Halpin, 2008-04-17
require 'pp'

def try(&block)
  begin
    block.call
  rescue Exception => e
    e
  end
end

