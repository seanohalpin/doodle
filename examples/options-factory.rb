require 'lib/doodle'

module CommandLine
  class Base < Doodle::Base
    include Doodle::Factory
    singleton_class do
      has :doc
    end
  end
  class KeyValue < Base
    # specify order (should I need to do this?)
    has :name
    has :value
    def to_s
      %[--#{name}="#{value}"]
    end
  end
  class Flag < Base
    def to_s
      %[--#{name}]
    end
  end
end

module Zenity
  include CommandLine
  class Entry < Flag
    # specifying name here has effect of re-ordering positional args
    doc "Display text entry dialogue"
    has :name, :default => :entry
  end
  class Text < KeyValue
    doc "Set the dialogue text"
    has :name, :default => :text
    has :value
    arg_order :value, :name
  end
  class EntryText < KeyValue
    doc "Set the entry text"
    has :name, :default => 'entry-text'
    has :value
    arg_order :value, :name
  end
  class HideText < KeyValue
    doc "Hide the entry text"
    has :name, :default => 'hide-text'
    arg_order :value, :name
  end

  class Command < Base
    def inspect
      "#{self.class}"
    end
    def to_s
      arg_order.map{ |x| send(x).to_s }.join(' ')
    end
  end

  class ZenityCommand < Command
#    has :name, :default => 'zenity'
  end
  
  class EntryCommand < ZenityCommand
    has :name, :default => 'zenity'
    has :entry, :kind => Entry, :default => Entry.new
    has :text, :kind => Text do
      from String do |s|
        Zenity::Text(s)
      end
    end
    has :entry_text, :kind => EntryText, :default => nil do
      from String do |s|
        Zenity::EntryText(:value => s)
      end
    end
    has :hide_text, :kind => HideText, :default => nil do
      from String do |s|
        Zenity::HideText(:value => s)
      end
    end
    must "not have both entry_text and hide_text" do
      !(ivar_defined?(:entry_text) && ivar_defined?(:hide_text))
    end
  end
end

e = Zenity::EntryCommand() do
  text "Enter your name"
  entry_text "Your name here"
  #  hide_text "Your name here"
end
puts e.to_s
system e.to_s
exit

module Zenity
  flag = true
  1.upto(100) do
    cmd = [
           Command.new("zenity"),
           Entry.new(),
           #       KeyValue.new("text", "Enter name:"),
           #       KeyValue.new(:name => "text", :value => "Enter name:"),
           #       Text.new(:value => "Enter name:"),
           #       Text.new(:value => "Enter name:"),
           Text("Enter name"),
           EntryText("Enter text"),
          ].join(' ')
    puts cmd if flag
    flag = false
  end
end
#result = `#{cmd}`
#puts "result=#{result}"

