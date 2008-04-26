$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'doodle'

class Doodle
  class DataTypeHolder
    attr_accessor :klass
    def initialize(klass, &block)
      @klass = klass
      instance_eval(&block) if block_given?
    end
    def define(name, params, block, type_params, &type_block)
      @klass.class_eval {
        td = has(name, type_params.merge(params), &type_block)
        td.instance_eval(&block) if block
        td
      }
    end
  end

  # set up global datatypes
  def self.datatypes(*mods)
    mods.each do |mod|
      DataTypeHolder.class_eval { include mod }
    end
  end

  # enable global datatypes and provide an interface that allows you
  # to add your own datatypes to this declaration
  def self.doodle(*mods, &block)
    dh = Doodle::DataTypeHolder.new(self)
    mods.each do |mod|
      dh.extend(mod)
    end
    dh.instance_eval(&block)
  end
end

### user code
require 'date'
require 'uri'
#require 'rfc822'

# note: this doesn't have to be in Doodle namespace
class Doodle
  module DataTypes
    def integer(name, params = { }, &block)
      define name, params, block, { :kind => Integer } do
        from Float do |n|
          n.to_i
        end
        from String do |n|
          n =~ /[0-9]+(.[0-9]+)?/ or raise "#{name} must be numeric"
          n.to_i
        end
      end
    end

    def symbol(name, params = { }, &block)
      define name, params, block, { :kind => Symbol } do
        from String do |s|
          s.to_sym
        end
      end
    end
    
    def string(name, params = { }, &block)
      # must extract non-standard attributes before processing with
      # define otherwise causes UnknownAttribute error in Attribute definition
      if params.key?(:max)
        max = params.delete(:max)
      end
      if params.key?(:size)
        size = params.delete(:size)
        # size should be a Range
        size.kind_of?(Range) or raise ArgumentError, ":size should be a Range", caller[-1]
      end
      define name, params, block, { :kind => String } do
        from String do |s|
          s
        end
        from Integer do |i|
          i.to_s
        end
        from Symbol do |s|
          s.to_s
        end
        if max
          must "be <= #{max} characters" do |s|
            s.size <= max
          end
        end
        if size
          must "have size from #{size} characters" do |s|
            size.include?(s.size)
          end
        end
      end
    end

    def uri(name, params = { }, &block)
      define name, params, block, { :kind => URI } do
        from String do |s|
          URI.parse(s)
        end
      end
    end

    def email(name, params = { }, &block)
      string(name, { :max => 255 }.merge(params), &block).instance_eval do
        must "be valid email address" do |s|
          #s =~ RFC822::EmailAddress
          s =~ /\A.*@.*\z/
        end
      end
    end
    
    def date(name, params = { }, &block)
      define name, params, block, { :kind => Date } do
        from String do |s|
          Date.parse(s)
        end
        from Array do |y,m,d|
          Date.new(y, m, d)
        end
        from Integer do |jd|
          Date.new(*Date.jd_to_civil(jd))
        end
      end
    end

    def version(name, params = { }, &block)
      define name, params, block, { :kind => String } do
        must "be of form n.n.n" do |str|
          str =~ /\d+\.\d+.\d+/
        end
        from Array do |a|
          a.join('.')
        end
      end
    end
  end
end

# tell doodle to incorporate the datatypes
Doodle.datatypes Doodle::DataTypes

