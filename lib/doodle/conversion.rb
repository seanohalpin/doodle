class Doodle
  module ConversionHelper
    # if block passed, define a conversion from class
    # if no args, apply conversion to arguments
    def from(*args, &block)
      Doodle::Debug.d { [self, args, block]}
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

    # convert a value according to conversion rules
    # FIXME: move
    def convert(owner, *args)
      #pp( { :convert => 1, :owner => owner, :args => args, :conversions => __doodle__.conversions } )
      begin
        args = args.map do |value|
          #!p [:convert, 2, value]
          if (converter = __doodle__.conversions[value.class])
            #p [:convert, 3, value, self, caller]
            value = converter[value]
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
  end
end
