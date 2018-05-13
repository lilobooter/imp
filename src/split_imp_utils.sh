#!/usr/bin/env bash

# Copyright (C) 2018 Charles Yates
# Released under the LGPL

DIR=$( dirname "${BASH_SOURCE[0]}" )
source "$DIR/split_imp.sh"

# USAGE:
#
# source split_imp_utils.sh
#
# This script provides a collection of functions which provide preconfigured 
# imps.
#
# It also introduces the concept of object.extends where new methods can be 
# added to an existing object.

# BC:

# imp.bc [ imp-config ]
#
# Courtesy wrapper for bc

imp.bc() { 
	imp "$imp_pager" "$@" bc -l 
}

# BASH:

# imp.bash [ imp-config ]
#
# Silly - create an imp of a bash shell

imp.bash() { 
	imp --name=bash "$imp_pager" "$@" bash 
}

# PYTHON:

# imp.python [ imp-config ]
#
# Silly - create an imp of an interactive python

imp.python() { 
	imp "$imp_pager" "$@" python -i ; 
}

# FESTIVAL:

# imp.festival [ imp-config ]
#
# Silly - text to speech thing

imp.festival() {
	# Create the imp to wrap the festival executable
	imp --name=festival --wait=1 --timeout=0 "$@" festival --pipe || return

	# name.speak "sentence" ...
	#
	# Sends the sentences to a festival imp

	festival::speak() {
		local name=$1 ; shift
		for thing in "$@" ; do
			local cmd=$( printf "( SayText \"%s\" )" "$thing" )
			$name.evaluate "$cmd"
		done
	}

	# Extend the imp with the festival methods
	object.extend "$IMP_LAST_CREATED" festival
}

# CONFIGURATION:
#
# The imps above can be controlled via the following env var:
#
# imp_pager
#
# Typically, you can leave this as default.

imp_pager=--pager="less -FeX"

# TERMBIN:

# tbc [ file ]*
#
# Uploads files or stdin to termbin.com and returns url.
#
# Nothing at all to do with imp - temporary placement.

tbc() { 
	cat "${@}" | nc termbin.com 9999 
}

