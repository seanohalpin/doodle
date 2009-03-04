#!/usr/bin/env ruby
require 'rubygems'
require 'directory_watcher'

dw = DirectoryWatcher.new(".", :glob => "**/*", :pre_load => true)
dw.interval = 1
dw.add_observer {|*events|
  rebuild, build = events.reject{ |event| event.path =~ /\/output/}.partition{ |event| event.path =~ %r{/_|/lib} }
#   p [:rebuild, rebuild]
#   p [:build, build]
  events.each {|event|
    puts event
  }
  if rebuild.size > 0
    system "webby rebuild"
  elsif build.size > 0
    system "webby build"
  end
}

dw.start
gets      # when the user hits "enter" the script will terminate
dw.stop
