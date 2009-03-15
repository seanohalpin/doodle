#: requires

require 'doodle'

#: definition
class Text < Doodle
  has :body, :init => "", :collect => :text
  def newline
    text "\n"
  end
  def to_s
    body
  end
end

#: use
output = Text do
  text "line 1"
  newline
  text "line 2"
  text " this will be concatenated"
end
puts output

