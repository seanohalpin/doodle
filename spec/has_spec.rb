require File.dirname(__FILE__) + '/spec_helper.rb'

describe Doodle, 'has Class' do
  temporary_constant :Foo, :Bar do
    it "should convert 'has Bar' into 'has :bar, :kind => Bar'" do
      class Bar
      end
      class Foo < Doodle
        has Bar
      end
      att = Foo.doodle_attributes.values.first
      att.name.should_be :bar
      att.kind.should_be Bar
    end
    it "should allow overriding name of attribute when using 'has Bar'" do
      class Bar
      end
      class Foo < Doodle
        has Bar, :name => :baz
      end
      att = Foo.doodle_attributes.values.first
      att.name.should_be :baz
      att.kind.should_be Bar
    end
    it "should convert class name to snakecase when using 'has AudioClip' form" do
      class AudioClip
      end
      class Foo < Doodle
        has AudioClip
      end
      att = Foo.doodle_attributes.values.first
      att.name.should_be :audio_clip
      att.kind.should_be AudioClip
    end
  end
end
