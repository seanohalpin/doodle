require 'rubygems'
require 'nokogiri'

class Doodle
  module EscapeXML
    ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }

    def self.escape(s)
      s.to_s.gsub(/[&"><]/) { |special| ESCAPE[special] }
    end
    def self.unescape(s)
      s = s.to_s
      ESCAPE.each do |k, v|
        s = s.gsub(v, k)
      end
      s
    end
  end

  module Utils
    def self.normalize_const(const)
      const.to_s.gsub(/[-]/, '')
    end
    # lookup a constant along the module nesting path
    def const_lookup(const, context = self)
      const = Utils.normalize_const(const)
      result = nil
      if !context.kind_of?(Module)
        context = context.class
      end
      klasses = context.to_s.split(/::/)
      #p klasses

      path = []
      0.upto(klasses.size - 1) do |i|
        path << Doodle::Utils.const_resolve(klasses[0..i].join('::'))
      end
      path = (path.reverse + context.ancestors).flatten
      #p [:const, context, path]
      path.each do |ctx|
        #p [:checking, ctx]
        if ctx.const_defined?(const)
          result = ctx.const_get(const)
          break
        end
      end
      raise NameError, "Uninitialized constant #{const} in context #{context}" if result.nil?
      result
    end
    module_function :const_lookup

  end

  # adds to_xml and from_xml methods for serializing and deserializing
  # Doodle object graphs to and from XML
  #
  # works for me but YMMV
  module XML
    include Utils
    class Document < Doodle
      include Doodle::XML
    end
    
    def self.from_xml(ctx, str)
      doc = Nokogiri::XML(str)
      root = doc.children.first
      from_xml_elem(ctx, root)
    end

    def self.from_xml_elem(ctx, root)
      attributes = root.attributes.inject({ }) { |hash, (k, v)| hash[k] = EscapeXML.unescape(v.to_s); hash}
      text, children = root.children.partition{ |x| x.name == "text"}
      text = text.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
      #p attributes
      oroot = Utils.const_lookup(root.name, ctx).new(text, attributes) { 
        from_xml_elem(root)
      }
      oroot
    end

    def from_xml_elem(parent)
      children = parent.children.reject{ |x| x.name == "text"}
      children.each do |child|
        text = child.children.select{ |x| x.name == "text"}.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
        object = const_lookup(child.name)
        method = Doodle::Utils.snake_case(Utils.normalize_const(child.name))
        attributes = child.attributes.inject({ }) { |hash, (k, v)| hash[k] = EscapeXML.unescape(v.to_s); hash}
        send(method, object.new(text, attributes) {
               from_xml_elem(child)
             })
      end
      #parent
      self
    end

    def tag
      #self.class.to_s.split(/::/)[-1].downcase
      self.class.to_s.split(/::/)[-1]
    end

    def format_attributes(attributes)
      if attributes.size > 0
        " " + attributes.map{ |k, v| %[#{ k }="#{ v }"]}.join(" ")
      else
        ""
      end
    end
    
    def format_tag(tag, attributes, body)
      if body.size > 0
        ["<#{tag}#{format_attributes(attributes)}>", body, "</#{tag}>"]
      else
        ["<#{tag}#{format_attributes(attributes)} />"]
      end.to_s
    end
    
    def to_xml
      body = []
      attributes = []
      self.doodle.attributes.map do |k, attr|
        next if self.default?(k)
        v = send(k)
        if v.kind_of?(Doodle)
          body << v.to_xml
        elsif v.kind_of?(Array)
          body << v.map{ |x| x.to_xml }
        else
          attributes << [k, EscapeXML.escape(v)]
        end
      end
      format_tag(tag, attributes, body)
    end
  end
end

