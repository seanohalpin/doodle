# Shared code for all pages below this directory.
#
# This is executed for every file transformed, in the binding of 
# the appropriate Rote::Page instance. Individual page sources
# ([pagename].rb) override anything defined here.
#
# Any COMMON.rb files found in directories above this will also
# be loaded.

@page_index = Dir["#{File.dirname(__FILE__)}/*"].reject{|x| x =~ /\.rb$/}.map{|x| File.basename(x, File.extname(x))}
dir = File.join(File.dirname(__FILE__), '..', '..', '..', 'lib', 'doodle')
@dir = dir
require File.join(dir, 'version')
@version = Doodle::VERSION::STRING

@site_title = "doodle"
page_filter Filters::Syntax.new
@toc = Filters::TOC.new
page_filter @toc = Filters::TOC.new

# allow comma separated args
code_re = /^\s*\#\:([a-z]+)(?:\#([a-z, ]*))?\#\s*?\n?(.*?)\s*\#\:\1\#(?:\2\#)?\s*$/m

page_filter Rote::Filters::MacroFilter.new([:foomacro], code_re) { |tag, args, body|
  args = args.to_s.split(/,/).map{ |x| x.strip }
  txt=%[
<pre>
foomacro
#{tag.inspect}
#{args.inspect}
#{body.inspect}
</pre>
<b>#{body}</b>
]
  txt
}

page_filter Rote::Filters::MacroFilter.new([:version], code_re) { |tag, args, body|
  "Version #{@version}"
}

page_filter Rote::Filters::MacroFilter.new([:note], code_re) { |tag, args, body|
  args = args.to_s.split(/,/).map{ |x| x.strip }
  txt = <<EOT
  <div class="note"><p>#{body}</p></div>
EOT
  txt
}

layout 'normal.html'

# Some helpers for writing out links and sections within
# the text

def page_link(page)
  uri = link_rel "/#{page}.html"
  %[<a href="#{uri}">#{page}</a>]
end
def section_anchor(name)
  name.downcase.gsub(/\s/,'_')
end

def section_link(name, text = name)
  %Q{"#{text}":\##{section_anchor(name)}}
end

def section(level, name, toplink = true)
%Q{
#{"[#{section_link('Top')}]" if toplink}
h#{level}. #{name}
}
end
