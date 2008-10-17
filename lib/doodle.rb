# doodle
# -*- mode: ruby; ruby-indent-level: 2; tab-width: 2 -*- vim: sw=2 ts=2
# Copyright (C) 2007-2008 by Sean O'Halpin
# 2007-11-24 first version
# 2008-04-18 latest release 0.0.12
# 2008-05-07 0.1.6
# 2008-05-12 0.1.7
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

if RUBY_VERSION < '1.9.0'
  require 'molic_orderedhash'  # todo[replace this with own (required functions only) version]
else
  # 1.9+ hashes are ordered by default
  class Doodle
    OrderedHash = ::Hash
  end
end

# require Ruby 1.8.6 or higher
if RUBY_VERSION < '1.8.6'
  raise Exception, "Sorry - doodle does not work with versions of Ruby below 1.8.6"
end

#
# instance_exec for ruby 1.8 by Mauricio Fernandez
# http://eigenclass.org/hiki.rb?bounded+space+instance_exec
# thread-safe and handles frozen objects in bounded space
#
# (tag "ruby instance_exec")
#
if !Object.respond_to?(:instance_exec)
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        methods = InstanceExecHelper.instance_methods
        # this in order to make the lookup O(1), and name generation O(n) on the
        # number of nested/concurrent instance_exec calls instead of O(n**2)
        table = Hash[*methods.zip(methods).flatten]
        n += 1 while table.has_key?(mname="__instance_exec#{n}")
      ensure
        Thread.critical = old_critical
      end
      InstanceExecHelper.module_eval{ define_method(mname, &block) }
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
end

require 'yaml'

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
    def parent
      context[-1]
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
        camel_cased_word.to_s.gsub(/([A-Z]+)([A-Z])/,'\1_\2').gsub(/([a-z])([A-Z])/,'\1_\2').downcase
      end
      # resolve a constant of the form Some::Class::Or::Module
      def const_resolve(constant)
        constant.to_s.split(/::/).reject{|x| x.empty?}.inject(Object) { |prev, this| prev.const_get(this) }
      end
      # deep copy of object (unlike shallow copy dup or clone)
      def deep_copy(obj)
        Marshal.load(Marshal.dump(obj))
      end
      # normalize hash keys using method (e.g. :to_sym, :to_s)
      # - updates target hash
      # - optionally recurse into child hashes
      def normalize_keys!(hash, recursive = false, method = :to_sym)
        hash.keys.each do |key|
          normalized_key = key.respond_to?(method) ? key.send(method) : key
          v = hash.delete(key)
          if recursive
            if v.kind_of?(Hash)
              v = normalize_keys!(v, recursive, method)
            elsif v.kind_of?(Array)
              v = v.map{ |x| normalize_keys!(x, recursive, method) }
            end
          end
          hash[normalized_key] = v
        end
        hash
      end
      # normalize hash keys using method (e.g. :to_sym, :to_s)
      # - returns copy of hash
      # - optionally recurse into child hashes
      def normalize_keys(hash, recursive = false, method = :to_sym)
        if recursive
          h = deep_copy(hash)
        else
          h = hash.dup
        end
        normalize_keys!(h, recursive, method)
      end
      # convert keys to symbols
      # - updates target hash in place
      # - optionally recurse into child hashes
      def symbolize_keys!(hash, recursive = false)
        normalize_keys!(hash, recursive, :to_sym)
      end
      # convert keys to symbols
      # - returns copy of hash
      # - optionally recurse into child hashes
      def symbolize_keys(hash, recursive = false)
        normalize_keys(hash, recursive, :to_sym)
      end
      # convert keys to strings
      # - updates target hash in place
      # - optionally recurse into child hashes
      def stringify_keys!(hash, recursive = false)
        normalize_keys!(hash, recursive, :to_s)
      end
      # convert keys to strings
      # - returns copy of hash
      # - optionally recurse into child hashes
      def stringify_keys(hash, recursive = false)
        normalize_keys(hash, recursive, :to_s)
      end
      # simple (!) pluralization - if you want fancier, override this method
      def pluralize(string)
        s = string.to_s
        if s =~ /s$/
          s + 'es'
        else
          s + 's'
        end
      end

      # caller
      def doodle_caller
        if $DEBUG
          caller
        else
          [caller[-1]]
        end
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
  # raised when try to set a readonly attribute after initialization
  class ReadOnlyError < Exception
  end

  # provides more direct access to the singleton class and a way to
  # treat singletons, Modules and Classes equally in a meta context
  module SelfClass
    # return the 'singleton class' of an object, optionally executing
    # a block argument in the (module/class) context of that object
    def singleton_class(&block)
      sc = class << self; self; end
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

  # = embrace
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
          #super(klass) if defined?(super)
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
    def call(*a, &b)
      block.call(*a, &b)
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
    attr_accessor :this
    attr_accessor :local_attributes
    attr_accessor :local_validations
    attr_accessor :local_conversions
    attr_accessor :validation_on
    attr_accessor :arg_order
    attr_accessor :errors
    attr_accessor :parent

    def initialize(object)
      @this = object
      @local_attributes = Doodle::OrderedHash.new
      @local_validations = []
      @validation_on = true
      @local_conversions = {}
      @arg_order = []
      @errors = []
      #@parent = nil
      @parent = Doodle.parent
    end
    # hide from inspect
    m = instance_method(:inspect)
    define_method :__inspect__ do
      m.bind(self).call
    end
    def inspect
      ''
    end

    # handle errors either by collecting in :errors or raising an exception
    def handle_error(name, *args)
      # don't include duplicates (FIXME: hacky - shouldn't have duplicates in the first place)
      if !errors.include?([name, *args])
        errors << [name, *args]
      end
      if Doodle.raise_exception_on_error
        raise(*args)
      end
    end

    # provide an alternative inheritance chain that works for singleton
    # classes as well as modules, classes and instances
    def parents
      anc = if @this.respond_to?(:ancestors)
              if @this.ancestors.include?(@this)
                @this.ancestors[1..-1]
              else
                # singletons have no doodle_parents (they're orphans)
                []
              end
            else
              @this.class.ancestors
            end
      anc.select{|x| x.kind_of?(Class)}
    end

    # send message to all doodle_parents and collect results
    def collect_inherited(message)
      result = []
      parents.each do |klass|
        if klass.respond_to?(:doodle) && klass.doodle.respond_to?(message)
          result.unshift(*klass.doodle.__send__(message))
        else
          break
        end
      end
      result
    end

    def handle_inherited_hash(tf, method)
      if tf
        collect_inherited(method).inject(Doodle::OrderedHash.new){ |hash, item|
          hash.merge(Doodle::OrderedHash[*item])
        }.merge(@this.doodle.__send__(method))
      else
        @this.doodle.__send__(method)
      end
    end

    # returns array of Attributes
    # - if tf == true, returns all inherited attributes
    # - if tf == false, returns only those attributes defined in the current object/class
    def attributes(tf = true)
      results = handle_inherited_hash(tf, :local_attributes)
      # if an instance, include the singleton_class attributes
      if !@this.kind_of?(Class) && @this.singleton_class.doodle.respond_to?(:attributes)
        results = results.merge(@this.singleton_class.doodle.attributes)
      end
      results
    end

    # return class level attributes
    def class_attributes
      attrs = Doodle::OrderedHash.new
      if @this.kind_of?(Class)
        attrs = collect_inherited(:class_attributes).inject(Doodle::OrderedHash.new){ |hash, item|
          hash.merge(Doodle::OrderedHash[*item])
        }.merge(@this.singleton_class.doodle.respond_to?(:attributes) ? @this.singleton_class.doodle.attributes : { })
        attrs
      else
        @this.class.doodle.class_attributes
      end
    end

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

    def lookup_attribute(name)
      # (look at singleton attributes first)
      # fixme[this smells like a hack to me]
      if @this.class == Class
        class_attributes[name]
      else
        attributes[name]
      end
    end

    # returns hash of conversions
    # - if tf == true, returns all inherited conversions
    # - if tf == false, returns only those conversions defined in the current object/class
    def conversions(tf = true)
      handle_inherited_hash(tf, :local_conversions)
    end

    def initial_values(tf = true)
      attributes(tf).select{|n, a| a.init_defined? }.inject({}) {|hash, (n, a)|
        #p [:initial_values, a.name]
        hash[n] = case a.init
                  when NilClass, TrueClass, FalseClass, Fixnum, Float, Bignum, Symbol
                    # uncloneable values
                    #p [:initial_values, :special, a.name, a.init]
                    a.init
                  when DeferredBlock
                    #p [:initial_values, self, DeferredBlock, a.name]
                    begin
                      @this.instance_eval(&a.init.block)
                    rescue Object => e
                      #p [:exception_in_deferred_block, e]
                      raise
                    end
                  else
                    #p [:initial_values, :clone, a.name]
                    begin
                      a.init.clone
                    rescue Exception => e
                      warn "tried to clone #{a.init.class} in :init option (#{e})"
                      #p [:initial_values, :exception, a.name, e]
                      a.init
                    end
                  end
        hash
      }
    end

    # turn off validation, execute block, then set validation to same
    # state as it was before +defer_validation+ was called - can be nested
    def defer_validation(&block)
      old_validation = self.validation_on
      self.validation_on = false
      v = nil
      begin
        v = @this.instance_eval(&block)
      ensure
        self.validation_on = old_validation
      end
      @this.validate!(false)
      v
    end

    # helper function to initialize from hash - this is safe to use
    # after initialization (validate! is called if this method is
    # called after initialization)
    def initialize_from_hash(*args)
      # p [:doodle_initialize_from_hash, :args, *args]
      defer_validation do
        # hash initializer
        # separate into array of hashes of form [{:k1 => v1}, {:k2 => v2}] and positional args
        key_values, args = args.partition{ |x| x.kind_of?(Hash)}
        #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :key_values, key_values, :args, args] }
        #!p [self.class, :doodle_initialize_from_hash, :key_values, key_values, :args, args]

        # set up initial values with ~clones~ of specified values (so not shared between instances)
        #init_values = initial_values
        #!p [:init_values, init_values]

        # match up positional args with attribute names (from arg_order) using idiom to create hash from array of assocs
        #arg_keywords = init_values.merge(Hash[*(Utils.flatten_first_level(self.class.arg_order[0...args.size].zip(args)))])
        arg_keywords = Hash[*(Utils.flatten_first_level(self.class.arg_order[0...args.size].zip(args)))]
        #!p [self.class, :doodle_initialize_from_hash, :arg_keywords, arg_keywords]

        # merge all hash args into one
        key_values = key_values.inject(arg_keywords) { |hash, item|
          #!p [self.class, :doodle_initialize_from_hash, :merge, hash, item]
          hash.merge(item)
        }
        #!p [self.class, :doodle_initialize_from_hash, :key_values2, key_values]

        # convert keys to symbols (note not recursively - only first level == doodle keywords)
        Doodle::Utils.symbolize_keys!(key_values)
        #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :key_values2, key_values, :args2, args] }
        #!p [self.class, :doodle_initialize_from_hash, :key_values3, key_values]

        # create attributes
        key_values.keys.each do |key|
          #DBG: Doodle::Debug.d { [self.class, :doodle_initialize_from_hash, :setting, key, key_values[key]] }
          #p [self.class, :doodle_initialize_from_hash, :setting, key, key_values[key]]
          if respond_to?(key)
            __send__(key, key_values[key])
          else
            # raise error if not defined
            __doodle__.handle_error key, Doodle::UnknownAttributeError, "unknown attribute '#{key}' => #{key_values[key].inspect} for #{self} #{doodle.attributes.map{ |k,v| k.inspect}.join(', ')}", Doodle::Utils.doodle_caller
          end
        end
        # do init_values after user supplied values so init blocks can depend on user supplied values
        #p [:getting_init_values, instance_variables]
        __doodle__.initial_values.each do |key, value|
          if !key_values.key?(key) && respond_to?(key)
            #p [:initial_values, key, value]
            __send__(key, value)
          end
        end
      end
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
    # fix for pp
    def pretty_print(q)
      q.pp_object(self)
    end
  end

  # implements the #doodle directive
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
    def has(*args, &block)
      @klass.class_eval { has(*args, &block) }
    end
    def must(*args, &block)
      @klass.class_eval { must(*args, &block) }
    end
    def from(*args, &block)
      @klass.class_eval { from(*args, &block) }
    end
    def arg_order(*args, &block)
      @klass.class_eval { arg_order(*args, &block) }
    end
    def doc(*args, &block)
      @klass.class_eval { doc(*args, &block) }
    end
  end

  # the core module of Doodle - however, to get most facilities
  # provided by Doodle without inheriting from Doodle, include
  # Doodle::Core, not this module
  module BaseMethods
    include SelfClass
    include SmokeAndMirrors

    # this is the only way to get at internal values. Note: this is
    # initialized on the fly rather than in #initialize because
    # classes and singletons don't call #initialize
    def __doodle__
      @__doodle__ ||= DoodleInfo.new(self)
    end
    protected :__doodle__

    # set up global datatypes
    def datatypes(*mods)
      mods.each do |mod|
        DataTypeHolder.class_eval { include mod }
      end
    end

    # vector through this method to get to doodle info or enable global
    # datatypes and provide an interface that allows you to add your own
    # datatypes to this declaration
    def doodle(*mods, &block)
      if mods.size == 0 && !block_given?
        __doodle__
      else
        dh = Doodle::DataTypeHolder.new(self)
        mods.each do |mod|
          dh.extend(mod)
        end
        dh.instance_eval(&block)
      end
    end

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

    # either get an attribute value (if no args given) or set it
    # (using args and/or block)
    # fixme: move
    def getter_setter(name, *args, &block)
      #p [:getter_setter, name]
      name = name.to_sym
      if block_given? || args.size > 0
        #!p [:getter_setter, :setter, name, *args]
        _setter(name, *args, &block)
      else
        #!p [:getter_setter, :getter, name]
        _getter(name)
      end
    end
    private :getter_setter

    # get an attribute by name - return default if not otherwise defined
    # fixme: init deferred blocks are not getting resolved in all cases
    def _getter(name, &block)
      #p [:_getter, name]
      ivar = "@#{name}"
      if instance_variable_defined?(ivar)
        #p [:_getter, :instance_variable_defined, name, ivar, instance_variable_get(ivar)]
        instance_variable_get(ivar)
      else
        # handle default
        # Note: use :init => value to cover cases where defaults don't work
        # (e.g. arrays that disappear when you go out of scope)
        att = __doodle__.lookup_attribute(name)
        # special case for class/singleton :init
        if att && att.optional?
          optional_value = att.init_defined? ? att.init : att.default
          #p [:optional_value, optional_value]
          case optional_value
          when DeferredBlock
            #p [:deferred_block]
            v = instance_eval(&optional_value.block)
          when Proc
            v = instance_eval(&optional_value)
          else
            v = optional_value
          end
          if att.init_defined?
            _setter(name, v)
          end
          v
        else
          # This is an internal error (i.e. shouldn't happen)
          __doodle__.handle_error name, NoDefaultError, "'#{name}' has no default defined", Doodle::Utils.doodle_caller
        end
      end
    end
    private :_getter

    def after_update(params)
    end

    def ivar_set(name, *args)
      ivar = "@#{name}"
      if instance_variable_defined?(ivar)
        old_value = instance_variable_get(ivar)
      else
        old_value = nil
      end
      instance_variable_set(ivar, *args)
      new_value = instance_variable_get(ivar)
      if new_value != old_value
        #pp [Doodle, :after_update, { :instance => self, :name => name, :old_value => old_value, :new_value => new_value }]
        after_update :instance => self, :name => name, :old_value => old_value, :new_value => new_value
      end
    end
    private :ivar_set

    # set an attribute by name - apply validation if defined
    # fixme: move
    def _setter(name, *args, &block)
      ##DBG: Doodle::Debug.d { [:_setter, name, args] }
      #p [:_setter, name, *args]
      #ivar = "@#{name}"
      att = __doodle__.lookup_attribute(name)
      if att && doodle.validation_on && att.readonly
        raise Doodle::ReadOnlyError, "Trying to set a readonly attribute: #{att.name}", Doodle::Utils.doodle_caller
      end
      if block_given?
        # if a class has been defined, let's assume it can take a
        # block initializer (test that it's a Doodle or Proc)
        if att.kind && !att.abstract && klass = att.kind.first
          if [Doodle, Proc].any?{ |c| klass <= c }
            # p [:_setter, '# 1 converting arg to value with kind ' + klass.to_s]
            args = [klass.new(*args, &block)]
          else
            __doodle__.handle_error att.name, ArgumentError, "#{klass} #{att.name} does not take a block initializer", Doodle::Utils.doodle_caller
          end
        else
          # this is used by init do ... block
          args.unshift(DeferredBlock.new(block))
        end
        #elsif
      end
      if att # = __doodle__.lookup_attribute(name)
        if att.kind && !att.abstract && klass = att.kind.first
          if !args.first.kind_of?(klass) && [Doodle].any?{ |c| klass <= c }
            #p [:_setter, "#2 converting arg #{att.name} to value with kind #{klass.to_s}"]
            #p [:_setter, args]
            begin
              args = [klass.new(*args, &block)]
            rescue Object => e
              __doodle__.handle_error att.name, e.class, e.to_s, Doodle::Utils.doodle_caller
            end
          end
        end
        #  args = [klass.new(*args, &block)]        ##DBG: Doodle::Debug.d { [:_setter, name, args] }
        #p [:_setter, :got_att1, name, ivar, *args]
        #        v = instance_variable_set(ivar, att.validate(self, *args))
        v = ivar_set(name, att.validate(self, *args))

        #p [:_setter, :got_att2, name, ivar, :value, v]
        #v = instance_variable_set(ivar, *args)
      else
        #p [:_setter, :no_att, name, *args]
        ##DBG: Doodle::Debug.d { [:_setter, "no attribute"] }
        #        v = instance_variable_set(ivar, *args)
        v = ivar_set(name, *args)
      end
      validate!(false)
      v
    end
    private :_setter

    # if block passed, define a conversion from class
    # if no args, apply conversion to arguments
    def from(*args, &block)
      #p [:from, self, args]
      if block_given?
        # set the rule for each arg given
        args.each do |arg|
          __doodle__.local_conversions[arg] = block
        end
      else
        convert(self, *args)
      end
    end

    # add a validation
    def must(constraint = 'be valid', &block)
      if block.nil?
        # is this really useful? do I really want it?
        __doodle__.local_validations << Validation.new(constraint, &proc { |v| v.instance_eval(constraint) })
      else
        __doodle__.local_validations << Validation.new(constraint, &block)
      end
    end

    # add a validation that attribute must be of class <= kind
    def kind(*args, &block)
      if args.size > 0
        @kind = [args].flatten
        # todo[figure out how to handle kind being specified twice?]
        if @kind.size > 2
          kind_text = "be a kind of #{ @kind[0..-2].map{ |x| x.to_s }.join(', ') } or #{@kind[-1].to_s}" # =>
        else
          kind_text = "be a kind of #{@kind.to_s}"
        end
        __doodle__.local_validations << (Validation.new(kind_text) { |x| @kind.any? { |klass| x.kind_of?(klass) } })
      else
        @kind ||= []
      end
    end

    # convert a value according to conversion rules
    # fixme: move
    def convert(owner, *args)
      #pp( { :convert => 1, :owner => owner, :args => args, :conversions => __doodle__.conversions } )
      begin
        args = args.map do |value|
          #!p [:convert, 2, value]
          if (converter = __doodle__.conversions[value.class])
            #p [:convert, 3, value, self, caller]
            value = converter[value]
            #value = instance_exec(value, &converter)
            #!p [:convert, 4, value]
          else
            #!p [:convert, 5, value]
            # try to find nearest ancestor
            this_ancestors = value.class.ancestors
            #!p [:convert, 6, this_ancestors]
            matches = this_ancestors & __doodle__.conversions.keys
            #!p [:convert, 7, matches]
            indexed_matches = matches.map{ |x| this_ancestors.index(x)}
            #!p [:convert, 8, indexed_matches]
            if indexed_matches.size > 0
              #!p [:convert, 9]
              converter_class = this_ancestors[indexed_matches.min]
              #!p [:convert, 10, converter_class]
              if converter = __doodle__.conversions[converter_class]
                #!p [:convert, 11, converter]
                value = converter[value]
                #value = instance_exec(value, &converter)
                #!p [:convert, 12, value]
              end
            else
              #!p [:convert, 13, :kind, kind, name, value]
              mappable_kinds = kind.select{ |x| x <= Doodle::Core }
              #!p [:convert, 13.1, :kind, kind, mappable_kinds]
              if mappable_kinds.size > 0
                mappable_kinds.each do |mappable_kind|
                  #!p [:convert, 14, :kind_is_a_doodle, value.class, mappable_kind, mappable_kind.doodle.conversions, args]
                  if converter = mappable_kind.doodle.conversions[value.class]
                    #!p [:convert, 15, value, mappable_kind, args]
                    value = converter[value]
                    #value = instance_exec(value, &converter)
                    break
                  else
                    #!p [:convert, 16, :no_conversion_for, value.class]
                  end
                end
              else
                #!p [:convert, 17, :kind_has_no_conversions]
              end
            end
          end
          #!p [:convert, 18, value]
          value
        end
      rescue Exception => e
        owner.__doodle__.handle_error name, ConversionError, "#{e.message}", Doodle::Utils.doodle_caller
      end
      if args.size > 1
        args
      else
        args.first
      end
    end

    # validate that args meet rules defined with +must+
    # fixme: move
    def validate(owner, *args)
      ##DBG: Doodle::Debug.d { [:validate, self, :owner, owner, :args, args ] }
      #p [:validate, 1, args]
      begin
        value = convert(owner, *args)
      rescue Exception => e
        owner.__doodle__.handle_error name, ConversionError, "#{owner.kind_of?(Class) ? owner : owner.class}.#{ name } - #{e.message}", Doodle::Utils.doodle_caller
      end
      #p [:validate, 2, args, :becomes, value]
      __doodle__.validations.each do |v|
        ##DBG: Doodle::Debug.d { [:validate, self, v, args, value] }
        if !v.block[value]
          owner.__doodle__.handle_error name, ValidationError, "#{owner.kind_of?(Class) ? owner : owner.class}.#{ name } must #{ v.message } - got #{ value.class }(#{ value.inspect })", Doodle::Utils.doodle_caller
        end
      end
      #p [:validate, 3, value]
      value
    end

    # define a getter_setter
    # fixme: move
    def define_getter_setter(name, params = { }, &block)
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

    # +doc+ add docs to doodle class or attribute
    def doc(*args, &block)
      if args.size > 0
        @doc = *args
      else
        @doc
      end
    end
    alias :doc= :doc

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
      #DBG: Doodle::Debug.d { [:has, self, self.class, args] }

      params = DoodleAttribute.params_from_args(self, *args)
      # get specialized attribute class or use default
      attribute_class = params.delete(:using) || DoodleAttribute

      # could this be handled in DoodleAttribute?
      # define getter setter before setting up attribute
      define_getter_setter params[:name], params, &block
      #p [:attribute, attribute_class, params]
      attr = __doodle__.local_attributes[params[:name]] = attribute_class.new(params, &block)
    end

    # define order for positional arguments
    def arg_order(*args)
      if args.size > 0
        begin
          args = args.uniq
          args.each do |x|
            __doodle__.handle_error :arg_order, ArgumentError, "#{x} not a Symbol", Doodle::Utils.doodle_caller if !(x.class <= Symbol)
            __doodle__.handle_error :arg_order, NameError, "#{x} not an attribute name", Doodle::Utils.doodle_caller if !doodle.attributes.keys.include?(x)
          end
          __doodle__.arg_order = args
        rescue Exception => e
          __doodle__.handle_error :arg_order, InvalidOrderError, e.to_s, Doodle::Utils.doodle_caller
        end
      else
        __doodle__.arg_order + (__doodle__.attributes.keys - __doodle__.arg_order)
      end
    end

    # return true if instance variable +name+ defined
    # fixme: move
    def ivar_defined?(name)
      instance_variable_defined?("@#{name}")
    end
    private :ivar_defined?

    # validate this object by applying all validations in sequence
    # - if all == true, validate all attributes, e.g. when loaded from YAML, else validate at object level only
    def validate!(all = true)
      ##DBG: Doodle::Debug.d { [:validate!, all, caller] }
      if all
        __doodle__.errors.clear
      end
      if __doodle__.validation_on
        if self.class == Class
          attribs = __doodle__.class_attributes
          ##DBG: Doodle::Debug.d { [:validate!, "using class_attributes", class_attributes] }
        else
          attribs = __doodle__.attributes
          ##DBG: Doodle::Debug.d { [:validate!, "using instance_attributes", doodle.attributes] }
        end
        attribs.each do |name, att|
          ivar_name = "@#{att.name}"
          if instance_variable_defined?(ivar_name)
            # if all == true, reset values so conversions and
            # validations are applied to raw instance variables
            # e.g. when loaded from YAML
            if all && !att.readonly
              ##DBG: Doodle::Debug.d { [:validate!, :sending, att.name, instance_variable_get(ivar_name) ] }
              __send__("#{att.name}=", instance_variable_get(ivar_name))
            end
          elsif att.optional?   # treat default/init as special case
            ##DBG: Doodle::Debug.d { [:validate!, :optional, name ]}
            next
          elsif self.class != Class
            __doodle__.handle_error name, Doodle::ValidationError, "#{self} missing required attribute '#{name}'", Doodle::Utils.doodle_caller
          end
        end

        # now apply instance level validations

        ##DBG: Doodle::Debug.d { [:validate!, "validations", doodle_validations ]}
        __doodle__.validations.each do |v|
          ##DBG: Doodle::Debug.d { [:validate!, self, v ] }
          begin
            if !instance_eval(&v.block)
              __doodle__.handle_error self, ValidationError, "#{ self.class } must #{ v.message }", Doodle::Utils.doodle_caller
            end
          rescue Exception => e
            __doodle__.handle_error self, ValidationError, e.to_s, Doodle::Utils.doodle_caller
          end
        end
      end
      # if OK, then return self
      self
    end

    # object can be initialized from a mixture of positional arguments,
    # hash of keyword value pairs and a block which is instance_eval'd
    def initialize(*args, &block)
      built_in = Doodle::BuiltIns::BUILTINS.select{ |x| self.kind_of?(x) }.first
      if built_in
        super
      end
      __doodle__.validation_on = true
      #p [:doodle_parent, Doodle.parent, caller[-1]]
      Doodle.context.push(self)
      __doodle__.defer_validation do
        doodle.initialize_from_hash(*args)
        instance_eval(&block) if block_given?
      end
      Doodle.context.pop
      #p [:doodle, __doodle__.__inspect__]
      #p [:doodle, __doodle__.attributes]
      #p [:doodle_parent, __doodle__.parent]
    end

    # create 'pure' hash of scalars only from attributes - hacky but works fine
    def to_hash
      Doodle::Utils.symbolize_keys!(YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }, true)
      #begin
      #  YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }
      #rescue Object => e
      #  doodle.attributes.inject({}) {|hash, (name, attribute)| hash[name] = send(name); hash}
      #end
    end
    def to_string_hash
      Doodle::Utils.stringify_keys!(YAML::load(to_yaml.gsub(/!ruby\/object:.*$/, '')) || { }, true)
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
  #   class Animal < Doodle
  #     include Factory
  #   end
  #   class Dog < Animal
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
                           rescue Object
                             false
                           end

          if name =~ Factory::RX_IDENTIFIER && !method_defined && !klass.respond_to?(name) && !eval("respond_to?(:#{name})", TOPLEVEL_BINDING)
            eval("def #{ name }(*args, &block); ::#{name}.new(*args, &block); end", ::TOPLEVEL_BINDING, __FILE__, __LINE__)
          end
        else
          klass = names.inject(self) {|c, n| c.const_get(n)}
          # todo[check how many times this is being called]
          if name =~ Factory::RX_IDENTIFIER && !klass.respond_to?(name)
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

  # wierd 1.9 shit
  class IAmNotUsedBut1_9GoesIntoAnInfiniteRegressInInspectIfIAmNotDefined
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
  class DoodleAttribute < Doodle
    # note: using extend with a module causes an infinite loop in 1.9
    # hence the inline

    class << self
      # rewrite rules for the argument list to #has
      def params_from_args(owner, *args)
        key_values, positional_args = args.partition{ |x| x.kind_of?(Hash)}
        params = { }
        if positional_args.size > 0
          name = positional_args.shift
          case name
            # has Person --> has :person, :kind => Person
          when Class
            params[:name] = Utils.snake_case(name.to_s.split(/::/).last)
            params[:kind] = name
          else
            params[:name] = name.to_s.to_sym
          end
        end
        params = key_values.inject(params){ |acc, item| acc.merge(item)}
        #DBG: Doodle::Debug.d { [:has, self, self.class, params] }
        if !params.key?(:name)
          __doodle__.handle_error name, ArgumentError, "#{self.class} must have a name", Doodle::Utils.doodle_caller
          params[:name] = :__ERROR_missing_name__
        else
          # ensure that :name is a symbol
          params[:name] = params[:name].to_sym
        end
        name = params[:name]
        __doodle__.handle_error name, ArgumentError, "#{self.class} has too many arguments", Doodle::Utils.doodle_caller if positional_args.size > 0

        if collector = params.delete(:collect)
          if !params.key?(:using)
            if params.key?(:key)
              params[:using] = KeyedAttribute
            else
              params[:using] = AppendableAttribute
            end
          end
          # this in generic CollectorAttribute class
          # collector from(Hash)
          if collector.kind_of?(Hash)
            collector_name, collector_class = collector.to_a[0]
          else
            # if Capitalized word given, treat as classname
            # and create collector for specific class
            collector_class = collector.to_s
            #p [:collector_klass, collector_klass]
            collector_name = Utils.snake_case(collector_class.split(/::/).last)
            #p [:collector_name, collector_name]
            if collector_class !~ /^[A-Z]/
              collector_class = nil
            end
            #!p [:collector_klass, collector_klass, params[:init]]
          end
          params[:collector_class] = collector_class
          params[:collector_name] = collector_name
        end
        params[:doodle_owner] = owner
        #p [:params, owner, params]
        params
      end
    end

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

    # has default been defined?
    def default_defined?
      ivar_defined?(:default)
    end

    # has default been defined?
    def init_defined?
      ivar_defined?(:init)
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

    # special case - not an attribute
    define_getter_setter :doodle_owner

    # temporarily fake existence of abstract attribute - later has
    # :abstract overrides this
    def abstract
      @abstract = false
    end
    def readonly
      false
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

    # documentation
    has :doc, :default => ""

    # don't try to initialize from this class
    remove_method(:abstract) # because we faked it earlier - remove to avoid redefinition warning
    has :abstract, :default => false
    remove_method(:readonly) # because we faked it earlier - remove to avoid redefinition warning
    has :readonly, :default => false
  end

  # base class for attribute collector classes
  class AttributeCollector < DoodleAttribute
    has :collector_class
    has :collector_name

    def resolve_collector_class
      if !collector_class.kind_of?(Class)
        self.collector_class = Doodle::Utils.const_resolve(collector_class)
      end
    end
    def resolve_value(value)
      if value.kind_of?(collector_class)
        value
      elsif collector_class.__doodle__.conversions.key?(value.class)
        collector_class.from(value)
      else
        collector_class.new(value)
      end
    end
    def initialize(*args, &block)
      super
      define_collection
      from Hash do |hash|
        resolve_collector_class
        hash.inject(self.init.clone) do |h, (key, value)|
          h[key] = resolve_value(value)
          h
        end
      end
      from Enumerable do |enum|
        resolve_collector_class
        post_process( enum.map{ |value| resolve_value(value) } )
      end
    end
    def post_process(results)
      self.init.clone.replace(results)
    end
  end

  class DoodleArray < Array
    def after_update(params)
      p [self.class, :after_update]
    end
    def <<(*a, &b)
      p [self.class, :<<]
      old_value = self.clone
      rv = super
      after_update :instance => self, :new_value => a
      rv
    end
  end
  class DoodleHash < Hash
    def after_update(params)
      p [self.class, :after_update]
    end
    def []=(*a, &b)
      p [self.class, :[]=]
      old_value = self.clone
      rv = super
      after_update :instance => self, :new_value => a
      rv
    end
  end

  # define collector methods for array-like attribute collectors
  class AppendableAttribute < AttributeCollector
    #    has :init, :init => DoodleArray.new
    has :init, :init => []

    # define a collector for appendable collections
    # - collection should provide a :<< method
    def define_collection
      if collector_class.nil?
        doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                   junk = #{name} if !#{name} # force initialization for classes
                   args.unshift(block) if block_given?
                   #{name}.<<(*args);
                 end", __FILE__, __LINE__)
      else
        doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                          junk = #{name} if !#{name} # force initialization for classes
                          if args.size > 0 and args.all?{|x| x.kind_of?(#{collector_class})}
                            #{name}.<<(*args)
                          else
                            #{name} << #{collector_class}.new(*args, &block)
                          end
                        end", __FILE__, __LINE__)
      end
    end

  end

  # define collector methods for hash-like attribute collectors
  class KeyedAttribute < AttributeCollector
    #    has :init, :init => DoodleHash.new
    has :init, :init => { }
    has :key

    def post_process(results)
      results.inject(self.init.clone) do |h, result|
        h[result.send(key)] = result
        h
      end
    end

    # define a collector for keyed collections
    # - collection should provide a :[] method
    def define_collection
      # need to use string eval because passing block
      if collector_class.nil?
        doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                   junk = #{name} if !#{name} # force initialization for classes
                   args.each do |arg|
                     #{name}[arg.send(:#{key})] = arg
                   end
                 end", __FILE__, __LINE__)
      else
        doodle_owner.sc_eval("def #{collector_name}(*args, &block)
                          junk = #{name} if !#{name} # force initialization for classes
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

############################################################
# and we're bootstrapped! :)
############################################################
