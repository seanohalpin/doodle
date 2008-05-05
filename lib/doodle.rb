# doodle
# Copyright (C) 2007-2008 by Sean O'Halpin
# 2007-11-24 first version
# 2008-04-18 latest release 0.0.12
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'molic_orderedhash'  # todo[replace this with own (required functions only) version]

# require Ruby 1.8.6 or higher
if RUBY_VERSION < '1.8.6'
  raise Exception, "Sorry - doodle does not work with versions of Ruby below 1.8.6"
end

# *doodle* is my attempt at an eco-friendly metaprogramming framework that does not
# have pollute core Ruby objects such as Object, Class and Module.
#
# While doodle itself is useful for defining classes, my main goal is to
# come up with a useful DSL notation for class definitions which can be
# reused in many contexts.
#
# Docs at http://doodle.rubyforge.org
#
class Doodle
  class << self
    # provide somewhere to hold thread-specific context information
    # (I'm claiming the :doodle_xxx namespace)
    def context
      Thread.current[:doodle_context] ||= []
    end
  end

  # debugging utilities
  module Debug
    class << self
      # output result of block if ENV['DEBUG_DOODLE'] set
      def d(&block)
        p(block.call) if ENV['DEBUG_DOODLE']
      end
    end
  end

  # Place to hold ref to built-in classes that need special handling
  module BuiltIns
    BUILTINS = [String, Hash, Array]
  end

  # Set of utility functions to avoid monkeypatching base classes
  module Utils
    class << self
      # Unnest arrays by one level of nesting, e.g. [1, [[2], 3]] => [1, [2], 3].
      def flatten_first_level(enum)
        enum.inject([]) {|arr, i| if i.kind_of? Array then arr.push(*i) else arr.push(i) end }
      end
      # from facets/string/case.rb, line 80
      def snake_case(camel_cased_word)
        camel_cased_word.gsub(/([A-Z]+)([A-Z])/,'\1_\2').gsub(/([a-z])([A-Z])/,'\1_\2').downcase
      end
    end
  end

  # error handling
  @@raise_exception_on_error = true
  def self.raise_exception_on_error
    @@raise_exception_on_error
  end
  def self.raise_exception_on_error=(tf)
    @@raise_exception_on_error = tf
  end

  # internal error raised when a default was expected but not found
  class NoDefaultError < Exception
  end
  # raised when a validation rule returns false
  class ValidationError < Exception
  end
  # raised when an unknown parameter is passed to initialize
  class UnknownAttributeError < Exception
  end
  # raised when a conversion fails
  class ConversionError < Exception
  end
  # raised when arg_order called with incorrect arguments
  class InvalidOrderError < Exception
  end

  # provides more direct access to the singleton class and a way to
  # treat Modules and Classes equally in a meta context
  module SelfClass
    # return the 'singleton class' of an object, optionally executing
    # a block argument in the (module/class) context of that object
    def singleton_class(&block)
      sc = (class << self; self; end)
      sc.module_eval(&block) if block_given?
      sc
    end
    # evaluate in class context of self, whether Class, Module or singleton
    def sc_eval(*args, &block)
      if self.kind_of?(Module)
        klass = self
      else
        klass = self.singleton_class
      end
      klass.module_eval(*args, &block)
    end
  end

  # provide an alternative inheritance chain that works for singleton
  # classes as well as modules, classes and instances
  module Inherited

    # parents returns the set of parent classes of an object
    def parents
      anc = if respond_to?(:ancestors)
              if ancestors.include?(self)
                ancestors[1..-1]
              else
                # singletons have no parents (they're orphans)
                []
              end
            else
              self.class.ancestors
            end
      anc #.select{|x| x.kind_of?(Class)}
    end
    
    # need concepts of
    # - attributes
    # - instance_attributes
    # - singleton_attributes
    # - class_attributes
   
    # send message to all parents and collect results 
    def collect_inherited(message)
      result = []
      parents.each do |klass|
        if klass.respond_to?(message)
          result.unshift(*klass.__send__(message))
        else
          break
        end
      end
      result
    end
    private :collect_inherited
  end

  # the intent of embrace is to provide a way to create directives
  # that affect all members of a class 'family' without having to
  # modify Module, Class or Object - in some ways, it's similar to Ara
  # Howard's mixable[http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/197296]
  # though not as tidy :S
  #
  # this works down to third level <tt>class << self</tt> - in practice, this is
  # perfectly good - it would be great to have a completely general
  # solution but I'm doubt whether the payoff is worth the effort

  module Embrace
    # fake module inheritance chain
    def embrace(other, &block)
      # include in instance method chain
      include other
      sc = class << self; self; end
      sc.module_eval {
        # class method chain
        include other
        # singleton method chain
        extend other
        # ensure that subclasses are also embraced
        define_method :inherited do |klass|
          #p [:embrace, :inherited, klass]
          klass.__send__(:embrace, other)       # n.b. closure
          klass.__send__(:include, Factory)     # is there another way to do this? i.e. not in embrace
          super(klass) if defined?(super)
        end
      }
      sc.module_eval(&block) if block_given?
    end
  end

  # save a block for later execution
  class DeferredBlock
    attr_accessor :block
    def initialize(arg_block = nil, &block)
      arg_block = block if block_given?
      @block = arg_block
    end
  end
  
  # A Validation represents a validation rule applied to the instance
  # after initialization. Generated using the Doodle::BaseMethods#must directive.
  class Validation
    attr_accessor :message
    attr_accessor :block
    # create a new validation rule. This is typically a result of
    # calling +must+ so the text should work following the word
    # "must", e.g. "must not be nil", "must be >= 10", etc.
    def initialize(message = 'not be nil', &block)
      @message = message
      @block = block_given? ? block : proc { |x| !self.nil? }
    end
  end

  # place to stash bookkeeping info
  class DoodleInfo
    attr_accessor :local_attributes
    attr_accessor :local_validations
    attr_accessor :local_conversions
    attr_accessor :validation_on
    attr_accessor :arg_order
    attr_accessor :errors
    attr_accessor :doodle_parent

    def initialize(object)
      @local_attributes = OrderedHash.new
      @local_validations = []
      @validation_on = true
      @local_conversions = {}
      @arg_order = []
      @errors = []
      @doodle_parent = nil
    end
    def inspect
      ''
    end
  end

  # what it says on the tin :) various hacks to hide @__doodle__ variable
  module SmokeAndMirrors
    # redefine instance_variables to ignore our private @__doodle__ variable
    # (hack to fool yaml and anything else that queries instance_variables)
    meth = Object.instance_method(:instance_variables)
    define_method :instance_variables do
      meth.bind(self).call.reject{ |x| x.to_s =~ /@__doodle__/}
    end

    # hide @__doodle__ from inspect
    def inspect
      super.gsub(/\s*@__doodle__=,/,'').gsub(/,?\s*@__doodle__=/,'')
    end
  end

  # the core module of Doodle - to get most facilities provided by Doodle
  # without inheriting from Doodle, include Doodle::Core, not this module
  module BaseMethods
    include SelfClass
    include Inherited
    include SmokeAndMirrors

    # this is the only way to get at internal values. Note: this is
    # initialized on the fly rather than in #initialize because
    # classes and singletons don't call #initialize
    def __doodle__
      @__doodle__ ||= DoodleInfo.new(self)
    end
    private :__doodle__

    # helper for Marshal.dump
    def marshal_dump
      # note: perhaps should also dump singleton attribute definitions?
      instance_variables.map{|x| [x, instance_variable_get(x)] }
    end
    # helper for Marshal.load
    def marshal_load(data)
      data.each do |name, value|
        instance_variable_set(name, value)
      end
    end

    # where should I put this?
    def errors
      __doodle__.errors
    end

    # clear out the errors collection
    def clear_errors
      #pp [:clear_errors, self, caller]
      __doodle__.errors.clear
    end
    
    # handle errors either by collecting in :errors or raising an exception
    def handle_error(name, *args)
      # don't include duplicates (FIXME: hacky - shouldn't have duplicates in the first place)
      if !self.errors.include?([name, *args])
        self.errors << [name, *args]
      end
      if Doodle.raise_exception_on_error
        raise(*args)
      end
    end

    def _handle_inherited_hash(tf, method)
      if tf
        collect_inherited(method).inject(OrderedHash.new){ |hash, item|
          hash.merge(OrderedHash[*item])
        }.merge(__send__(method))
      else
        __send__(method)
      end
    end
    private :_handle_inherited_hash
    
    # return attributes defined in instance
    def local_attributes
      __doodle__.local_attributes
    end
    protected :local_attributes

    # returns array of Attributes
    # - if tf == true, returns all inherited attributes
    # - if tf == false, returns only those attributes defined in the current object/class
    def attributes(tf = true)
      results = _handle_inherited_hash(tf, :local_attributes)
      if !kind_of?(Class) && singleton_class.respond_to?(:attributes)
        results = results.merge(singleton_class.attributes)
      end
      results
    end

    # return attributes for class
    def class_attributes(tf = true)
      attrs = OrderedHash.new
      if self.kind_of?(Class)
        attrs = collect_inherited(:class_attributes).inject(OrderedHash.new){ |hash, item|
          hash.merge(OrderedHash[*item])
        }.merge(singleton_class.respond_to?(:attributes) ? singleton_class.attributes : { })
        attrs
      else
        self.class.class_attributes
      end
    end

    # the set of conversions defined in the current class (i.e. without inheritance)
    def local_conversions
      __doodle__.local_conversions
    end
    protected :local_conversions

    # returns hash of conversions
    # - if tf == true, returns all inherited conversions
    # - if tf == false, returns only those conversions defined in the current object/class
    def conversions(tf = true)
      _handle_inherited_hash(tf, :local_conversions)
    end

    # the set of validations defined in the current class (i.e. without inheritance)
    def local_validations
      __doodle__.local_validations
    end
    protected :local_validations

    # returns array of Validations
    # - if tf == true, returns all inherited validations
    # - if tf == false, returns only those validations defined in the current object/class
    def validations(tf = true)
      if tf
        # note: validations are handled differently to attributes and
        # conversions because ~all~ validations apply (so are stored
        # as an array), whereas attributes and conversions are keyed
        # by name and kind respectively, so only the most recent
        # applies
        
        local_validations + collect_inherited(:local_validations)
      else
        local_validations
      end
    end

    # lookup a single attribute by name, searching the singleton class first
    def lookup_attribute(name)
      # (look at singleton attributes first)
      # fixme[this smells like a hack to me]
      if self.class == Class
        class_attributes[name]
      else
        attributes[name]
      end
    end
    private :lookup_attribute

    # either get an attribute value (if no args given) or set it
    # (using args and/or block)
    def getter_setter(name, *args, &block)
      name = name.to_sym
      if block_given? || args.size > 0
        _setter(name, *args, &block)
      else
        _getter(name)
      end
    end
    private :getter_setter

    # get an attribute by name - return default if not otherwise defined
    def _getter(name, &block)
      ivar = "@#{name}"
      if instance_variable_defined?(ivar)
        instance_variable_get(ivar)
      else
        # handle default
        # Note: use :init => value to cover cases where defaults don't work
        # (e.g. arrays that disappear when you go out of scope)
        att = lookup_attribute(name)
        # special case for class/singleton :init
        if att.init_defined?
          _setter(name, att.init)
        elsif att.default_defined?
          case att.default
          when DeferredBlock
            instance_eval(&att.default.block)
          when Proc
            instance_eval(&att.default)
          else
            att.default
          end
        else
          # This is an internal error (i.e. shouldn't happen)
          handle_error name, NoDefaultError, "Error - '#{name}' has no default defined", [caller[-1]]
        end
      end
    end
    private :_getter

    # set an attribute by name - apply validation if defined
    def _setter(name, *args, &block)
      #Doodle::Debug.d { [:_setter, name, args] }
      ivar = "@#{name}"
      if block_given?
        args.unshift(DeferredBlock.new(block))
      end
      if att = lookup_attribute(name)
        #Doodle::Debug.d { [:_setter, name, args] }
        v = instance_variable_set(ivar, att.validate(self, *args))
        #v = instance_variable_set(ivar, *args)
      else
        #Doodle::Debug.d { [:_setter, "no attribute"] }
        v = instance_variable_set(ivar, *args)
      end
      validate!(false)
      v
    end
    private :_setter

    # if block passed, define a conversion from class
    # if no args, apply conversion to arguments
    def from(*args, &block)
      if block_given?
        # set the rule for each arg given
        args.each do |arg|
          local_conversions[arg] = block
        end
      else
        convert(self, *args)
      end
    end

    # add a validation
    def must(message = 'be valid', &block)
      local_validations << Validation.new(message, &block)
    end

    # add a validation that attribute must be of class <= kind
    def kind(*args, &block)
      if args.size > 0
        # todo[figure out how to handle kind being specified twice?]
        @kind = args.first
        local_validations << (Validation.new("be #{@kind}") { |x| x.class <= @kind })
      else
        @kind
      end
    end

    # convert a value according to conversion rules
    def convert(owner, *args)
      begin
        value = args.first
        if (converter = conversions[value.class])
          value = converter[*args]
        else
          # try to find nearest ancestor
          ancestors = value.class.ancestors
          matches = ancestors & conversions.keys
          indexed_matches = matches.map{ |x| ancestors.index(x)}
          if indexed_matches.size > 0
            converter_class = ancestors[indexed_matches.min]
            if converter = conversions[converter_class]
              value = converter[*args]
            end
          end
        end
      rescue Exception => e
        owner.handle_error name, ConversionError, e.to_s, [caller[-1]]
      end
      value
    end

    # validate that args meet rules defined with +must+
    def validate(owner, *args)
      #Doodle::Debug.d { [:validate, self, :owner, owner, :args, args ] }
      # if I bypass convert here, the AR inspect wierdness stops
      # so what is going on?
      #return args.first
      value = convert(owner, *args)
      #return args.first
      validations.each do |v|
        #Doodle::Debug.d { [:validate, self, v, args, value] }
        if !v.block[value]
          owner.handle_error name, ValidationError, "#{ name } must #{ v.message } - got #{ value.class }(#{ value.inspect })", [caller[-1]]
        end
      end
      value
    end

    # define a getter_setter
    def define_getter_setter(name, *args, &block)      
      # need to use string eval because passing block
      sc_eval "def #{name}(*args, &block); getter_setter(:#{name}, *args, &block); end", __FILE__, __LINE__
      sc_eval "def #{name}=(*args, &block); _setter(:#{name}, *args); end", __FILE__, __LINE__

      # this is how it should be done (in 1.9)
      #       module_eval {
      #         define_method name do |*args, &block|
      #           getter_setter(name.to_sym, *args, &block)
      #         end
      #         define_method "#{name}=" do |*args, &block|
      #           _setter(name.to_sym, *args, &block)
      #         end
      #       }
    end
    private :define_getter_setter

    # define a collector
    # - collection should provide a :<< method
    def define_collector(collection, name, klass = nil, &block)
      # need to use string eval because passing block
      if klass.nil?
        sc_eval("def #{name}(*args, &block); args.unshift(block) if block_given?; #{collection}.<<(*args); end", __FILE__, __LINE__)
      else
        sc_eval("def #{name}(*args, &block);
                          if args.all?{|x| x.kind_of?(#{klass})}
                            #{collection}.<<(*args)
                          else
                            #{collection} << #{klass}.new(*args, &block);
                          end
                     end", __FILE__, __LINE__)
      end
    end
    private :define_collector

    # +has+ is an extended +attr_accessor+
    #
    # simple usage - just like +attr_accessor+:
    #
    #  class Event
    #    has :date
    #  end
    #
    # set default value:
    #
    #  class Event
    #    has :date, :default => Date.today
    #  end
    #
    # set lazily evaluated default value:
    #
    #  class Event
    #    has :date do
    #      default { Date.today }
    #    end
    #  end
    #    
    def has(*args, &block)
      Doodle::Debug.d { [:has, self, self.class, args] }
      name = args.shift.to_sym
      # d { [:has2, name, args] }
      key_values, positional_args = args.partition{ |x| x.kind_of?(Hash)}
      handle_error name, ArgumentError, "Too many arguments" if positional_args.size > 0
      params = { :name => name }
      params = key_values.inject(params){ |acc, item| acc.merge(item)}

      # don't pass collector params through to Attribute
      collector_klass = nil
      if collector = params.delete(:collect)
        if !params.key?(:init)
          params[:init] = []
        end
        if collector.kind_of?(Hash)
          collector_name, collector_klass = collector.to_a[0]
        else
          # if Capitalized word given, treat as classname
          # and create collector for specific class
          collector_klass = collector.to_s
          collector_name = Utils.snake_case(collector_klass)
          if collector_klass !~ /^[A-Z]/
            collector_klass = nil
          end
        end
        define_collector name, collector_name, collector_klass
      end
      
      # define getter setter before setting up attribute
      define_getter_setter name, *args, &block
      local_attributes[name] = attribute = Attribute.new(params, &block)
      # if a collector has been defined and has a specific class, then you can pass in an array of hashes
      if collector_klass
        attribute.instance_eval {
          from Enumerable do |enum|
            if !collector_klass.kind_of?(Class)
              tmp_klass = self.class.const_get(collector_klass)
            else
              tmp_klass = collector_klass
            end
            enum.map{|x|
              if x.kind_of?(tmp_klass)
                x
              elsif tmp_klass.conversions.key?(x.class)
                tmp_klass.from(x)
              else
                tmp_klass.new(x)
              end
            }
          end
        }
      end
      attribute
    end

    # define order for positional arguments
    def arg_order(*args)
      if args.size > 0
        begin
          args.uniq!
          args.each do |x|
            handle_error :arg_order, ArgumentError, "#{x} not a Symbol" if !(x.class <= Symbol)
            handle_error :arg_order, NameError, "#{x} not an attribute name" if !attributes.keys.include?(x)
          end
          __doodle__.arg_order = args
        rescue Exception => e
          handle_error :arg_order, InvalidOrderError, e.to_s, [caller[-1]]
        end
      else
        __doodle__.arg_order + (attributes.keys - __doodle__.arg_order)
      end
    end

    def get_init_values(tf = true)
      attributes(tf).select{|n, a| a.init_defined? }.inject({}) {|hash, (n, a)| 
        hash[n] = begin
                    case a.init
                    when NilClass, TrueClass, FalseClass, Fixnum
                      a.init
                    when DeferredBlock
                      instance_eval(&a.init.block)
                    else
                      a.init.clone 
                    end
                  rescue Exception => e
                    a.init
                  end
        ; hash }
    end
    private :get_init_values

    # return true if instance variable +name+ defined
    def ivar_defined?(name)
      instance_variable_defined?("@#{name}")
    end
    private :ivar_defined?

    # validate this object by applying all validations in sequence
    # - if all == true, validate all attributes, e.g. when loaded from YAML, else validate at object level only
    def validate!(all = true)
      #Doodle::Debug.d { [:validate!, all, caller] }
      if all
        clear_errors
      end
      if __doodle__.validation_on
        if self.class == Class
          attribs = class_attributes
          #Doodle::Debug.d { [:validate!, "using class_attributes", class_attributes] }
        else
          attribs = attributes
          #Doodle::Debug.d { [:validate!, "using instance_attributes", attributes] }
        end
        attribs.each do |name, att|
          # treat default as special case
          if att.default_defined?
            #Doodle::Debug.d { [:validate!, "default_defined - breaking" ]}
            break
          end
          ivar_name = "@#{att.name}"
          if instance_variable_defined?(ivar_name)
            # if all == true, reset values so conversions and
            # validations are applied to raw instance variables
            # e.g. when loaded from YAML
            if all
              #Doodle::Debug.d { [:validate!, :sending, att.name, instance_variable_get(ivar_name) ] }
              __send__("#{att.name}=", instance_variable_get(ivar_name))
            end
          elsif self.class != Class
            handle_error name, Doodle::ValidationError, "#{self} missing required attribute '#{name}'", [caller[-1]]
          end
        end
        # now apply instance level validations
        
        #Doodle::Debug.d { [:validate!, "validations", validations ]}
        validations.each do |v|
          #Doodle::Debug.d { [:validate!, self, v ] }
          begin
            if !instance_eval(&v.block)
              handle_error self, ValidationError, "#{ self.class } must #{ v.message }", [caller[-1]]
            end
          rescue Exception => e
            handle_error self, ValidationError, e.to_s, [caller[-1]]
          end
        end
      end
      # if OK, then return self
      self
    end

    # turn off validation, execute block, then set validation to same
    # state as it was before +defer_validation+ was called - can be nested
    def defer_validation(&block)
      old_validation = __doodle__.validation_on
      __doodle__.validation_on = false
      v = nil
      begin
        v = instance_eval(&block)
      ensure
        __doodle__.validation_on = old_validation
      end
      validate!(false)
      v
    end

    # helper function to initialize from hash - this is safe to use
    # after initialization (validate! is called if this method is
    # called after initialization)
    def initialize_from_hash(*args)
      defer_validation do
        # hash initializer
        # separate into array of hashes of form [{:k1 => v1}, {:k2 => v2}] and positional args 
        key_values, args = args.partition{ |x| x.kind_of?(Hash)}
        Doodle::Debug.d { [self.class, :initialize_from_hash, :key_values, key_values, :args, args] }

        # match up positional args with attribute names (from arg_order) using idiom to create hash from array of assocs
        arg_keywords = Hash[*(Utils.flatten_first_level(self.class.arg_order[0...args.size].zip(args)))]

        # set up initial values with ~clones~ of specified values (so not shared between instances)
        init_values = get_init_values

        # add to start of key_values array (so can be overridden by params)
        key_values.unshift(init_values)

        # merge all hash args into one
        key_values = key_values.inject(arg_keywords) { |hash, item| hash.merge(item)}

        # convert key names to symbols
        key_values = key_values.inject({}) {|h, (k, v)| h[k.to_sym] = v; h}
        Doodle::Debug.d { [self.class, :initialize_from_hash, :key_values2, key_values, :args2, args] }
        
        # create attributes
        key_values.keys.each do |key|
          Doodle::Debug.d { [self.class, :initialize_from_hash, :setting, key, key_values[key]] }
          if respond_to?(key)
            __send__(key, key_values[key])
          else
            # raise error if not defined
            handle_error key, Doodle::UnknownAttributeError, "Unknown attribute '#{key}' #{key_values[key].inspect}"
          end
        end
      end
    end
    #private :initialize_from_hash

    # return containing object (set during initialization)
    # (named doodle_parent to avoid clash with ActiveSupport)
    def doodle_parent
      __doodle__.doodle_parent
    end

    # object can be initialized from a mixture of positional arguments,
    # hash of keyword value pairs and a block which is instance_eval'd
    def initialize(*args, &block)
      built_in = Doodle::BuiltIns::BUILTINS.select{ |x| self.kind_of?(x) }.first
      if built_in
        super
      end
      __doodle__.validation_on = true
      __doodle__.doodle_parent = Doodle.context[-1]
      Doodle.context.push(self)
      defer_validation do
        initialize_from_hash(*args)
        instance_eval(&block) if block_given?
      end
      Doodle.context.pop
    end

  end

  # A factory function is a function that has the same name as
  # a class which acts just like class.new. For example:
  #   Cat(:name => 'Ren')
  # is the same as:
  #   Cat.new(:name => 'Ren')
  # As the notion of a factory function is somewhat contentious [xref
  # ruby-talk], you need to explicitly ask for them by including Factory
  # in your base class:
  #   class Base < Doodle::Root
  #     include Factory
  #   end
  #   class Dog < Base
  #   end
  #   stimpy = Dog(:name => 'Stimpy')
  # etc.
  module Factory
    RX_IDENTIFIER = /^[A-Za-z_][A-Za-z_0-9]+\??$/
    class << self
      # create a factory function in appropriate module for the specified class
      def factory(konst)
        name = konst.to_s
        names = name.split(/::/)
        name = names.pop
        if names.empty?
          # top level class - should be available to all
          klass = Object
          method_defined = begin
                             method(name)
                             true
                           rescue
                             false
                           end

          if !method_defined && !klass.respond_to?(name) && !eval("respond_to?(:#{name})", TOPLEVEL_BINDING) && name =~ Factory::RX_IDENTIFIER
            eval("def #{ name }(*args, &block); ::#{name}.new(*args, &block); end", ::TOPLEVEL_BINDING, __FILE__, __LINE__)
          end
        else
          klass = names.inject(self) {|c, n| c.const_get(n)}
          # todo[check how many times this is being called]
          if !klass.respond_to?(name) && name =~ Factory::RX_IDENTIFIER
            klass.module_eval("def self.#{name}(*args, &block); #{name}.new(*args, &block); end", __FILE__, __LINE__)
          end
        end
      end

      # inherit the factory function capability
      def included(other)
        super
        # make +factory+ method available
        factory other
      end
    end
  end

  # Include Doodle::Core if you want to derive from another class
  # but still get Doodle goodness in your class (including Factory
  # methods).
  module Core
    def self.included(other)
      super
      other.module_eval {
        extend Embrace
        embrace BaseMethods
        include Factory
      }
    end
  end
  # deprecated
  Helper = Core

  # deprecated
  class Base
    include Core
  end
  include Core
end

class Doodle
  # Attribute is itself a Doodle object that is created by #has and
  # added to the #attributes collection in an object's DoodleInfo
  #
  # It is used to provide a context for defining #must and #from rules
  #
  class Attribute < Doodle
    # todo[want to design Attribute so it's extensible, e.g. to specific datatypes & built-in validations]
    # must define these methods before using them in #has below

    # hack: bump off +validate!+ for Attributes - maybe better way of doing
    # this however, without this, tries to validate Attribute to :kind
    # specified, e.g. if you have
    #
    #   has :date, :kind => Date
    #
    # it will fail because Attribute is not a kind of Date -
    # obviously, I have to think about this some more :S
    #
    # at least, I could hand roll a custom validate! method for Attribute
    #
    def validate!(all = true)
    end

    # is this attribute optional? true if it has a default defined for it
    def optional?
      default_defined? or init_defined?
    end

    # an attribute is required if it has no default or initial value defined for it
    def required?
      # d { [:default?, self.class, self.name, instance_variable_defined?("@default"), @default] }
      !optional?
    end

    # has default been defined?
    def default_defined?
      ivar_defined?(:default)
    end
    # has default been defined?
    def init_defined?
      ivar_defined?(:init)
    end

    # name of attribute
    has :name, :kind => Symbol do
      from String do |s|
        s.to_sym
      end
    end

    # default value (can be a block)
    has :default, :default => nil

    # initial value
    has :init, :default => nil

  end

end

############################################################
# and we're bootstrapped! :)
############################################################
