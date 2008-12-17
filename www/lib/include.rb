# TODO: add selectors (cf. S5 includer)
def include(fn)
  File.read(File.join('content', fn))
end

# TODO: add selectors (cf. S5 includer)
def ruby(fn = nil, &block)
#   if fn
#     src = include(fn)
#     blk = proc { src }
#   else
#     blk = block
#   end
  coderay :lang => :ruby, &block
end
