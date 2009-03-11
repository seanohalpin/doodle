# doodle
# -*- mode: ruby; ruby-indent-level: 2; tab-width: 2 -*- vim: sw=2 ts=2
# Copyright (C) 2007-2009 by Sean O'Halpin
# 2007-11-24 first version
# 2008-04-18 latest release 0.0.12
# 2008-05-07 0.1.6
# 2008-05-12 0.1.7
# 2009-02-26 0.2.0
# require Ruby 1.8.6 or higher
if RUBY_VERSION < '1.8.6'
  raise Exception, "Sorry - doodle does not work with versions of Ruby below 1.8.6"
end

# set up load path
$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# *doodle* is an eco-friendly metaprogramming framework that does not
# pollute core Ruby objects such as Object, Class and Module.
#
# While doodle itself is useful for defining classes, my main goal is to
# come up with a useful DSL notation for class definitions which can be
# reused in many contexts.
#
# Docs at http://doodle.rubyforge.org
#
require 'doodle/debug'
require 'doodle/ordered-hash'
require 'doodle/utils'
require 'doodle/equality'
require 'doodle/comparable'
require 'doodle/exceptions'
require 'doodle/singleton'
require 'doodle/embrace'
require 'doodle/validation'
require 'doodle/conversion'
require 'doodle/deferred'
require 'doodle/info'
require 'doodle/smoke-and-mirrors'
require 'doodle/datatype-holder'
require 'doodle/to_hash'
require 'doodle/marshal'
require 'doodle/getter-setter'
require 'doodle/factory'
require 'doodle/base'
require 'doodle/core'
require 'doodle/attribute'
require 'doodle/collector'

############################################################
# and we're bootstrapped! :)
############################################################
