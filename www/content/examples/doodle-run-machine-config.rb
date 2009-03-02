#:requires
require 'doodle-machine-config'
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

#:mc1-yaml
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

#:mc1-use
mc1 = MachineConfig(YAML::load(yaml1))
pp mc1

#:noinclude
#   yaml1b = mc1.to_yaml
#   puts yaml1b
#   mc1b = YAML::load(yaml1b).validate!
#   pp mc1b

#   yaml1c = mc1.to_hash.to_yaml
#   puts yaml1c
#   mc1c = MachineConfig(YAML::load(yaml1c))
#   pp mc1c

#:mc2-yaml
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

#:mc2-use
mc2 = try { MachineConfig(YAML::load(yaml2)) }
pp mc2

#:mc1-validation
pp try {  mc1.contains_sensitive_data = true }
