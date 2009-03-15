begin
  require 'ruby2ruby'
  require 'parse_tree_extensions'
rescue LoadError => e
  class Object
    def to_ruby
      "<source not available>"
    end
  end
end

class AssertFailed < Exception
end
class DenyFailed < Exception
end

def assert(&block)
  #puts block.to_ruby
  if !block.call
    source = block.to_ruby.gsub(/^proc \{\s*\(?(.*?)\)?\s*\}/, '\1')
    #raise AssertFailed, source, [caller[-1]]
    puts "AssertFailed: #{source} : #{ [caller[-1]] }"
  else
    print '.'
  end
end
END { puts }

alias :expect :assert

def expect_error(exception = nil, &block)
  rv = false
  begin
    rv = !block.call
    #p [:expect_error, 0, rv]
  rescue Object => e
    #p [:expect_error, 1, exception]
    rv = false
    if exception.nil?
      #p [:expect_error, 2]
      rv = true
    elsif exception.kind_of?(Class) && exception <= Exception
      if e.kind_of?(exception)
        #p [:expect_error, 3]
        rv = true
      else
        rv = false
        msg = "expected #{exception} but got #{e.class}"
      end
    elsif exception.kind_of?(String)
      #p [:expect_error, 4]
      if e.to_s.include?(exception)
        #p [:expect_error, 5]
        rv = true
      end
    elsif exception.kind_of?(Regexp)
      #p [:expect_error, 6]
      if e.to_s =~ exception
        #p [:expect_error, 7]
        rv = true
      end
    end
  end
  #p [:expect_error, 8]
  if !rv
    #p [:expect_error, 9]
    source = block.to_ruby.gsub(/^proc \{\s*\(?(.*?)\)?\s*\}/, '\1')
    if msg.nil?
      msg = "expected error but there was none"
    end
    msg = [msg, source].join(": ")
    if e
      msg += " raised exception #{e.class}: '#{e}'"
    end
    puts "AssertFailed: #{msg} : #{ [caller[-1]] }"
    #raise AssertFailed, msg, [caller[-1]]
  else
    print '.'
  end
end
alias :assert_error :expect_error

def expect_ok(&block)
  rv = begin
         if !block.call
           msg = block.to_ruby.gsub(/^proc \{\s*\(?(.*?)\)?\s*\}/, '\1')
           #puts "AssertFailed: #{msg} : #{ [caller[-1]] }"
           raise AssertFailed, msg, [caller[-1]]
         end
       rescue Object => e
         source = block.to_ruby.gsub(/^proc \{\s*\(?(.*?)\)?\s*\}/, '\1')
         msg = source + " raised exception #{e.class}: '#{e}'"
         puts "AssertFailed: #{msg} : #{ [caller[-1]] }"
         #raise AssertFailed, msg, [caller[-1]]
         false
       end
  if !rv
    print '.'
  end
end
alias :assert_ok :expect_ok

def deny(&block)
  if block.call
    source = block.to_ruby.gsub(/^proc \{\s*\(?(.*?)\)?\s*\}/, '\1')
    #raise DenyFailed, source, [caller[-1]]
    puts "DenyFailed: #{source} : #{[caller[-1]]}"
  end
end
alias :disprove :deny
alias :refute :deny
alias :reject :deny

def __dummy__
  1 + 1
end

# why I don't know, but we need this otherwise to_ruby won't work on
# blocks - can be any method defined in this file
dummy = method(:__dummy__).to_ruby
