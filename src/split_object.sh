#!/usr/bin/env bash

# Object functions
#
# These functions help automate object construction. The basic concept is that
# a class consists of a constructor and a collection of functions which all take
# an object name argument as the first argument as minimum. The names of these
# functions should all have a common leading pattern. The functionality here
# creates usable functions of the form '$name$method' and when executed they
# call the real function as 'pattern_method name ...'.
#
# For example:
#
# function stack( ) {
#    local name=$1
#    object_create "$name" "stack::"
#    ...
# }
#
# function stack::push( ) {
#    local name=$1
#    ...
# }
#
# function stack::pop( ) {
#    local name=$1
#    ...
# }
#
# Would create name.push and name.pop functions.
#
# Constructors can create global variables or other state (such as files)
# incorporating the given name and the methods can access them.
#

# object_create name prefix
#
# Creates methods of the form name.method for all functions that match start
# with $prefix - the $prefix is removed, and the remainder becomes the method
# (ie: stack::push with a prefix of stack:: would create a method of $name.push).

function object_create( ) {
	local name=$1
	local pattern=$2
	local methods
	methods=$( declare -F | grep " $pattern" | sed "s/^declare -f $pattern//" )
	for method in $methods
	do
		method_create "$name.$method" "$pattern$method" "$name"
	done
}

# object_destroy name
#
# Destroys all methods which start with $name. - as created by object_create
# above.

function object_destroy( ) {
	local name=$1
	local methods
	methods=$( declare -F | grep " $name\." | sed "s/^declare -f //" )
	for method in $methods
	do
		unset -f "$method"
	done
}

# method_create name function args ...
#
# Creats a function of name which calls function (or script or execuable) with
# the remainder of the args and appending args provided at runtime.
#
# For example:
#
# method_create name.push stack::push name
#
# Would make a function called name.push with a usage of:
#
# name.push [ args ]*

function method_create( ) {
	local name=$1
	shift
	eval "$name( ) { $* \"\$@\" ; }"
}

# tool_up command env-var
#
# Example:
#
# tool_up piranha ENCODER= <<< "$( piranha --encoders )"
#
# Creates a function for each output of "piranha --encoders" of the form:
#
# function piranha.name( ) { 
#   piranha ENCODER=name "$@"
# }
#
# NOTE: this is incorrect:
#
# piranha --encoders | tool_up piranha ENCODER=
#
# In this case, the new functions would be created in the subshell created to
# run the tool_up function - once it's complete, any changes made in that 
# subshell are lost.

function tool_up( ) {
	local command=$1
	local var=$2
	shift 2
	local name

	while read name
	do
		echo "$command.$name -> $command $var$name" "$@"
		method_create "$command.$name" "$command" "$var$name" "$@"
	done
}

