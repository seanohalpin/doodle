# 1.8.7+ versions
class Doodle
  class AppendableAttribute
    def define_collector
      # FIXME: don't use eval in 1.9+
      #name = self.name
      #collector_name = self.collector_name
      #collector_class = self.collector_class
      this = self
      if collector_class.nil?
        doodle_owner.sc_eval do
          define_method this.collector_name do |*args, &block|
            collection = send(this.name)
            #p [this.collector_name, 1, this.name, args]
            # unshift the block onto args so not consumed by <<
            #args.unshift(block) if block_given?
            collection.<<(*args, &block)
          end
        end
      else
        doodle_owner.sc_eval do
          define_method this.collector_name do |*args, &block|
            collection = send(this.name)
            #p [this.collector_name, 1, this.name, args]
            #args.unshift(block) if block_given?
            if args.size > 0 and args.all?{|x| x.kind_of?(this.collector_class)}
              collection.<<(*args, &block)
            else
              collection << this.collector_class.new(*args, &block)
              #collection.<<(*args)
            end
          end
        end
      end
    end
  end

  class KeyedAttribute
    def define_collector
      # save ref to self for use in closure
      this = self
      if this.collector_class.nil?
        doodle_owner.sc_eval do
          #p [:defining, this.collector_name]
          define_method this.collector_name do |*args, &block|
            #p [this.collector_name, 1, args]
            collection = send(this.name)
            args.each do |arg|
              collection[arg.send(key)] = arg
            end
          end
        end
      else
        doodle_owner.sc_eval do
          #p [:defining, this.collector_name]
          define_method this.collector_name do |*args, &block|
            #p [this.collector_name, 2, args]
            collection = send(this.name)
            if args.size > 0 and args.all?{|x| x.kind_of?(this.collector_class)}
              args.each do |arg|
                collection[arg.send(this.key)] = arg
              end
            else
              obj = this.collector_class.new(*args, &block)
              collection[obj.send(this.key)] = obj
            end
          end
        end
      end
    end
  end
end
