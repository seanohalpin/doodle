require 'json'
require 'pp'

class Doodle
  module JSON
    module InstanceMethods
      def to_json(*a)
        # don't include default values
        values = doodle.keys.reject{|k| default?(k) }.map{ |k, a| [k, send(k)]}
        value_hash = Hash[*Doodle::Utils.flatten_first_level(values)]
        {
          'json_class'   => self.class.name,
          # doodles should be able to load from a hash so this should
          # be sufficient (in most cases)
          # 'data'         => self.to_hash,
          'data' => value_hash,
        }.to_json(*a)
      end
    end
    module ClassMethods
      def json_create(o)
        #pp [:json_create, o]
        const = Doodle::Utils.const_resolve(o['json_class'])
        const.new(o['data'])
      end
      def from_json(src)
        ::JSON::parse(src)
      end
    end
    def self.included(other)
      other.module_eval { include InstanceMethods }
      other.extend(ClassMethods)
    end
  end
  include Doodle::JSON
end
