class Doodle
  # base class for attribute collector classes
  class AttributeCollector < DoodleAttribute
    # FIXME: collector
    has :collector_class
    has :collector_name

    def resolve_collector_class
      # FIXME: collector - perhaps don't allow non-class collectors - should be resolved by this point
      if !collector_class.kind_of?(Class)
        self.collector_class = Doodle::Utils.const_resolve(collector_class)
      end
    end
    def resolve_value(value)
      # FIXME: collector - find applicable collector class
      if value.kind_of?(collector_class)
        # no change required
        #p [:resolve_value, :value, value]
        value
      elsif collector_class.__doodle__.conversions.key?(value.class)
        # if the collector_class has a specific conversion for this value class
        #p [:resolve_value, :collector_class_from, value]
        collector_class.from(value)
      else
        # try to instantiate collector_class using raw value
        #p [:resolve_value, :collector_class_new, value]
        collector_class.new(value)
      end
    end
    def initialize(*args, &block)
      super
      define_collector
      from Hash do |hash|
        # FIXME: collector - my bogon detector just went off the scale - I forget why I have to do this here... :/
        resolve_collector_class
        hash.inject(self.init.clone) do |h, (key, value)|
          h[key] = resolve_value(value)
          h
        end
      end
      from Enumerable do |enum|
        #p [:enum, Enumerable]
        # FIXME: collector
        resolve_collector_class
        # this is not very elegant but String is a classified as an
        # Enumerable in 1.8.x (but behaves differently)
        if enum.kind_of?(String) && self.init.kind_of?(String)
          post_process( resolve_value(enum) )
        else
          post_process( enum.map{ |value| resolve_value(value) } )
        end
      end
    end
    def post_process(results)
      #p [:post_process, results]
      self.init.clone.replace(results)
    end
  end

  # define collector methods for array-like attribute collectors
  class AppendableAttribute < AttributeCollector
    #    has :init, :init => DoodleArray.new
    has :init, :init => []

    # define a collector for appendable collections
    # - collection should provide a :<< method
    if RUBY_VERSION >= '1.9.1'
    end
  end

  # define collector methods for hash-like attribute collectors
  class KeyedAttribute < AttributeCollector
    #    has :init, :init => DoodleHash.new
    has :init, :init => { }
    #has :init, :init => OrderedHash.new
    has :key

    def post_process(results)
      results.inject(self.init.clone) do |h, result|
        h[result.send(key)] = result
        h
      end
    end
  end
end

if false
  # not ready for primetime
  #if RUBY_VERSION >= '1.8.7'
  # load ruby 1.8.7+ version specific methods
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
