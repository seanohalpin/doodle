class Doodle
  # two doodles of the same class with the same attribute values are
  # considered equal
  module Equality
    def eql?(o)
      #       p [:comparing, self.class, o.class, self.class == o.class]
      #       p [:values, self.doodle.values, o.doodle.values, self.doodle.values == o.doodle.values]
      #       p [:attributes, doodle.attributes.map { |k, a| [k, send(k).==(o.send(k))] }]
      res = self.class == o.class &&
        #self.doodle.values == o.doodle.values
        # short circuit comparison
        doodle.attributes.all? { |k, a| send(k).==(o.send(k)) }
      #       p [:res, res]
      res
    end
    def ==(o)
      eql?(o)
    end
    def hash
      doodle.key_values_without_defaults.hash
    end
  end
end

