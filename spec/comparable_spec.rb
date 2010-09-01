require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper.rb'))

describe Doodle, 'Comparable' do
  temporary_constants :Item, :MyList do
    before :each do
      #: definition
      class ::Item < Doodle
        has :name, :kind => String
      end
      class ::MyList < Doodle
        has :items, :collect => Item
      end
    end

    it 'makes it possible to sort doodles' do
      list = MyList do
        item "B"
        item "C"
        item "A"
      end
      list.items.sort.should_be [Item("A"), Item("B"), Item("C")]
    end
  end
end
