# Author:: Martin Ankerl (mailto:martin.ankerl@gmail.com)
# Copyright:: Copyright (c) 2005 Martin Ankerl.
# License:: Ruby license.

# RubyToDot converts the class and module structure of a ruby program or library
# into a dot diagram. 
#
# == 20 Seconds Tutorial
# 
# Here is a simple example to generate the structure of
# the +set+ library:
#
#  stats = RubyToDot.new
#  stats.hide_current_state  # ignore all loaded classes+modules
#  require 'set'             # load new classes
#  puts stats.generate       # generate dot output
# 
# Use dot to generate an image from the above output, e.g. with
#
#  ruby rtd-test.rb | dot -Tpng >set.png
#
# == 1 Minute Tutorial
#
# For more complex libraries like FXRuby from Ruby Gems, a bit more is required 
# to produce nice looking graphs.
#
# 1. Initialize stats object, load everything required to load FXRuby
#
#      stats = RubyToDot.new
#      require 'rubygems'
#
# 1. Right before loading FXRuby, set all currently loaded classes to be ignored.
#
#      stats.hide_current_state
#      require_gem 'fxruby'
#
# 1. FXRuby uses SWIG, and all these wrapper classes can be safely ommited, 
#    they should not be visible to a user anyway. Therefore ignore 
#    <tt>SWIG::Pointer</tt> and everything that inherits this class.
#
#      stats.hide_tree(SWIG::Pointer)
#
# 1. Almost everything includes +Kernel+ and +Responder2+ module, so hide it.
# 
#     stats.hide(Kernel, Responder2)
# 
# 1. Enough setup! Now generate the dot diagram:
# 
#     puts stats.generate
#
# Voila! Instant class hierarchy graphs!
#
class RubyToDot
	# The name of the graph [String]
	attr_accessor :graph_name
	
	# Use left-to-right layout [true or false]
	attr_accessor :left_to_right
	
	# Color of classes / modules. May be  'h,s,v'  (hue,  saturation,  brightness)  float numbers
	# between 0 and 1, X11 color name like +white+, +black+, +burlywood+, etc,
	# or a '#rrggbb' (red, green, blue, 2 hex characters each) value. [String]
	attr_accessor :color
	
	# Color of the edges. [String]
	attr_accessor :color_edge
	
	# Font name [String]
	attr_accessor :font
	
	# Font size [Integer]
	attr_accessor :font_size
	
	# Color of classes/modules that should be hidden but are required because other classes
	# inherit them [String]
	attr_accessor :color_hidden
	
	# Shape of the classes. May be +plaintext+, +ellipse+, +circle+, +egg+, +triangle+, +box+, +diamond+, +trapezium+,
	# +parallelogram+, +house+, +hexagon+, and +octagon+. [String]
	attr_accessor :shape_class
	
	# Class + Module node height [Float]
	attr_accessor :height

	# Class + Module node width [Float]
	attr_accessor :width
	
	# Text shown at the edge of classes to an included module [String]
	attr_accessor :label_include
	
	# Font size of edge labels
	attr_accessor :font_size_edge
	
	# Force alphabetic ordering, even if this means ugly graphs [true or false]
	attr_accessor :sort_alphabetic
	
	def set_defaults
		@graph_name = "Ruby"
		@left_to_right = true
		@color = "black"
		@color_edge = "midnightblue"
		@color_hidden = "grey"
		@font = "Helvetica"
		@font_size = 10
		@shape_class = "ellipse"
		@height = 0.2
		@width = 0.4
		@label_include = "include"
		@font_size_edge = 8
		@sort_alphabetic = false
	end

	# Creates a new RubyToDot object.
	def initialize
		@classes = Array.new
		# A set instead of the hashes would be a nicer choice, but 
		# RubyToDot should not depend on any library to allow more complete graphs.
		@modules = Hash.new
		@ignored = Hash.new
		@ignored_tree = Hash.new
		set_defaults
	end
	
	# All currently loaded classes and modules will not be shown in the output graph.
	# If new classes inherit one of these already existing classes, they will be shown 
	# in grey color.
	def hide_current_state
		@classes = Array.new
		ObjectSpace.each_object(Class) do |klass|
			@classes.push klass
		end
		@modules = Hash.new
		ObjectSpace.each_object(Module) do |mod|
			@modules[mod] = true
		end
	end
	
	# Adds all specified classes/modules to the hidden list. E.g. it is
	# a good idea to ignore +Kernel+, as this module is used almost
	# everywhere.
	def hide(*classOrModules)
		classOrModules.each do |classOrModule|
			@ignored[classOrModule] = true
		end
	end
	
	# Hides all specified classes/modules and their subclasses. E.g. 
	# useful to hide the +SWIG+ classes for FXRuby.
	def hide_tree(*classOrModules)
		classOrModules.each do |classOrModule|
			@ignored_tree[classOrModule] = true
		end
	end
	
	# Generates the dot graph, and returns a string of the graph.
	def generate(with_modules=true)
		str = %Q|
digraph #{@graph_name} {
	#{"rankdir=LR;\n" if @left_to_right}
	#{"ordering=out;\n" if @sort_alphabetic}
	edge [color="#{@color_edge}",fontname="#{@font}",fontsize=#{font_size_edge}];
	node [color="#{@color_hidden}",fontcolor="#{@color_hidden}",fontname="#{@font}",fontsize=#{font_size},shape=#{shape_class},height=#{@height},width=#{@width}];
|
		# get classes
		current = Array.new
		ObjectSpace.each_object(Class) do |klass|
			current.push klass
		end
		todo = current - @classes - @ignored.keys

		# remove all classes from ignore_tree
		todo.delete_if do |klass|
			klass = klass.superclass while klass && !@ignored_tree[klass]
			klass
		end
		
		todo = todo.sort_by { |klass| klass.to_s }
		todo.each do |klass|
			# all classes black
			str << %Q|	"#{klass}" [height=#{@height},width=#{@width},color="#{@color}",fontcolor="#{@color}"];\n|
		end
		
		con = Hash.new
		# connections
		todo.each do |klass|
			while superclass = klass.superclass
				break if @ignored[superclass]
				con[ [superclass, klass] ] = true
				klass = superclass
			end
		end
		con.each_key do |superclass, klass|
			str << %Q{\t"#{superclass}" -> "#{klass}";\n}
		end
		str << "\n"
		
		gen_modules(str, todo) if with_modules			
		
		str << "}"
		str
	end
	
	private
	
	def gen_modules(str, todo)
		mods = Hash.new
		todo.each do |klass|
			klass.ancestors.each do |mod|
				next unless mod.class == Module
				next if @ignored[mod]
				mods[mod]  = true
				str << %Q{\t"#{klass}" -> "#{mod}" [color="darkorchid3",fontsize=#{@font_size_edge},style="dashed",label="#{@label_include}",fontname="#{@font}"];\n}
			end
		end
		str << "\n"
		mods.each_key do |mod|
			if @modules[mod]
				str << %Q{\t"#{mod}" [shape=box,height=#{@height},width=#{width}];\n}
			else
				str << %Q{\t"#{mod}" [shape=box,height=#{@height},width=#{width},color=#{@color},fontcolor=#{@color}];\n}
			end
		end
	end
end

=begin
	stats = RubyToDot.new
	require 'rubygems'
	stats.hide_current_state
	require_gem 'fxruby'
	stats.hide_tree(SWIG::Pointer)
	stats.hide(Kernel, Responder2)
	puts stats.generatedir
=end
