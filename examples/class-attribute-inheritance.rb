require 'doodle'

class Main < Doodle::Base
  class << self
    has :doc, :default => 'Change me' do
      must "be >= 1 char" do |s|
        s.size >= 1
      end
    end
  end
  has :info
end

#Main.doc                        # =>
#p Main.attributes               # => 
p Main.meta.attributes          # => 
#Main.doc = "Hello"                 # => 
#p Main.doc                 # => 
# class << Main
#   p attributes
#   doc "Hi"
# end
class Foo < Main
  doc "H"
end
