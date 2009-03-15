#:requires

require 'configtoolkit'
require 'configtoolkit/hashreader'
require 'config-toolkit-machine-config'
require 'yaml'
require 'pp'

#:try
def try(&block)
  begin
    block.call
  rescue Object => e
    e
  end
end

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

yaml2 = %[
  name: apple
  architecture: powerpc
  os: AIX
  num_cpus: 32
  behind_firewall: no
  contains_sensitive_data: yes
  addresses:
#    - a bad uri
    - http://default.designingpatterns.com
    - http://apple.designingpatterns.com
]
config2 = YAML::load(yaml2)
mc2 = try { MachineConfig.load(ConfigToolkit::HashReader.new(config2)) }
pp mc2

#:mc1-validation
pp try {  mc1.contains_sensitive_data = true }
