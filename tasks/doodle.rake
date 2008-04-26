require 'spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('coverage') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  #  t.spec_files = FileList['*.spec']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'examples']
end

desc "Profile application"
task :profile do
  system "ruby-prof examples/profile-options.rb > tmp/profile-options.txt"
  system "ruby-prof -p graph_html examples/profile-options.rb > tmp/profile-options.html"
  puts File.read("tmp/profile-options.txt")
end

desc "Documentation coverage"
task :dcov do
  system "dcov lib/doodle.rb"
end

desc "Assess complexity (with flog)"
task :flog do
  system "flog doodle.rb lib/*.rb"
end

desc "Check version"
task :check_version do
  puts Doodle::VERSION::STRING
end

desc "Generate rote docs"
task :rote do
  system "cd ./rote && rake"
end

#desc "Copy docs to rubyforge"
#task :publish_docs => [:rdoc] do
#  system "scp -r rote/html/* monkeymind@rubyforge.org:/var/www/gforge-projects/doodle/"
#end
