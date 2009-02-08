require File.dirname(__FILE__) + '/spec_helper.rb'
require 'doodle/xml'

describe Doodle, 'xml serialization within a module' do
  temporary_constants :Container, :Base, :Slideshow, :Layout do
    before(:each) do
      @xml_source = '<Slideshow id="1" name="test"><Layout template="generic" /></Slideshow>'
      module Container
        class Base < Doodle
          include Doodle::XML
        end
        class Layout < Base
          has :template
        end
        class Slideshow < Base
          has :id, :kind => Integer do
            from String do |s|
              s.to_i
            end
          end
          has :name, :kind => String
          has Layout
        end
      end
    end
    it 'should serialize to xml' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      slideshow.to_xml.should_be @xml_source
    end
    it 'should serialize from xml' do
      slideshow = Container::Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle::XML.from_xml(Container, @xml_source)
      ss2.should_be slideshow
    end
  end
end

describe Doodle, 'xml serialization at top level' do
  temporary_constants :Base, :Slideshow, :Layout do
    before(:each) do
      @xml_source = '<Slideshow id="1" name="test"><Layout template="generic" /></Slideshow>'
      class Base < Doodle
        include Doodle::XML
      end
      class Layout < Base
        has :template
      end
      class Slideshow < Base
        has :id, :kind => Integer do
          from String do |s|
            s.to_i
          end
        end
        has :name, :kind => String
        has Layout
      end
    end
    it 'should serialize to xml' do
      slideshow = Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      slideshow.to_xml.should_be @xml_source
    end
    it 'should serialize from xml' do
      slideshow = Slideshow.new do
        id 1
        name "test"
        layout "generic"
      end
      ss2 = Doodle::XML.from_xml(Object, @xml_source)
      ss2.should_be slideshow
    end
  end
end
