def wikilink(link_text, context = {})
  link, text = link_text.split(/\|/)
  link, anchor = link.split(/#/)
  #p [1, :link, link, :anchor, anchor, :text, text]
  [link, anchor, text]
end

# if  __FILE__ == $0
#   wikilink("hello")
#   wikilink("hello#world")
#   wikilink("hello#world|text")
#   wikilink("hello|text")
# end

Webby::Filters.register :wikilinks do |input, cursor|

  renderer = cursor.renderer
  input = input.gsub %r/link\[([^\]]+)\]/ do
  #input.gsub %r/\[\[([^|\]]+)\]\]/ do
    name = $1
    p [:wikilink, name]
    link, anchor, text = wikilink(name)
    text ||= link
    # apologies for confusing terminology :)
    renderer.link_to_page(text, :title => link, :url => { :anchor => anchor }) {
      %Q(<a class="missing internal">#{text}</a>)
    }
  end

end
