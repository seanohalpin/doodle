#: rubygems
require 'rubygems'
#: requires
require 'doodle'
require 'doodle/datatypes'

class Address < Doodle
  has :value, :kind => URI do
    from String do |s|
      URI.parse(s)
    end
  end
  def to_yaml(*opts)
    value.to_s.to_yaml(*opts)
  end
end

class MachineConfig < Doodle
  doodle do
    string :name
    string :architecture
    string :os
    integer :num_cpus, :kind => Integer do
      must "be greater than zero" do |value|
        value >= 0
      end
    end
    boolean :contains_sensitive_data
    list :addresses, :collect => Address
    boolean :behind_firewall, :default => true

    must "be behind the firewall if it contains sensitive data" do
      !(contains_sensitive_data && !behind_firewall)
    end
  end
end

