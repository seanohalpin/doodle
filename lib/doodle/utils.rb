# doodle/utils.rb
class Doodle
  # Set of utility functions to avoid monkeypatching base classes
  module Utils
    module ClassMethods
      # unnest arrays by one level of nesting, e.g. [1, [[2], 3]] =>
      # [1, [2], 3].
      def flatten_first_level(enum)
        enum.inject([]) {|arr, i|
          if i.kind_of?(Array)
            arr.push(*i)
          else
            arr.push(i)
          end
        }
      end

      # from facets/string/case.rb, line 80
      def snake_case(camel_cased_word)
        # if all caps, just downcase it
        if camel_cased_word =~ /^[A-Z]+$/
          camel_cased_word.downcase
        else
          camel_cased_word.to_s.gsub(/([A-Z]+)([A-Z])/,'\1_\2').gsub(/([a-z])([A-Z])/,'\1_\2').downcase
        end
      end
      alias :snakecase :snake_case

      # resolve a constant of the form Some::Class::Or::Module -
      # doesn't work with constants defined in anonymous
      # classes/modules
      def const_resolve(constant)
        constant.to_s.split(/::/).reject{|x| x.empty?}.inject(Object) { |prev, this| prev.const_get(this) }
      end

      # deep copy of object (unlike shallow copy dup or clone)
      def deep_copy(obj)
        ::Marshal.load(::Marshal.dump(obj))
      end

      # normalize hash keys using method (e.g. :to_sym, :to_s)
      # - updates target hash
      # - optionally recurse into child hashes
      def normalize_keys!(hash, recursive = false, method = :to_sym)
        if hash.kind_of?(Hash)
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

      # execute block - catch any exceptions and return as value
      def try(&block)
        begin
          block.call
        rescue Exception => e
          e
        end
      end

      # normalize a name to contain only legal characters for a Ruby
      # constant
      def normalize_const(const)
        const.to_s.gsub(/[^A-Za-z_0-9]/, '')
      end

      # lookup a constant along the module nesting path
      def const_lookup(const, context = self)
        #p [:const_lookup, const, context]
        const = Utils.normalize_const(const)
        result = nil
        if !context.kind_of?(Module)
          context = context.class
        end
        klasses = context.to_s.split(/::/)
        #p klasses

        path = []
        0.upto(klasses.size - 1) do |i|
          path << Doodle::Utils.const_resolve(klasses[0..i].join('::'))
        end
        path = (path.reverse + context.ancestors).flatten
        #p [:const, context, path]
        path.each do |ctx|
          #p [:checking, ctx]
          if ctx.const_defined?(const)
            result = ctx.const_get(const)
            break
          end
        end
        raise NameError, "Uninitialized constant #{const} in context #{context}" if result.nil?
        result
      end
    end
    extend ClassMethods
    include ClassMethods
  end
end
