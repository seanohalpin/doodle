# Rakefile for doodle project
# Sean O'Halpin, 2007-11-24
require 'rake'
require 'spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  #  t.spec_files = FileList['*.spec']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'examples']
end

desc "Run tests"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*.rb']
  t.spec_opts = ['--colour --format specdoc --loadby mtime --reverse']
end

desc "Create class diagram"
task('diagram') do |t|
  system("ruby scripts/doodle2dot.rb")
end

# RDoc stuff
file 'README'
file 'LICENSE'
file 'COPYING'

desc "Build example .rdoc file from .rb file"
rule '.rdoc' => ['.rb'] do |t|
  system "xmpfilter #{t.source} > #{t.name}"
end

desc "Create examples for rdoc"
examples = Dir['examples/example-*.rb'].map{ |x| x.ext('.rdoc')}
task :examples => examples
# task :examples do
#   Dir["examples/example*.rb"].each do |file|
#     system "xmpfilter #{file} > #{file}.rdoc"
#   end
# end
task :rdoc => :examples

require 'rake/rdoctask'
desc "Create rdoc"
Rake::RDocTask.new do |rdoc|
  files = ['README', 'LICENSE', 'COPYING', 'lib/**/*.rb',
           'doc/**/*.rdoc', 'test/*.rb']
  rdoc.rdoc_files.add(files)
  rdoc.main = "README" # page to start on
  rdoc.title = "doodle"
  rdoc.rdoc_dir = 'doc' # rdoc output folder
  rdoc.template = '~/rdoc/jamis'
  rdoc.options << '--line-numbers' << '--inline-source'
end

desc 'Build all'
task :all => [:spec, :rcov, :rdoc, :profile, :dcov]

desc 'checkin after running tests'
task :commit => [:spec] do
  if ENV['comment'].nil?
    puts <<-EOT
You must specify a comment, e.g.
  $ rake commit comment="My comment"
EOT
  else
    system %[svn commit -m"#{ENV['comment']}"]
  end
end

desc 'scratch task for testing'
task :scratch => [:spec] do
  if ENV['comment'].nil?
    puts <<-EOT
You must specify a comment, e.g.
  $ rake commit comment="My comment"
EOT
  else
    p ENV['comment']
    puts %[svn commit -m"#{ENV['comment']}"]
  end
end

task :default => [:all]

desc "Profile application"
task :profile do
  system "ruby-prof examples/profile-options.rb > scratch/profile-options.txt"
  system "ruby-prof -p graph_html examples/profile-options.rb > scratch/profile-options.html"
  puts File.read("scratch/profile-options.txt")
end

desc "Sanity check examples"
task :check do
  system "for p in examples/*.rb ; do ruby $p>/dev/null; done"
end

desc "Documentation coverage"
task :dcov do
  system "dcov doodle.rb lib/*.rb"
end

desc "Assess complexity (with flog)"
task :flog do
  system "flog doodle.rb lib/*.rb"
end
