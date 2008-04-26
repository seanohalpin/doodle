require File.dirname(__FILE__) + '/spec_helper.rb'

describe :DateRange, 'validation & conversions' do
  temporary_constants :Base, :DateRange, :ClassMethods do
    
    before :each do
      module ClassMethods
        def date(*a, &b)
  #        if a.size > 0
            name = a.shift
  #        else
  #          name = :date
  #        end
          td = has(name, { :kind => Date }, *a) do
            # it is a bit clumsy to define these conversions &
            # conditions for every attribute/typedef - could define a
            # subclass of Typedef which does this by default (so we
            # instances can override or defer to class level conversions
            # and conditions)
            from String do |s|
              Date.parse(s)
            end
            from Array do |y,m,d|
              #p [:from, Array, y, m, d]
              Date.new(y, m, d)
            end
            from Integer do |jd|
              Doodle::Debug.d { [:converting_from, Integer, jd] }
              Date.new(*Date.jd_to_civil(jd))
            end
          end
          Doodle::Debug.d { [:date, td] }
          td.instance_eval(&b) if block_given? # user's block should override default
        end
      end

      class Base < Doodle
        extend ClassMethods
      end

      class DateRange < Base
        date :start_date do
          Doodle::Debug.d { [:start_date, self, self.class] }
          default { Date.today }
          must "be >= 2007-01-01" do |d|
            d >= Date.new(2007, 01, 01)
          end
        end
        date :end_date do
          default { start_date }
        end
        must "have end_date >= start_date" do
          end_date >= start_date
        end
      end
    end
  
    it 'should not raise an exception if end_date >= start_date' do
      proc { DateRange.new('2007-01-01', '2007-01-02') }.should_not raise_error
    end
  
    it 'should raise an exception if end_date < start_date' do
      proc { DateRange.new('2007-01-02', '2007-01-01') }.should raise_error
    end

    it 'should raise an exception if end_date < start_date' do
      proc { DateRange.new('2007-01-01', '2007-01-01') }.should_not raise_error
    end

    it 'should have start_date kind == Date' do
      d = DateRange.new
      d.attributes[:start_date].kind == Date
    end

    it 'should have two validations' do
      d = DateRange.new
      d.attributes[:start_date].validations.size.should == 2    
      d.attributes[:start_date].validations(false).size.should == 2
    end

    it 'should have two conversions' do
      d = DateRange.new
      d.attributes[:start_date].conversions.size.should == 3    
      d.attributes[:start_date].conversions(false).size.should == 3
    end

    it 'should convert from Array' do
      d = DateRange.new [2007,01,01], [2007,01,02]
      d.start_date.should == Date.new(2007,01,01)
      d.end_date.should == Date.new(2007,01,02)
    end
  
    it 'should convert Integer representing Julian date to Date' do
      d = DateRange.new 2454428, 2454429
      d.start_date.should == Date.new(2007,11,23)
      d.end_date.should == Date.new(2007,11,24)
    end
  end
end

# describe Doodle, 'validations' do
#   temporary_constants :Foo do
#     before :each do
#       class Foo < Doodle
#         has :identifier, :kind => [String, Symbol]
#       end
#     end

#     it 'may have more than one kind#1' do
#       proc { foo = Foo(:foo) }.should_not raise_error
#     end

#     it 'may have more than one kind#2' do
#       proc { foo = Foo('foo') }.should_not raise_error
#     end

#   end
# end

describe Doodle, 'class validations' do
  temporary_constants :Foo, :Bar do
    before :each do
      class Foo < Doodle
        class << self
          has :meta, { :default => "data", :kind => String } do
            must "be >= 3 chars long" do |s|
              s.size >= 3
            end
          end
        end
      end
      class Bar < Foo
      end
    end

    it 'should validate singleton class attributes' do
      proc { Foo.meta = 1 }.should raise_error(Doodle::ValidationError) 
    end

    it 'should reject invalid singleton class attributes specified with must clause' do
      proc { Foo.meta = "a" }.should raise_error(Doodle::ValidationError) 
    end
    
    it 'should accept valid singleton class attributes specified with must clause' do
      proc { Foo.meta = "abc" }.should_not raise_error
    end

    it 'should validate inherited singleton class attributes' do
      proc { Bar.meta = 1 }.should raise_error(Doodle::ValidationError) 
    end

    it 'should reject invalid inherited singleton class attributes specified with must clause' do
      proc { Bar.meta = "a" }.should raise_error(Doodle::ValidationError) 
    end
    
    it 'should accept valid inherited singleton class attributes specified with must clause' do
      proc { Bar.meta = "abc" }.should_not raise_error
    end

  end
end


