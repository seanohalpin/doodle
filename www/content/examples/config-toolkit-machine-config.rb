# from http://configtoolkit.rubyforge.org/

require 'configtoolkit'
require 'uri'

#
# This configuration class is nested within MachineConfig (below).
# All configuration classes must descend from ConfigToolkit::BaseConfig.
#
class OSConfig < ConfigToolkit::BaseConfig
  add_required_param(:name, String)
  add_required_param(:version, Float)
end

#
# This configuration class is used in all of the example programs.
# Since it is a configuration class, it descends from
# ConfigToolkit::BaseConfig.
#
class MachineConfig < ConfigToolkit::BaseConfig
  #
  # This is a required parameter with extra user-specified validation
  # (that :num_cpus > 0 must be true)
  #
  add_required_param(:num_cpus, Integer) do |value|
    if(value <= 0)
      raise_error("num_cpus must be greater than zero")
    end
  end

  #
  # This required parameter is itself a BaseConfig instance; BaseConfig
  # instances can be nested within each other.
  #
  #add_required_param(:os, OSConfig)
  add_required_param(:os, String)

  #
  # This is a required boolean parameter.  Note that Ruby does not
  # have a boolean type (it has a TrueClass and a FalseClass), so use
  # a marker class (ConfigToolkit::Boolean) to indicate that
  # the parameter will have boolean values (true and false).
  # Boolean values can be written as "true"/"false" or as
  # "yes"/"no" in configuration files.
  #
  add_required_param(:contains_sensitive_data, ConfigToolkit::Boolean)

  #
  # The behind_firewall parameter is optional and has a default value of
  # true, which means that it will be set to the true if not explicitly set
  # by a configuration file.
  #
  add_optional_param(:behind_firewall, ConfigToolkit::Boolean, true)

  #
  # The primary_contact parameter is optional and has no default value, which
  # means that it will be absent if not explicitly set by a configuration file.
  #
  add_optional_param(:primary_contact, String)

  #
  # This parameter's values are guaranteed to be Arrays with URI elements.
  #
  add_required_param(:addresses, ConfigToolkit::ConstrainedArray.new(URI))

  #
  # This method is called by load() after loading values for
  # all parameters from a specified configuration and can enforce
  # constraints between different parameters.  In this case, this method
  # ensures that all machines containing sensitive data are behind
  # the firewall.
  #
  def validate_all_values
    if(contains_sensitive_data && !behind_firewall)
      raise_error("only machines behind firewalls can contain sensitive data")
    end
  end
end
