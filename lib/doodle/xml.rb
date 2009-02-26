require 'rubygems'
#require 'nokogiri'
require 'rexml/document'

class Doodle
  module EscapeXML
    ESCAPE = { '&' => '&amp;', '"' => '&quot;', '>' => '&gt;', '<' => '&lt;' }

    def self.escape(s)
      s.to_s.gsub(/[&"><]/) { |special| ESCAPE[special] }
    end
    def self.unescape(s)
      ESCAPE.inject(s.to_s) do |str, (k, v)|
        # don't use gsub! here - don't want to modify argument
        str.gsub(v, k)
      end
    end
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

    def self.parse_xml(xml)
      #doc = Nokogiri::XML(str) # nokogiri
      REXML::Document.new(xml)
    end

    def self.text_node?(node)
      node.kind_of?(::REXML::Text)
      # node.name == "text"
    end

    def self.from_xml(ctx, str)
      doc = parse_xml(str)
      root = doc.children.first
      from_xml_elem(ctx, root)
    end

    def self.from_xml_elem(ctx, root)
      attributes = root.attributes.inject({ }) { |hash, (k, v)| hash[k] = EscapeXML.unescape(v.to_s); hash}
      text, children = root.children.partition{ |x| text_node?(x) }
      text = text.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
      oroot = Utils.const_lookup(root.name, ctx).new(text, attributes) {
        from_xml_elem(root)
      }
      oroot
    end

    def from_xml_elem(parent)
      children = parent.children.reject{ |x| XML.text_node?(x) }
      children.each do |child|
        text = child.children.select{ |x| XML.text_node?(x) }.map{ |x| x.to_s}.reject{ |s| s =~ /^\s*$/}.join('')
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
      end.join('')
    end

    def to_xml
      body = []
      attributes = []
      self.doodle.attributes.map do |k, attr|
        next if self.default?(k)
        # arbitrary
        if k == :_text_
          body << self._text_
          next
        end
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

