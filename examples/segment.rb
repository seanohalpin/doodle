require 'doodle'

include Doodle

module Constraints
  def string(name, *args, &block)
    opts, args = args.partition{ |x| x.kind_of?(Hash)}
    opts = *opts.flatten_first_level
    p [opts, args]
    max = opts.delete(:max) || 255
    min = opts.delete(:min) || 0
    p [opts, args]
    attr = has name, opts do
      p [:has, name, opts]
      kind String
      if !max.nil?
        must "be <= #{max} characters long" do |s|
          s.size <= max
        end
      end
      if !min.nil?
        must "be >= #{min} characters long" do |s|
          s.size >= min
        end
      end
    end
    attr.instance_eval(&block) if block_given?
  end
end

class PIT < Base
  extend Constraints
end

class Segment < PIT
  string :title, :min => 1, :max => 255
  string :composer, :min => 1, :default => ''
end

def try(&block)
  begin
    block.call
  rescue Exception => e
    e.to_s
  end
end

p Segment("Hello Dolly")
try { Segment("Hello Dolly") }                     # =>
try { seg = Segment("Hello Dolly"); seg.composer } # =>
try { Segment("Hi", "Beethoven") }                 # =>
try { Segment("") }                                # =>
try { Segment(:composer => "Mozart") }             # =>
try { Segment("Taxman", "") }                      # =>
try { Segment("Taxman") }                          # =>
