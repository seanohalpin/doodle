class Doodle
  module GetterSetter
    # either get an attribute value (if no args given) or set it
    # (using args and/or block)
    # FIXME: move
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
    # FIXME: init deferred blocks are not getting resolved in all cases
    def _getter(name, &block)
      begin
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
      rescue Object => e
        __doodle__.handle_error name, e, e.to_s, Doodle::Utils.doodle_caller
      end
    end
    private :_getter

    def after_update(params)
    end

    # set an instance variable by symbolic name and call after_update if changed
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
    # FIXME: move
    def _setter(name, *args, &block)
      ##DBG: Doodle::Debug.d { [:_setter, name, args] }
      #p [:_setter, name, *args]
      att = __doodle__.lookup_attribute(name)
      if att && __doodle__.validation_on && att.readonly
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
        #p [:_setter, :got_att1, name, ivar, *args]
        v = ivar_set(name, att.validate(self, *args))

        #p [:_setter, :got_att2, name, ivar, :value, v]
        #v = instance_variable_set(ivar, *args)
      else
        #p [:_setter, :no_att, name, *args]
        ##DBG: Doodle::Debug.d { [:_setter, "no attribute"] }
        v = ivar_set(name, *args)
      end
      validate!(false)
      v
    end
    private :_setter

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



  end
end
