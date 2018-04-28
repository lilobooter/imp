#!/usr/bin/env bash

# Copyright (C) 2018 Charles Yates
# Released under the LGPL

DIR=$( dirname "${BASH_SOURCE[0]}" )
source "$DIR/split_object.sh"

# USAGE:
#
# map name [ key=value ]
#
# EXECUTIVE SUMMARY:
#
# Constructs an associative array object and populates with the specified 
# key/value pairs. Provides additional high level access to the array.
#
# EXAMPLE OF USE:
#
# To instantiate an imp, simply source the split_map.sh changing the path 
# specified as appropriate:
#
# $ source src/split_map.sh
#
# Then create your map:
#
# $ map name
#
# Assign some values:
#
# $ name.assign key=value foo=bar fufu=snusnu
#
# Obtain the list of keys:
#
# $ echo $( name.keys )
# key foo fufu
#
# Obtain a value from the map by its key:
#
# $ echo $( name.value key )
# value
#
# Remove a key:
#
# $ name.remove key
# $ echo $( name.keys )
# foo fufu
#
# Use tab completion to see all available methods:
#
# name.assign    name.clear     name.contains  name.copy      name.destroy   
# name.dump      name.keys      name.read      name.remove    name.size      
# name.value     name.values
#
# RATIONALE:
#
# The intent is to wrap the ugly (but powerful) bash associative array in a
# prettier, more convenient manner.

map( ) {
	local name=$1
	object.create "$name" "map" || return
	shift
	declare -A -g __map_$name
	$name.assign "$@"
	return 0
}

# METHODS:

# name.destroy
#
# Destroys the map

map::destroy( ) {
	local name=$1
	unset __map_$name
	object.destroy "$name"
}

# name.copy other
#
# Creates a copy of the map as other

map::copy( ) {
	local name=$1
	local other=$2
	map "$other" || return
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

map::assign( ) {
	local name=$1
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

map::pair( ) {
	local name=$1
	local -n map=__map_$1
	local key=$2
	shift 2
	map["$key"]="$@"
}

# name.keys
#
# Outputs the known keys

map::keys( ) {
	local name=$1
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		echo "$key"
	done
}

# name.contains key
#
# Returns 0 if the key has been assigned

map::contains( ) {
	local name=$1
	local -n map=__map_$1
	local key="$2"
	test "${map[$key]+_}"
}

# name.values
#
# Outputs the current list of values

map::values( ) {
	local name=$1
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		test "${map[$key]+_}" && echo "${map[$key]}"
	done
}

# name.value key ...
#
# Outputs the value of the requested keys

map::value( ) {
	local name=$1
	local -n map=__map_$1
	shift
	local key
	while (( $# > 0 ))
	do
		key=$1
		test "${map[$key]+isset}" && echo "${map[$key]}"
		shift
	done
}

# name.remove key ...
#
# Removes the specified keys

map::remove( ) {
	local name=$1
	local -n map=__map_$1
	shift
	while (( $# > 0 ))
	do
		test "${map[$1]+isset}" && unset map["$1"]
		shift
	done
}

# name.size
#
# Outputs the number of entries in the map

map::size( ) {
	local name=$1
	local -n map=__map_$1
	echo "${#map[@]}"
}

# name.dump
#
# Convenience method which lists the contents of the map

map::dump( ) {
	local name=$1
	local -n map=__map_$1
	for key in "${!map[@]}"
	do
		echo "$key=${map[$key]}"
	done
}

# name.clear
#
# Removes everything from the map

map::clear( ) {
	local name=$1
	unset __map_$name
	declare -A -g __map_$name
}

# name.read
#
# Read values from stdin and assign to the map

map::read( ) {
	local name=$1
	while read -r
	do  
		$name.assign "$REPLY"
	done
}

# PUBLIC:

# map.ls
#
# List the defined map objects

map.ls( ) {
	object.ls map | grep -v "^_"
}

