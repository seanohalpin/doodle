require 'lib/doodle'

module Workflow
  class Connection < Doodle::Base
    class << self
      def connections
        @connections ||= []
      end
    end
    has :source
    has :role
    has :target
    def initialize(*args, &block)
      super
      self.class.connections << self
    end
    def inspect
      "#{source} #{role} #{target}"
    end
  end
  class Thing < Doodle::Base
    class << self
      # this is not working as I would hope
      #has :counter, :default => 0
      def new_id
        @counter ||= 0
        "%02d" % (@counter += 1).to_s
      end
    end

    has :id, :default => proc { self.class.new_id }
    has :type, :default => proc { self.class.to_s } # ~not~ self.to_s = infinite regress!
    has :name, :default => proc { type.gsub(/.*::/, '') + "#" + id }
    def to_s
      name
    end
    def inspect
      %[#{type}("#{name}")]
    end
    def method_missing(method, *args, &block)
      args.each do |arg|
        Connection.new(self, Role.new(:role => method), arg)
      end
    end
  end
  class Role < Doodle::Base
    has :role, :default => 'has role wrt'
    def inspect
      "has Role #{role} wrt"
    end
    def to_s
      role.to_s
    end
  end

  class Person < Thing
  end

  class Process < Thing
  end

  class Project < Thing
  end

  class Host < Thing
  end

  thing = Thing.new
  person = Person.new
  process = Process.new
  process2 = Process.new
  thing2 = Thing.new

  require 'pp'
  
  puts thing, person, process, process2, thing2

  
  Connection(person, "belongs to", process2)

  Sean = Person("Sean")         # Sean is a Person
  PIT = Project("PIT")
  Nat = Person("Nat")
  Dave = Person("Dave")
  Integration = Host("Integration")
  
  Sean.is_SSE_for PIT
  Sean.manages Nat, Dave

  Sean.deploys(PIT)
  PIT.is_deployed_to(Integration)

  # Sean.deploys PIT, :to => Integration

  # creates a process 'deploy:to'
  # with Subject, Object, IndirectObject

  # Sean.deploys PIT, :to => Integration, :with => Capistrano
  # Sean.deploys PIT, :to => Integration, :using => Capistrano
  # Subject, Object, IndirectObject, Agency
  # Subject, Object, IndirectObject, Instrument

  # Person(:SSE).deploys Project(:PIT), :to => Host(:Integration), :using => Tool(:Capistrano)
  # Person(:SSE).builds RPM(:PIT_setup), :on => Host(:Mock), :using => Tool(:Mock)

  # Person(:Sysadmin).copies RPM(:PIT_setup), :to => Host(:Repo)

  %w[Person[Sean] has Role[SSE] on Project[PIT]]

  %w[Sean is SSE on PIT]
  [:SSE, :builds, :RPM, :on, :Host, "Mock", :using, :Mock]
  [:Sysadmin, :copies, :RPM, :to, :Repository]

  %[SSE builds RPM on Host[Mock] using Mock]
  
  pp Connection.connections

  p %w[SSE builds RPM on Host[Mock] using Mock]
  p %w[role:SSE builds artefact:RPM on host:mock.ips using tool:mock]

  p %w[role[SSE] builds artefact[RPM] on host[mock.ips.radio.bbc.co.uk] as[sudo] using tool[mock]]
  puts %w[role[SSE] builds artefact[RPM] on host[mock.ips.radio.bbc.co.uk] as[sudo] using tool[mock]]

  %[role[SSE] on host[mock] implies account[user, host]]

  %[role[SSE on[host[mock]]] implies[account[user, host]]]

#  Assert(Role(:SSE, :on => Host(:mock)), :implies => Fact(Role(SSE), :has, Account(:on => Host(:mock))))
  
end
