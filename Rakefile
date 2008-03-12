# Rakefile for doodle project
# Sean O'Halpin, 2007-11-24
require 'rake'
require 'rake/gempackagetask'
require 'spec/rake/spectask'
require 'rubygems'

task :default => [:all]

all_tasks = [:spec, :rcov, :rdoc, :dcov]
#all_tasks = [:spec, :rcov, :rdoc, :profile, :dcov]
desc "Run all tasks: #{all_tasks.map{|x| x.to_s}.join(', ')}"
task :all => all_tasks

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

desc "Profile application"
task :profile do
  system "ruby-prof examples/profile-options.rb > scratch/profile-options.txt"
  system "ruby-prof -p graph_html examples/profile-options.rb > scratch/profile-options.html"
  puts File.read("scratch/profile-options.txt")
end

desc "Sanity check examples"
task :check_examples do
  system "for p in examples/*.rb ; do ruby $p>/dev/null; done"
end

desc "Documentation coverage"
task :dcov do
  system "dcov lib/doodle.rb"
end

desc "Assess complexity (with flog)"
task :flog do
  system "flog doodle.rb lib/*.rb"
end

VERSION = "0.0.4"

spec = Gem::Specification.new do |s| 
  s.name = "doodle"
  s.version = VERSION
  s.author = "Sean O'Halpin"
  s.email = "sean.ohalpin@gmail.com"
  s.homepage = "http://doodle.rubyforge.org/"
  s.platform = Gem::Platform::RUBY
  s.summary = "Declarative attribute definitions, validations and conversions"
  s.files = FileList["{bin,lib,examples}/**/*"].to_a
  s.require_path = "lib"
  s.test_files = FileList["{spec}/**/*spec.rb"].to_a
  s.has_rdoc = true
  s.extra_rdoc_files = ["README", "COPYING", "ChangeLog"]
  s.rubyforge_project = "doodle"
end
 
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_tar = true
end

desc "Generate rote docs"
task :rote do
  system "cd ./rote && rake"
end

desc "Copy docs to rubyforge"
task :publish_docs => [:rdoc] do
  system "scp -r rote/html/* monkeymind@rubyforge.org:/var/www/gforge-projects/doodle/"
end

desc "Upload new gem"
task :upload_gem => [:gem] do
  sh "rubyforge add_release doodle doodle #{VERSION} pkg/doodle-#{VERSION}.gem"
end



