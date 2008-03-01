$:.unshift(File.join(File.dirname(__FILE__), '../.'))

require 'lib/doodle'
require 'date'

def undefine_const(*consts)
  consts.each do |const|
    if Object.const_defined?(const)
      Object.send(:remove_const, const)
    end
  end
end

def raise_if_defined(*args)
  defined, undefined = args.partition{ |x| Object.const_defined?(x)}
  raise "Namespace pollution: #{defined.join(', ')}" if defined.size > 0
end


