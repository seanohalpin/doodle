$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift(File.join(File.dirname(__FILE__), '.'))

require 'doodle'
require 'date'
require 'uri'
require 'rfc822'

module Doodle
  module DataTypes
  end

  class DataTypeHolder
    include DataTypes
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
  def self.datatypes(*mods)
    mods.each do |mod|
      DataTypeHolder.class_eval { include mod }
    end
  end
end

class Doodle::Base
  def self.doodle(&block)
    Doodle::DataTypeHolder.new(self, &block)
  end
end

### user code

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

  def name(name, params = { }, &block)
    string(name, { :size => 1..255 }.merge(params), &block).instance_eval do
      must "not contain numbers" do |s|
        s !~ /\d/
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
        s =~ RFC822::EmailAddress
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
Doodle.datatypes DataTypes

if __FILE__ == $0

  class DateRange < Doodle::Base
    doodle do
      date :start
      date :end do
        default { start + 1 }
      end
      version :version, :default => "0.0.1"
    end
  end

  #pp DateRange.instance_methods(false)

  class Person < Doodle::Base
    doodle do
      #    string :name, :max => 10
      name :name, :size => 3..10
      integer :age
      email :email, :default => ''
    end
  end

  def try(&block)
    begin
      block.call
    rescue Exception => e
      e
    end
  end

  require 'pp'

  pp try { DateRange "2007-01-18", :version => [0,0,9] }
  pp try { Person 'Sean', '45', 'sean.ohalpin@gmail.com' }
  pp try { Person 'Sean', '45' }
  pp try { Person 'Sean', 'old' }
  pp try { Person 'Sean', 45, 'this is not an email address' }
  pp try { Person 'This name is too long', 45 }
  pp try { Person 'Sean', 45, 42 }
  pp try { Person 'A', 45 }
  pp try { Person '123', 45 }
  pp try { Person '', 45 }
end
