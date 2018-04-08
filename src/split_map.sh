#!/usr/bin/env bash

# map name [ key=value ]*
#
# Constructs a map object and populates with the specified key/value pairs.
#
# Example usage:
#
# $ source split_map.sh
# $ map name
# $ name.assign key=value foo=bar fufu=snusnu
# $ echo $( name.keys )
# key foo fufu
# $ echo $( name.value key )
# value
# $ name.remove key
# $ echo $( name.keys )
# foo fufu
# $ name.[tab][tab]
# name.assign    name.clear     name.contains  name.copy      name.destroy   
# name.dump      name.keys      name.read      name.remove    name.size      
# name.value     name.values
#
# The intent is to wrap the ugly (but powerful) bash associative array in a
# prettier, more convenient manner.

function map( ) {
	local name=$1
	shift
	unset __map_$name
	declare -A -g __map_$name
	object_create "$name" "map::"
	$name.assign "$@"
}

# name.destroy
#
# Destroys the map

function map::destroy( ) {
	local name=$1
	unset __map_$name
	object_destroy "$name"
}

# name.copy other
#
# Creates a copy of the map as other

function map::copy( ) {
	local name=$1
	local other=$2
	map "$other"
	local -n old_map=__map_$name
	local -n new_map=__map_$other
	for key in "${!old_map[@]}"
	do
		new_map["$key"]="${old_map[$key]}"
	done
}

# name.assign [ key=value ]*
#
# Assign entries in the map

function map::assign( ) {
	local -n map=__map_$1
	shift
	while (( $# > 0 ))
	do
		IFS='=' read -r key value <<< "$1"
		map["$key"]="$value"
		shift
	done
}

# name.pair key value ...
#
# Assign entries in the map - allows keys to hold = symbols if required

function map::pair( ) {
	local -n map=__map_$1
	local key=$2
	shift 2
	map["$key"]="$@"
}

# name.keys
#
# Outputs the known keys

function map::keys( ) {
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		echo "$key"
	done
}

# name.contains key
#
# Returns 0 if the key has been assigned

function map::contains( ) {
	local -n map=__map_$1
	local key="$2"
	test "${map[$key]+_}"
}

# name.values
#
# Outputs the current list of values

function map::values( ) {
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		echo "${map[$key]}"
	done
}

# name.value key
#
# Outputs the value of the requested key

function map::value( ) {
	local -n map=__map_$1
	local key="$2"
	test "${map[$key]+isset}" && echo "${map[$key]}"
}

# name.remove key
#
# Removes the specified key

function map::remove( ) {
	local -n map=__map_$1
	local key="$2"
	test "${map[$key]+isset}" && unset map["$key"]
}

# name.size
#
# Outputs the number of entries in the map

function map::size( ) {
	local -n map=__map_$1
	echo "${#map[@]}"
}

# name.dump
#
# Convenience method which lists the contents of the map

function map::dump( ) {
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		echo "$key=${map[$key]}"
	done
}

# name.clear
#
# Removes everything from the map

function map::clear( ) {
	local name=$1
	unset __map_$name
	declare -A -g __map_$name
}

# name.read
#
# Read values from stdin and assign to the map

function map::read( ) {
	local name=$1
	while read
	do  
		$name.assign "$REPLY"
	done
}

# map.ls
#
# List the defined map objects

function map.ls( ) {
    declare -A | grep "^declare -A __map_" | sed -e 's/=.*$//' -e "s/^declare -A __map_//" | grep -v "^_"
}

# Include the object definition stuff here
INCLUDE_DIR=$( dirname "${BASH_SOURCE[0]}" )
source "$INCLUDE_DIR/split_object.sh"
