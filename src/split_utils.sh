#!/usr/bin/env bash

# die message
#
# Close script with an error message

die( ) {
	echo >&2 "ERROR: $*" ; exit 1
}

# log message
#
# Log message with date/time stamp

log( ) {
	echo >&2 "$( date '+%Y:%m:%d %H:%M.%S' )" "$@"
}

# info message
#
# Log message with date/time stamp

info( ) {
	(( DEBUG > 0 )) && log "$@" || return 0
}

# running
#
# Outputs the number of currently running jobs

running( ) {
	jobs -p | wc -w
}

# block [ pid ]*
#
# Block until at least one of the specified or current jobs has completed

block( ) {
	local -a pids
	(( $# > 0 )) && pids=( "$@" ) || pids=( $( jobs -p ) )
	wait -n "${pids[@]}"
}

# check_dependencies [ command ]*
#
# Checks if 'which' can find the commands requested and fails with an appropriate
# error listing missing commands

check_dependencies( ) {
	local fail
	for command in "$@"
	do
		if ! which "$command" > /dev/null 2> /dev/null
		then
			fail="$fail$command "
		fi
	done
	[[ "$fail" != "" ]] && echo "$fail"
	test "$fail" == ""
}

# evaluate [ name ]*
#
# Inline expansion of deferred env vars
#
# Example:
#
# GOP=16
# NON_DEFERRED="g=$GOP"
# DEFERRED='g=$GOP'
# GOP=12
# evaluate DEFERRED
#
# The result will be that DEFERRED is now g=12 while NON_DEFERRED will still be g=16

evaluate( ) {
	while (( $# > 0 ))
	do
		local name="$1"
		local value
		value=$( eval echo "${!1}" )
		eval "$name='$value'"
		shift
	done
}

# list_functions prefix
#
# List functions which have a certain prefix

list_functions( ) {
	declare -F | grep " $1" | sed "s/^declare -f //"
}

# get_extension file
#
# Get the exension of the file

get_extension( ) {
	local filename
	filename=$( basename "$1" )
	echo "${filename##*.}"
}

# variable_exists name
#
# Determines if a variable with the name already exists or not

variable_exists( ) {
	local key=$1
	eval "test -z \${$key+_}"
	(( $? == 0 )) && return 1 || return 0
}

# function_exists name
#
# Determine if function exists.

function_exists( ) {
	[[ $( type -t "$1" ) == "function" ]]
}

# fullpath path
#
# Converts relative paths to absolute (reimplementation for systems which lack readlink -f)

fullpath( ) {
	local path=$1
	local abs=$path

	case $path in
		/*)
			;;
		*)
			abs=$PWD/$path
			;;
	esac

	[ -d "$path" ] && path=$path/.

	abs=$( cd "$( dirname -- "$path" )" ; printf %s. "$PWD" )
	abs=${abs%?}
	abs=$abs/${path##*/}

	echo "$abs"
}

# fullpath path
#
# Converts relative paths to absolute

fullpath( ) {
	readlink -f "$1"
}

# urlencode url
#
# Outputs a url encoded form of the input url

urlencode( ) {
	local string="$1"
	local strlen=${#string}
	local encoded=""
	local pos c o

	for (( pos=0 ; pos<strlen ; pos++ ))
	do
		c=${string:$pos:1}
		case "$c" in
			[-_.~a-zA-Z0-9$PRESERVE] )
				o="$c"
				;;
			* )
				printf -v o '%%%02x' "'$c"
				;;
		esac
		encoded+="$o"
	done
	echo "$encoded"
}

# switch_value switch
#
# Output the value of the switch - ie: get_value --url-prefix=/pug would output
# "/pug".

switch_value( ) {
	local name value
	IFS='=' read name value <<< "$1"
	echo "$value"
}

# tabs_to_spaces
#
# Converts stdin to 4 character spaces instead of tabs

tabs_to_spaces( ) {
	expand -t 4
}

