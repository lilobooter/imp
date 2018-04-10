#!/usr/bin/env bash

DIR=$( dirname "${BASH_SOURCE[0]}" )
source "$DIR/split_object.sh"
source "$DIR/split_map.sh"
source "$DIR/split_utils.sh"

# imp name command ...
#
# Creates a backgrounded process of 'command ...' and a pair of fifos to interact 
# with it.
#
# PLEASE NOTE:
#
# The documentation is very much focussed on using imp interactively, but imp's 
# primary purpose is to be used inside other scripts. The purpose of the interactive 
# commands is to introduce a debugging tool for script development.

# Rationale:
#
# A very common requirement in scripting is to carry out operations using small 
# tools. For example, we can use the GNU bc command to carry out floating point
# arithmetic:
#
# $ result=$( bc -l <<< "3 / 2" )
# $ echo $result 
# 1.50000000000000000000
#
# While this is quite succinct it has some major disadvantages.
#
# The first issue is that each calculation requires a new process to be spawned.
# Typically, this is way more expensive than the actual operation it's required
# to carry out. Having said that, speed improvements only apply to heavier tools
# than bc.
#
# The second issue is that we lose a lot of features of the tools themselves. It
# would be nice to have it retain state between calls for example, or to use 
# bc's extensive grammar to provide additional functionality beyond the basics.
#
# A third issue is that if the command you want is actually on another machine,
# this becomes even more expensive to kick it off each time via ssh or similar.
#
# Some systems (ie: Windows) are relatively slow at starting processes too, so
# complex scripts which invoke many such instances can really grind.
#
# This class attempts to provide a mechanism which converts any executable which
# executes commands received on stdin and produces output on stdout into a 
# stateful server.
#
# Using the bc example, we can construct an imp object called calculator as 
# follows:
#
# $ source split_imp.sh
# $ imp calculator bc -l
# $ calculator.evaluate "10 + 20"
# 30
# $ result=$( calculator.evaluate ". * 4" )
# $ echo $result
# 120
#
# In bc, . means 'the previous result' - this evaluation of result demonstrates 
# that state is retained between uses.
#
# Environment variables can also be used in the command executed:
#
# $ echo $( calculator.evaluate "$result * 4" )
# 480
#
# When multiple arguments are provided to evaluate, each is pushed to the instance
# as a discrete line of text, hence:
#
# $ echo $( calculator.evaluate "10 + 20" "30 + 40" )
# 30 70
# echo $( calculator.evaluate 'for ( i = 0; i < 10; i ++ )' 'print i, "\n"' )
# 0 1 2 3 4 5 6 7 8 9
#
# Additionally, assuming that a ssh-copy-id or similar has been executed, you can 
# run an instance from a remote machine like:
#
# $ imp remote ssh user@server bc -l
# $ remote.evaluate "6 * 7"
# 42
#
# An alternative to evaluate and shell is read. This uses stdin to receive its 
# input rather than command line arguments.

# Additional Features:
#
# It also provides a basic interactive shell:
#
# $ calculator.shell
# calculator> 6 * 7
# 42
# calculator>
#
# which you can leave at any point using ctrl+d and return to later. 
#
# Note that name.shell does not currently have a meaningful or usable history.
#
# You can inspect the methods available using a double tab:
#
# $ calculator.[tab][tab]
# calculator.destroy   calculator.echo      calculator.evaluate  
# calculator.read      calculator.shell
# $ calculator.
#
# The echo method provides a means for you to train imp regarding how you
# interact with your object. See details below on what this provides and how
# it's used.
#
# To remove everything related to the calculator, you can run:
#
# $ calculator.destroy
#
# The processes related to the object are now removed.
#
# To see what you currently have running, you can run the command:
#
# $ imp.ls

# Return values:
#
# All functions/methods return 0 if successful.

function imp( ) {
	# Ensure we can create an object of the named object
	local name=$1
	object.check_create "$name" || return
	shift

	# Ensure specified command exists
	if ! check_dependencies "$1" > /dev/null
	then
		echo >&2 "ERROR: Cannot find the requested command '$1'"
		return 3
	fi

	# This object holds all state in this map
	local state=__imp_$name
	map "$state"

	# Create the object from the imp:: functions
	object_create "$name" "imp" || return

	# Create a temporary dir to hold the fifos and lock
	$state.pair temp "$( mktemp -d -t imp.XXXXXXXXXX )"

	# Create the fifos
	$state.pair input "$( $state.value temp )/input"
	$state.pair output "$( $state.value temp )/output"
	mkfifo "$( $state.value input )"
	mkfifo "$( $state.value output )"

	# Create the lock file
	$state.pair lock "$( $state.value temp )/lock"
	check_dependencies lockfile > /dev/null
	$state.pair lock_missing $?

	# Set the timeout for the fallback read
	$state.pair timeout 0.2

	# Start the execution
	$state.pair execute "$@"
	imp.run "$name" || return 1

	# Ensure we cleanup on exit
	trap "$name.destroy" EXIT

	# We need a place to store shell history
	mkdir -p ~/.imp/history

	# Courtesy - set the echo command for known commands
	case "$1" in
		amlbatch | amltutor) $name.echo '$ "<key>" .' ;;
		bash) $name.echo 'echo "<key>"' ;;
		bc) $name.echo 'print "<key>\n"' ;;
		dc) $name.echo '[<key>] p' ;;
		python) 
			$name.echo 'print "<key>"'
			$name.evaluate 'import sys; sys.ps1=""' > /dev/null
			;;
	esac
}

# name.destroy
#
# Destroys the named instance

function imp::destroy( ) {
	local name=$1
	local state=__imp_$name
	rm -rf "$( $state.value temp )"
	$state.destroy
	object_destroy "$name"
}

# name.echo [ command ... ]
#
# This method allows you to specify a tool specific manner to echo a string. The
# command should contain <key> as this will get replaced by a random string on 
# each use.
#
# For example:
#
# $ amlbatch.echo '$ "<key>" .'
# $ bc.echo 'print "<key>\n"'
# etc
#
# Common cases for local instances are automatically handled in the imp 
# constructor. Other tools will require manual specification where applicable.
# See name.evaluate for additional information on how this is used.

function imp::echo( ) {
	local name=$1
	local state=__imp_$name
	shift
	if (( $# > 0 ))
	then
		if [[ "$@" == *\<key\>* ]]
		then
			$state.pair echo "$@"
		else
			echo >&2 "ERROR: Invalid echo command - lacks <key>"
			return 2
		fi
	else
		$state.value "echo"
	fi
}

# name.evaluate args ...
#
# Pushes args to the process and reads the result.
#
# There are two conditions to the read back of the result:
#
# * if name.echo has been specified or derived on startup, then the provided 
#   args are pushed first, followed by the echo (after replacing <key> with 
#   a random string). We then do a blocking read until the random string is 
#   returned.
#
# * otherwise, we read the output with a timeout value until no more output is 
#   returned. This is of course, rather problematic if the processing takes 
#   longer than the timeout, but is provided as a fallback for simple/immediate 
#   results where no mechanism to echo an arbitrary string exists.
#
# Special notes:
#
# This function allows for the returned acknowledgement to either be on its own
# line or at the end of the last line of the output. If it's elsewhere, the
# function will block indefinitely.
#
# There is an attempt to lock access by way of lockfile here. If it's not 
# installed you will likely have problems using this concurrently from subshells.
# Care should also be taken to avoid deadlocks by having the evaluation of one
# command relying on the evaluation of another.

function imp::evaluate( ) {
	local name=$1
	local state=__imp_$name
	local echocmd lock input output timeout missing
	shift

	# The echo command can have spaces, so take that in isolation
	echocmd="$( $state.value echo )"

	# Get the rest of the state
	read lock input output timeout missing <<< $( $state.value lock input output timeout lock_missing )

	# Acquire a lock if possible
	[[ "$missing" == "0" ]] && lockfile "$lock"

	# Push each argument as a separate command
	for cmd in "$@" ; do echo "$cmd" > "$input" ; done

	# Handle the ack echocmd here and acquire all results
	if [[ "$echocmd" != "" ]]
	then
		# Generate a random echo key
		local key="ack-$RANDOM-ack"
		echocmd=${echocmd/<key>/$key}

		# Push the echocmd to signal completion of cmds
		echo "$echocmd" > "$input"

		# Read back all output until the key
		while read -r < "$output"
		do
			[[ "$REPLY" == "$key" ]] && break
			echo "${REPLY/$key/}"
			[[ "$REPLY" == *$key ]] && break
		done
	else
		# Fallback, just attempt to pop until timeout occurs
		while read -r -t "$timeout" < "$output" ; do echo "$REPLY" ; done
	fi

	# Relinquish the lock
	[[ "$missing" == "0" ]] && rm -f "$lock"
}

# name.read
#
# Reads stdin until eof and runs contents via name.evaluate
#
# Unlike evaluate (which only accepts input by way of command line arguments),
# this method receives its input by way of stdin.
#
# Examples of use:
#
# $ echo "10 + 20" | calculator.read
# 30
# $ calculator.read <<< "10 + 20"
# 30
# $ calculator.read << EOF
# 10 + 20
# EOF
# 30
# $ echo "10 + 20" > file
# $ calculator.read < file
# 30
#
# The intent with this method is to provide a more convenient approach for 
# exchanging larger blocks of input to the imp.

function imp::read( ) {
	local name=$1
	local input=()
	while read -r ; do input+=("$REPLY") ; done
	$name.evaluate "${input[@]}"
}

# name.shell [ command ... ]
#
# Starts an interactive shell for the named instance. The optional command
# specified as arguments are ran before the interactive shell is started.

function imp::shell( ) {
	local name=$1
	local oldhist=$HISTFILE
	local restore
	shift

	# Temporarily replace history file used with one for this command
	history -a
	HISTFILE="$HOME/.imp/history/$name"
	history -r

	# The first first history message isn't saved (bash bug)
	history -s "# Start of shell session for $name"

	# Ensure we turn off globbing while preserving the original state
	[[ $- = *f* ]] || restore='set +f'
	set -f

	# Evalaute arguments as a command
	if (( $# > 0 ))
	then 
		history -s "$@"
		$name.evaluate "$@" | less -e -F
	fi

	# Read input one line at a time and evaluate each
	while read -r -e -p "$name> " 
	do
		[[ "$REPLY" != "" && "$REPLY" != -* ]] && history -s "$REPLY"
		$name.evaluate "$REPLY" | less -e -F
	done

	# Ensure the cursor is in the right place at exit (line below last prompt)
	echo

	# Restore globbing
	eval "$restore"

	# Save the history and ensure we return to the default history file
	history -a
	HISTFILE="$oldhist"
	history -r
}

# imp.dump name
#
# Reports internal state of named imp

function imp.dump( ) {
	local name=$1
	object.check_exists "$name" imp || return
	local state=__imp_$name
	$state.dump
}

# imp.run name
#
# Starts the imp as a background process.
#
# The general rule in this function is that the background process we create
# uses the input and output fifos constructed in the ctor. Note that the logic
# is slightly different between linux and cygwin.

function imp.run( ) {
	local name=$1
	object.check_exists "$name" imp || return
	local state=__imp_$name
	local pid

	# Obtain pid of existing process if running
	pid=$( $state.value process )

	# Only start if no pid exists
	if [[ "$pid" == "" ]]
	then
		local execute temp input output

		# Extract the relevant state here
		execute=$( $state.value execute )
		read temp input output <<< $( $state.value temp input output )

		# Handle cross platform startup stuff here
		case "$( uname -s )" in
			CYGWIN*)
				imp.execute.cygwin( ) {
					( while [ 1 ] ; do cat < "$input" ; done | $execute 2>&1 | while [ 1 ] ; do read -r && echo "$REPY" > "$output" ; done )
				}

				# Execute the combined keepalive and execution logic for cygwin
				imp.execute.cygwin &
				$state.pair process $!
				;;
			*)
				imp.keepalive.unix( ) {
					while [[ -d "$temp" ]] ; do sleep 1 ; done > "$input" < "$output" 
				}

				# Execute the keepalive process
				imp.keepalive.unix &
				$state.pair keepalive $!

				imp.execute.unix( ) {
					$execute < "$input" > "$output" 2>&1
				}

				# Excute the main job
				imp.execute.unix &
				$state.pair process $!
				;;
		esac
	else
		echo >&2 "ERROR: imp $name already running as $pid"
		return 1
	fi
}

# imp.ls
#
# Not a class method - just lists existing imp instances

function imp.ls( ) {
	object.ls imp | grep -v "^_"
}

