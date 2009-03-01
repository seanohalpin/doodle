require 'rubygems'
require 'wiki_creole'
require 'coderay'
require 'shellwords'
require 'yaml'

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
  def self.plugin_source(input, args = { })
    lang = args.delete(:lang).to_sym
    output = '<div class="CodeRay"><pre>'
    #STDERR.puts [lang, args].inspect
    output << ::CodeRay.scan(input, lang).html(args)
    output << '</pre></div>'
    output
  end

  def self.plugin_ruby(input, args = { })
    #STDERR.puts args.inspect
    plugin_source(input, args.merge(:lang => :ruby))
  end

  def self.plugin_xmp(input, args = { })
    #STDERR.puts args.inspect
    filename = args.delete(:filename)
    path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'content', 'examples', filename))
    p [:PATH, path]
    #input = File.read(filename)
    input = `xmpfilter #{path}`
    if wanted_sections = args.delete(:sections)
      wanted_sections = [wanted_sections].flatten
      #p [:sections, wanted_sections]
      input = sections(input, *wanted_sections)
    end
    plugin_source(input, args.merge(:lang => :ruby))
  end

  def self.sections(input, *wanted_sections)
    h = split_file(input)
    res = wanted_sections.inject([]) { |acc, section| acc << h[section] }.join('')
    #STDERR.puts res
    # strip trailing newlines
    res.gsub(/\n+\Z/,'')
  end
  
  def self.split_file(input)
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


  
  def self.plugin_output(input, args = { })
    %[<pre class="output">#{input}</pre>]
  end
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
