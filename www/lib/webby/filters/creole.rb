
require 'wiki_creole'
require File.expand_path(File.join(File.dirname(__FILE__), 'creole_coderay_plugin'))

transforms = {
  # @code@ but not @like this@
  "@" => [ "{{{", "}}}" ],
  # rdoc style
  "+" => [ "{{{", "}}}" ],
  # single ~words~ can be highlighted but not ~like this~
  "~" => "//",
#   "_" => "//",
}

Webby::Filters.register :creole do |input, cursor|
  # need to stash away plugin source
  # apply these hacks
  # then restore plugin source

  transforms.each do |sigil, replacement|
    if sigil.kind_of?(Array)
      sigil_left, sigil_right = *sigil
    else
      sigil_left = sigil_right = sigil
    end
    if replacement.kind_of?(Array)
      left, right = *replacement
    else
      left = right = replacement
    end
    input = input.gsub(/#{Regexp.escape(sigil_left)}([\w:\?_#!]+?)#{Regexp.escape(sigil_right)}/, left + '\1' + right)
  end

#   # single ~words~ can be highlighted but not ~like this~
#   input = input.gsub(/~(\w+)~/, '//\1//')

#   # single @words@ can be highlighted but not @like this@
#   input = input.gsub(/@(\w+)@/, '{{{\1}}}')

  # handle $ shell code
  input = input.gsub(/^(\s*\$.*$)/, '<<< source lang: shell
\1
>>>')
  puts input
  WikiCreole.creole_parse(input)
end
