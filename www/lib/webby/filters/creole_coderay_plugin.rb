# provide the means to import source code into webby site
# running through xmpfilter and selecting sections
# with pre and post filters
require 'rubygems'
require 'wiki_creole'
require 'coderay'
require 'shellwords'
require 'yaml'
require 'systemu'

def project_root(*args)
  path = [File.dirname(__FILE__)]
  while !File.exist?(File.join(path, 'lib', 'doodle.rb'))
    path << '..'
  end
  path = path.push(*args)
  File.expand_path(File.join(*path))
end
$:.unshift(project_root('lib'))

ENV['RUBYLIB'] = project_root('lib')

require 'doodle'
require 'doodle/xml'

def example_path(filename)
  project_root('www', 'content', 'examples', filename)
end

def plugin_tag(input)
  tag = :none
  args = []
  if input =~ /^\s*(.*)$/
    match = $1
    tag, args = match.split(/\s+/, 2)
    args = [args].flatten.compact.join(' ').strip
    p args
    if args !~ /^\{.*\}$/
      args = "{#{args}}"
    end
    args = YAML::load(args)
    args.each do |k, v|
      if k.is_a?(String)
        sym_key = k.to_sym
        if !args.key?(sym_key)
          args[sym_key] = v
        end
      end
    end
    input = input.gsub(/^\s*#{Regexp.escape(match)}\n*/, '') #.gsub(/\s*$/, '')
  end
  [tag, args, input]
end

module CreolePlugin
  module ModuleMethods
    def sections(input, *wanted_sections)
      h = split_file(input)
      res = wanted_sections.inject([]) { |acc, section| acc << h[section] }.join('')
      # strip trailing newlines
      res.gsub(/\n+\Z/,'')
    end

    def split_file(input)
      sections = input.split(/^(#:\s*.*)$/)
      # p sections.first
      while sections.first == ""
        sections.shift
      end
      sections = sections.
        map{ |x| x.gsub(/\A\s*\Z/, '')}.
        map{ |x| x.gsub(/\A\n*/, '')}.
        map{ |x| x == '' ? nil : x}.
        map{ |x| x =~ /^#:\s*(.*)$/ ? $1 : x}
      #p [:sections, sections]

      res = Hash[*sections]
      #p res
      res
    end

    def plugin_source(input, args = { }, &block)
      if filename = args.delete(:filename)
        path = example_path(filename)
        input = File.read(path)
      end
      # pre filter chain
      if filters = args.delete(:filters) || args.delete(:filter) || args.delete(:pre)
        filters.each do |filter|
          status, input = systemu(filter, :stdin => input)
        end
      end
      # select sections
      if wanted_sections = args.delete(:sections) || args.delete(:section)
        wanted_sections = [wanted_sections].flatten
        #p [:sections, wanted_sections]
        input = sections(input, *wanted_sections)
      end
      if filters = args.delete(:after) || args.delete(:post)
        filters.each do |filter|
          if filter == "stripxmp"
            filter = "sed 's/# >> //g'"
          end
          status, input = systemu(filter, :stdin => input)
        end
      end
      lang = args.delete(:lang) || "ruby"
      lang = lang.to_sym
      css_class = args.delete(:class) || :coderay
      case css_class
      when :coderay
        output = '<div class="CodeRay"><pre>'
        #STDERR.puts [lang, args].inspect
        output << ::CodeRay.scan(input, lang).html(args)
        output << '</pre></div>'
      when :output
        output = %[<pre class="output">#{Doodle::EscapeXML.escape(input)}</pre>]
      end
      output
    end

    def plugin_ruby(input, args = { })
      #STDERR.puts args.inspect
      plugin_source(input, { :lang => :ruby }.merge(args) )
    end

    def plugin_xmp(input, args = { })
      plugin_source(input, { :lang => :ruby, :filter => 'xmpfilter' }.merge(args) )
    end

    def plugin_output(input, args = { })
      plugin_source(input, { :class => :output }.merge(args))
    end
  end
  extend ModuleMethods
end

WikiCreole.creole_plugin {|input|
  tag, args, input = plugin_tag(input)
  #STDERR.puts [tag, args, input]
  method = "plugin_#{tag}"
  if CreolePlugin.respond_to?(method)
    #STDERR.puts "GOT #{method}"
    output = CreolePlugin.send(method, input, args)
  else
    output = input
  end
  output
}
