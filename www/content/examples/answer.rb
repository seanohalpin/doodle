require 'rubygems'
require 'doodle'

class Life < Doodle
  has :answer, :kind => Integer, :default => 42 do
    must "be 42" do |value|
      value == 42
    end
    from String do |s|
      s.to_i
    end
  end
end

a = Life.new                    # =>
a.answer                        # =>
b = Life(:answer => "42")       # =>
c = Life(41)                    # =>

__END__

To keep this DRY, it could be rewritten using a constant:

class Life < Doodle
  ANSWER = 42
  has :answer, :kind => Integer, :default => ANSWER do
    must "be #{ANSWER}" do |value|
      value == ANSWER
    end
    from String do |s|
      s.to_i
    end
  end
end

or a closure:

class Life < Doodle
  answer = 42
  has :answer, :kind => Integer, :default => answer do
    must "be #{answer}" do |value|
      value == answer
    end
    from String do |s|
      s.to_i
    end
  end
end
