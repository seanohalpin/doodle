if false
  # not ready for primetime
  #if RUBY_VERSION >= '1.8.7'
  require 'doodle/collector-1.9'
else
  # version for ruby 1.8.6
  class Doodle
    class AppendableAttribute
      def define_collector
        # FIXME: don't use eval in 1.9+
        if collector_class.nil?
          doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                   collection = self.#{name}
                   args.unshift(block) if block_given?
                   collection.<<(*args);
                 end", __FILE__, __LINE__)
        else
          doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                          collection = self.send(:#{name})
                          if args.size > 0 and args.all?{|x| x.kind_of?(#{collector_class})}
                            collection.<<(*args)
                          else
                            # FIXME: this is a wierd one - need name here - can't use collection directly...?
                            #{name} << #{collector_class}.new(*args, &block)
                            # this is OK
                            #self.send(:#{name}) << #{collector_class}.new(*args, &block)
                            # but this isn't
                            #collection.<<(#{collector_class}.new(*args, &block))
                          end
                        end", __FILE__, __LINE__)
        end
      end
    end

    class KeyedAttribute
      # define a collector for keyed collections
      # - collection should provide :[], :clone and :replace methods
      def define_collector
        # need to use string eval because passing block
        # FIXME: don't use eval in 1.9+
        if collector_class.nil?
          doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                   collection = #{name}
                   args.each do |arg|
                     #{name}[arg.send(:#{key})] = arg
                   end
                 end", __FILE__, __LINE__)
        else
          doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                          collection = #{name}
                          if args.size > 0 and args.all?{|x| x.kind_of?(#{collector_class})}
                            args.each do |arg|
                              #{name}[arg.send(:#{key})] = arg
                            end
                          else
                            obj = #{collector_class}.new(*args, &block)
                            #{name}[obj.send(:#{key})] = obj
                          end
                     end", __FILE__, __LINE__)
        end
      end
    end
  end
end
