# Rakefile
begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "doodle"
    gemspec.summary = %q{Doodle is a gem for simplifying the \
definition of Ruby classes by making attributes and their \
properties more declarative. Doodle is eco-friendly: it does not \
globally modify Object, Class or Module.}
    gemspec.description = %q{Doodle is a gem for simplifying the \
definition of Ruby classes by making attributes and their \
properties more declarative. Doodle is eco-friendly: it does not \
globally modify Object, Class or Module.}
    gemspec.email = "sean.ohalpin@gmail.com"
    gemspec.homepage = "http://doodle.rubyforge.org/"
    gemspec.authors = ["Sean O'Halpin"]

    gemspec.files =
      FileList[
               "doodle.gemspec",
               "lib/**/*",
               "examples/**/*",
               "spec/**/*"
               "COPYING",
               "CREDITS",
               "History.txt",
               "License.txt",
               "PostInstall.txt",
               "README.txt",
               "Rakefile",
               "VERSION",
              ]
    gemspec.test_files = ["spec/*_spec.rb"]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end
