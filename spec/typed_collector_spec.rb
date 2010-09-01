require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe Doodle, 'typed collector' do
  temporary_constants :Item, :ItemList do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::ItemList < Doodle
        has :items, :init => Doodle::TypedArray(Item), :collect => Item
        #has :items, :collect => Item
      end
    end

    it 'should accept convertible values in collector' do
      list = nil
      expect_ok {
        list = ItemList do
          item "Hello"
          item "World"
        end
      }
      list.items.size.should_be 2
      list.items[1].should_be Item("World")
    end

    it 'should accept correctly typed values in collector' do
      list = nil
      expect_ok {
        list = ItemList do
          item Item("Hello")
          item Item("World")
        end
      }
      list.items.size.should_be 2
      list.items[1].should_be Item("World")
    end

    it 'should prevent adding invalid values' do
      list = ItemList.new
      expect_error(TypeError) {
        list.items << "Hello"
      }
    end

    it 'should accept valid values' do
      list = ItemList.new
      expect_ok {
        list.items << Item("Hello")
      }
      list.items.size.should_be 1
      list.items[0].should_be Item("Hello")
    end

  end
end
