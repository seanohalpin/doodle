require 'rubygems'
require 'configtoolkit'
require 'configtoolkit/hashreader'
require 'yaml'
require 'pp'

def try(&block)
  begin
    block.call
  rescue Object => e
    e
  end
end

class MachineConfig < ConfigToolkit::BaseConfig
  add_required_param(:name, String)
  add_required_param(:architecture, String)
  add_required_param(:os, String)
  add_required_param(:num_cpus, Integer) do |value|
    if(value <= 0)
      raise_error("num_cpus must be greater than zero")
    end
  end
  add_optional_param(:behind_firewall, ConfigToolkit::Boolean, true)
  add_required_param(:contains_sensitive_data, ConfigToolkit::Boolean)
  add_required_param(:addresses, ConfigToolkit::ConstrainedArray.new(URI, 2, 3))

  def validate_all_values
    if(contains_sensitive_data && !behind_firewall)
      raise_error("a machine cannot contain sensitive data and not be behind the firewall")
    end
  end
end

if __FILE__ == $0

  yaml1 = %[
  name: apple
  architecture: powerpc
  os: AIX
  num_cpus: 32
  behind_firewall: no
  contains_sensitive_data: no
  addresses:
    - http://default.designingpatterns.com
    - http://apple.designingpatterns.com
]

  config1 = YAML::load(yaml1)
  mc1 = MachineConfig.load(ConfigToolkit::HashReader.new(config1))
  pp mc1
  puts mc1.to_yaml

  yaml2 = %[
  name: apple
  architecture: powerpc
  os: AIX
  num_cpus: 32
  behind_firewall: no
  contains_sensitive_data: yes
  addresses:
    - http://default.designingpatterns.com
    - http://apple.designingpatterns.com
]
  config2 = YAML::load(yaml2)
  mc2 = try { MachineConfig.load(ConfigToolkit::HashReader.new(config2)) }
  pp mc2

  pp try {  mc1.contains_sensitive_data = true }
end
