links = @toc.links.select { |l| l.tag =~ /h1/ }
if !links.empty?
  @page_title = links.first.title
else
  @page_title = 'Untitled'
end
