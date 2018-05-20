#!/usr/bin/env bash

# Copyright (C) 2018 Charles Yates
# Released under the LGPL
# Faleena Hopkins can go spin

# USAGE:
#
# source cocky.sh
# cocky_button() { echo "button: $@" ; }
# cocky_axis() { echo "axis: $@" ; }
# cocky
#
# The 'cocky' function simply monitors button presses and axis moves made on
# a joystick. In turn, it invokes a number of functions, all of which can be 
# overridden.
#
# For general use, it is sufficient to define 1 or more of the following 3 
# functions:
#
# cocky_button <number> <value> <time>
# cocky_axis <number> <value> <time>
# cocky_event
#
# Hence, this example usage would override the button and axis handlers before 
# starting the cocky thing. The arguments received to the handler are simply 
# displayed.
#
# INTERNALS:
#
# This script is implemented as a simple wrapper for the jstest program from 
# the Linux joystick package. 
#
# The jstest program when running with the --event or --select switch provides
# output of the form:
#
# Event: type <type>, time <time>, number <number>, value <value>
#
# Where:
#
# <type> is 1 for a button or 2 for an axis
# <time> is the time in ms of the event relative to the uptime of the computer
# <number> is the button or axis number (varies from joystick to joystick)
# <value> is a number between -32767 and 32767 for an axis or 0 or 1 for buttons
#
# On receipt of each event, the 4 bits of information are extracted from the 
# received string, and the functions cocky_button or cocky_axis invoked with
# arguments of <number> <value> <time>. 
#
# If no event is received in 0.01s, the cocky_event function is called with no
# arguments.
#
# By default, all 3 functions do nothing.
#
# Additionaly, a script can override the cocky_validate and cocky_read functions 
# if required. For example if the joystick is connected to another machine:
#
# cocky_validate() { return ; }
# cocky_read() { exec ssh user@server jstest --event "$1" ; }
#
# would allow control from there.

# FUNCTIONS:

# cocky [ device ]
#
# Starts the event loop. A lock file based on the name of the device in use is
# employed to ensure two cocky instances aren't trying to use the same device.
# This is cleaned up on exit via the traps established in the function.

cocky() {
	# Handle arguments
	local js=${1:-/dev/input/js0}
	local running

	# Validate the specified device
	cocky_validate "$js" || return

	# Derive 'running' lock file
	running=/tmp/cocky-$( basename "$js" )

	# Confirm that we are the only cocky using this device
	[[ -f "$running" ]] && { echo >&2 "ERROR: $js is in use - remove $running if you believe this to be in error" ; return 3 ; }
	touch "$running"

	# Establish a cleanup track which removes the 'running' lock file on exit
	trap 'cocky_trap "$running"' SIGINT SIGTERM EXIT SIGHUP SIGQUIT SIGPIPE

	# Start the reading pipe and keep processing until running lock file is removed
	cocky_read "$js" |
	while [[ -f "$running" ]] ; do
		cocky_process
	done
}

# cocky_validate device
#
# Ensures that cocky is able to service the device

cocky_validate() {
	# Ensure jstest is available
	which jstest > /dev/null 2>&1 || { echo >&2 "ERROR: jstest is not available - install the joystick package" ; return 1 ; }

	# Ensure the js device exists
	[ -c "$1" ] || { echo >&2 "ERROR: $1 is not found" ; return 2 ; }
}

# cocky_read device
#
# Starts the jstest process or an equivalent. See usage comments above.

cocky_read() {
	exec jstest --event "$1"
}

# cocky_trap lockfile
#
# Trap handler which is associated to the cocky instance in use - removes the 
# lock file on completion.

cocky_trap() {
	[[ "$1" != "" ]] && rm -f "$1"
}

# cocky_process
#
# Read and parse an event.
#
# If no event is received in 0.01s, simply call the cocky_event function.
#
# Otherwise, parse the event description, determine which function to call and
# pass the derived "$number" "$value" "$time" values.

cocky_process() {
	local type time number value junk
	read -r -t 0.01
	if [[ "$REPLY" == "" ]] ; then
		cocky_event
	elif [[ "$REPLY" =~ ^Event:.type.[12]+,.*$ ]] ; then
		IFS=' ,' read junk junk type junk time junk number junk value <<< "$REPLY"
		case "$type" in
		1) cocky_button "$number" "$value" "$time" ;;
		2) cocky_axis "$number" "$value" "$time" ;;
		esac
	fi
}

# cocky_button <number> <value> <time>
#
# Invoked by cocky_process each time the state of a button changes.

cocky_button() { return ; }

# cocky_axis <number> <value> <time>
#
# Invoked by cocky_process each time the state of an axis changes.

cocky_axis() { return ; }

# cocky_event
#
# Invoked by cocky_process each time a timeout occurs

cocky_event() { return ; }
