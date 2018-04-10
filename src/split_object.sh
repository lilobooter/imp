#!/usr/bin/env bash

# Object functions
#
# These functions help automate object construction. The basic concept is that
# a class consists of a constructor and a collection of functions which all take
# an object name argument as the first argument as minimum. The names of these
# functions should all have a common leading pattern. The functionality here
# creates usable functions of the form '$name.$method' and when executed they
# call the real function as 'class:method name ...'.
#
# For example:
#
# function stack( ) {
#	local name=$1
#	object_create "$name" stack || return
#	...
# }
#
# function stack::push( ) {
#	local name=$1
#	...
# }
#
# function stack::pop( ) {
#	local name=$1
#	...
# }
#
# Would create name.push and name.pop functions.
#
# By default the functions take the form:
#
# function name.push( ) {
# 	object.check_exists name stack && stack::push name "$@"
# }
#
# function name.pop( ) {
# 	object.check_exists name stack && stack::pop name "$@"
# }
#
# This ensures that what stack::push and stack::pop receive as arguments are 
# valid. In practice this is overkill, since we have already validated the
# name prior to creating the method, hence:
#
# function name.push( ) {
# 	stack::push name "$@"
# }
#
# function name.pop( ) {
# 	stack::pop name "$@"
# }
#
# is all that is really required. To turn on the simpler form:
#
# export OBJECT_TRUSTED=1
#
# prior to creating your objects.
#
# Constructors can create global variables or other state (such as files)
# incorporating the given name and the methods can access them.

# object_create name class
#
# Creates methods of the form name.method for all functions that match start
# with $class:: - the class is removed, and the remainder becomes the method
# ie: stack::push with a class of stack would create a method of $name.push.
#
# See notes above for usage.

function object_create( ) {
	local name=$1
	local class=$2
	local methods
	object.check_create "$name" || return
	object_instances[$name]=$class
	methods=$( declare -F | grep " $class::" | sed "s/^declare -f $class:://" )
	for method in $methods
	do
		if [[ "$OBJECT_TRUSTED" == "1" ]]
		then
			method_create "$name.$method" "$class::$method $name"
		else
			method_create "$name.$method" "object.check_exists $name $class && $class::$method $name"
		fi
	done
}

# object_destroy name
#
# Destroys all methods which start with $name. - as created by object_create
# above.

function object_destroy( ) {
	local name=$1
	local methods
	object.check_exists "$name" || return
	unset object_instances[$name]
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

# object.check_create name
#
# Verifies that 'name' indicates an object which can be created. Reports on 
# stderr and returns a non-zero value if fails.

function object.check_create( ) {
	local name=$1
	if [[ "$name" == "" ]] ; then
		echo >&2 "ERROR: No name specified"
		return 1
	elif [[ "$name" == *[![:alnum:]_]* ]] ; then
		echo >&2 "ERROR: Invalid name '$name' for object"
		return 2
	elif [[ "${object_instances[$name]+_}" ]] ; then
		echo >&2 "ERROR: An object called '$name' of class '${object_instances[$name]}' already exists"
		return 3
	fi
	return 0
}

# object.check_exists name [ class ]
#
# Verifies that 'name' indicates an existing object of type class if specified. 
# Reports on stderr and returns a non-zero value if fails.

function object.check_exists( ) {
	local name=$1
	local class=$2
	if [[ "$name" == "" ]] ; then
		echo >&2 "ERROR: No name specified"
		return 1
	elif [[ ! "${object_instances[$name]+_}" ]] ; then
		echo >&2 "ERROR: Unable to locate an object called '$name'"
		return 2
	elif [[ "$class" != "" && "${object_instances[$name]}" != "$class" ]] ; then
		echo >&2 "ERROR: Object '$name' is a '${object_instances[$name]}' not a '$class'"
		return 2
	fi
	return 0
}

# object.ls [ class ]
#
# Lists created objects

function object.ls( ) {
	local class=$1
	local name
	for key in "${!object_instances[@]}"
	do
		[[ "$class" == "" ]] && echo "$key -> ${object_instances[$key]}"
		[[ "$class" != "" && "$class" == "${object_instances[$key]}" ]] && echo "$key"
	done
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

# object_instances global array created here if necessary

declare -A -g object_instances
