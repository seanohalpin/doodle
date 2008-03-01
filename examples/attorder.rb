require 'lib/doodle'

class A < Doodle::Base
  has :name, :default => 'anon'
  class << self
    has :metadata, :default => 'hello'
  end
end

class B < A
  has :other, :default => nil
  class << self
    has :doc, :default => 'world'
  end
end

class C < B
  has :more, :default => ''
end

# p B.attributes.keys
# p C.attributes.keys

p B.parents
p C.parents

# p B.class_eval { collect_inherited(:local_attributes) }
# p C.class_eval { collect_inherited(:local_attributes) }

p B.new.meta.parents
p B.new.meta.attributes.keys

p A.metadata
p B.doc
