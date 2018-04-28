# imp
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
 
```
###  USAGE:
```

  imp [ config ] command ...

  where config is nothing or any of the following:

  --name=title      : Gives the imp a name
  --echo=command    : Handhshaking command (see evaluate for more information)
  --pager=command   : For use in the interactive shell
  --timeout=value   : Fallback - when handshaking isn't an option
  --wait=value      : Fallback - specify number of lines to wait for

```
###  EXECUTIVE SUMMARY:
```

  Turns any 'command ...' which accepts input on stdin and produces output on 
  stdout into a stateful server.

```
###  EXAMPLE OF USE:
```

  The following is an example of use from a bash command line using the GNU bc 
  calculator. 

  This is perhaps not the most exciting command to use, but it's safe, fairly 
  forgiving and it has features which are quite interesting in itself :).

  If bc does not excite you, consider playing with python -i or even bash itself.

  To instantiate an imp, simply source the split_imp.sh changing the path 
  specified as appropriate:

  $ source src/split_imp.sh

  Then create your imp:

  $ imp bc -l

  If you use tab completion on bc. you will see all the methods with which you
  can interact with your imp:

  bc.config    bc.destroy   bc.evaluate  bc.read      bc.shell

  We shall start by introducing the evaluate command:

  $ bc.evaluate "10 + 20"
  30

  We can also request multiple calculations:

  $ bc.evaluate "20 + 30" "40 + 50"
  50
  90

  Note that imps hold state between uses. To demonstrate this, I will use bc's
  '.' functionality - this simply means 'the result of the last calculation':

  $ bc.evaluate "10 + 20"
  30
  $ bc.evaluate ". * 4"
  120

  Environment variables can also be used in the command executed:

  $ value=10
  $ bc.evaluate "$value * 4"
  40

  When multiple arguments are provided to evaluate, each is pushed to the instance
  as a discrete line of text, hence:

  $ echo $( bc.evaluate "10 + 20" "30 + 40" )
  30 70
  echo $( bc.evaluate 'for ( i = 0; i < 10; i ++ )' 'print i, "\n"' )
  0 1 2 3 4 5 6 7 8 9

  Additionally, assuming that a ssh-copy-id or similar has been executed, you can 
  run an instance from a remote machine like:

  $ imp ssh user@server bc -l
  $ ssh.evaluate "6 * 7"
  42

  Obviously, if you want to use ssh multiple times, it would be better to name 
  each instance like:

  $ imp --name=server_bc ssh user@server bc -l
  $ server_bc.evaluate "2 * 3 * 7"
  42

  You can also specify config options when constructing the imp:

  $ imp --name=amlclient --echo='aml.echo-<key>' nc localhost 55378

  which would create an imp called amlclient which connects with amldaemon at 
  port 55378 on localhost.

  Additional Features:

  It also provides a basic interactive shell:

  $ bc.shell
  bc> 6 * 7
  42
  bc>

  which you can leave at any point using ctrl+d and return to later. 

  Note that name.shell does have a history, but due to a bug in bash, the 
  initial history is populated from the bash history at that point. Upon 
  re-entry, the last command for the named imp is available though. Also due 
  to a bash bug, the first attempt to record a command fails - hence a 
  dummy/unsaved entry is introduced by way of a #'d comment. This is not
  saved.

  An alternative to evaluate and shell is read. This uses stdin to receive its 
  input rather than command line arguments.

  To remove everything related to bc, you can run:

  $ bc.destroy

  The processes related to the object are now removed.

  To see what you currently have running, you can run the command:

  $ imp.ls
 
```
###  PLEASE NOTE:
```

  This documentation is very much focussed on using imp interactively, but imp's 
  primary purpose is to be used inside other scripts. The purpose of the 
  interactive commands is to introduce a debugging tool for script development.
 
```
###  RATIONALE:
```

  A very common requirement in scripting is to carry out operations using small 
  tools. For example, we can use the GNU bc command to carry out floating point
  arithmetic:

  $ result=$( bc -l <<< "3 / 2" )
  $ echo $result 
  1.50000000000000000000

  While this is quite succinct it has some major disadvantages.

  The first issue is that each calculation requires a new process to be spawned.
  Typically, this is way more expensive than the actual operation it's required
  to carry out. Having said that, speed improvements only apply to heavier tools
  than bc.

  The second issue is that we lose a lot of features of the tools themselves. It
  would be nice to have it retain state between calls for example, or to use 
  the extensive, or even simplified, grammar these tools can provide

  A third issue is that if the command you want is actually on another machine,
  this becomes even more expensive to kick it off each time via ssh or similar.

  Some systems (ie: Windows) are relatively slow at starting processes too, so
  complex scripts which invoke many such instances can really grind.

  This class attempts to provide a mechanism which converts any executable which
  executes commands received on stdin and produces output on stdout into a 
  stateful server.
 
```
###  RETURN VALUES:
```

  All functions/methods return 0 if successful.
 
```
###  METHODS:
```
 
  name.destroy

  Destroys the named instance
 
  name.config [ options ... ]

  Provides access to the internal options. 

  By default (without options), it reports all state.

  You can also query an individual setting using (for example):

  name.config timeout

  And you can set modifiable settings using:

  name.config timeout 0.5

  This method also allows you to specify a tool specific manner to echo a 
  string. The command should contain <key> as this will get replaced by a 
  random string on each use.

  For example:

  $ amlbatch.config echo 'aml.echo-<key>'
  $ bc.config echo print "<key>\n"
  etc

  Common cases for local or ssh instances are automatically handled in the imp 
  constructor. Other tools will require manual specification where applicable.
  See name.evaluate for additional information on how this is used.
 
  name.evaluate args ...

  Pushes args to the process and reads the result.

  There are two conditions to the read back of the result:

  * if name.config echo has been specified or derived on startup, then the 
    provided args are pushed first, followed by the echo (after replacing 
    <key> with a random string). We then do a blocking read until the random 
    string is returned.

  * otherwise, we read the output with a timeout value until no more output is 
    returned. This is of course, rather problematic if the processing takes 
    longer than the timeout, but is provided as a fallback for simple/immediate 
    results where no mechanism to echo an arbitrary string exists.

  Special notes:

  This function allows for the returned acknowledgement to either be on its own
  line or at the end of the last line of the output. If it's elsewhere, the
  function will block indefinitely.

  There is an attempt to lock access by way of lockfile here. If it's not 
  installed you will likely have problems using this concurrently from subshells.
  Care should also be taken to avoid deadlocks by having the evaluation of one
  command relying on the evaluation of another.
 
  name.read

  Reads stdin until eof and runs contents via name.evaluate

  Unlike evaluate (which only accepts input by way of command line arguments),
  this method receives its input by way of stdin.

  Examples of use:

  $ echo "10 + 20" | calculator.read
  30
  $ calculator.read <<< "10 + 20"
  30
  $ calculator.read << EOF
  10 + 20
  EOF
  30
  $ echo "10 + 20" > file
  $ calculator.read < file
  30

  The intent with this method is to provide a more convenient approach for 
  exchanging larger blocks of input to the imp.
 
  name.shell [ command ... ]

  Starts an interactive shell for the named instance. The optional command
  specified as arguments are ran before the interactive shell is started.
 
```
###  INTERNALS:
```
 
  imp.run name

  Starts the imp as a background process.

  The general rule in this function is that the background process we create
  uses the input and output fifos constructed in the ctor. Note that the logic
  is slightly different between linux and cygwin.
 
```
###  PUBLIC:
```
 
  imp.ls

  Lists existing imp instances
```
