require 'spec/rake/spectask'

namespace :mm do
  desc "Run tests"
  Spec::Rake::SpecTask.new('spec') do |t|
    t.spec_files = FileList['spec/**/*.rb']
    t.spec_opts = ['--colour --format specdoc --loadby mtime --reverse']
  end

  desc "Run specs and generate HTML output"
  Spec::Rake::SpecTask.new('spec-html') do |t|
    t.spec_files = FileList['spec/**/*.rb']
    t.spec_opts = ['--colour --format html']
  end
  
  desc "Run all specs with RCov"
  Spec::Rake::SpecTask.new('coverage') do |t|
    t.spec_files = FileList['spec/**/*.rb']
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

  namespace :docs do
    desc "Generate rote docs"
    task :rote do
      system "cd ./rote && rake"
    end

    desc "Copy docs to rubyforge"
    task :copy_rote_docs_to_rubyforge => [:rote, :rdoc] do
      system "scp -r rote/html/* monkeymind@rubyforge.org:/var/www/gforge-projects/doodle/"
    end
  end
  
  # rebuild TAGS file
  module Tags
    RUBY_FILES = FileList['**/*.rb'].exclude("pkg")
  end

  namespace "tags" do
    task :emacs => Tags::RUBY_FILES do
      puts "Making Emacs TAGS file"
      sh "ctags-exuberant -e #{Tags::RUBY_FILES}", :verbose => false
    end
  end

  desc "Build example .xmp.rb file from an .rb file"
  rule '.xmp.rb' => ['.rb'] do |t|
    system "xmpfilter #{t.source} > #{t.name}"
  end
  
  task :tags => ["tags:emacs"]
end
