# cocky
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
  Faleena Hopkins can go spin
 
```
###  USAGE:
```

  source cocky.sh
  cocky_button() { echo "button: $@" ; }
  cocky_axis() { echo "axis: $@" ; }
  cocky

  The 'cocky' function simply monitors button presses and axis moves made on
  a joystick. In turn, it invokes a number of functions, all of which can be 
  overridden.

  For general use, it is sufficient to define 1 or more of the following 3 
  functions:

  cocky_button <number> <value> <time>
  cocky_axis <number> <value> <time>
  cocky_event

  Hence, this example usage would override the button and axis handlers before 
  starting the cocky thing. The arguments received to the handler are simply 
  displayed.

```
###  INTERNALS:
```

  This script is implemented as a simple wrapper for the jstest program from 
  the Linux joystick package. 

  The jstest program when running with the --event or --select switch provides
  output of the form:

  Event: type <type>, time <time>, number <number>, value <value>

  Where:

  <type> is 1 for a button or 2 for an axis
  <time> is the time in ms of the event relative to the uptime of the computer
  <number> is the button or axis number (varies from joystick to joystick)
  <value> is a number between -32767 and 32767 for an axis or 0 or 1 for buttons

  On receipt of each event, the 4 bits of information are extracted from the 
  received string, and the functions cocky_button or cocky_axis invoked with
  arguments of <number> <value> <time>. 

  If no event is received in 0.01s, the cocky_event function is called with no
  arguments.

  By default, all 3 functions do nothing.

  Additionaly, a script can override the cocky_validate and cocky_read functions 
  if required. For example if the joystick is connected to another machine:

  cocky_validate() { return ; }
  cocky_read() { exec ssh user@server jstest --event "$1" ; }

  would allow control from there.
 
```
###  FUNCTIONS:
```
 
  cocky [ device ]

  Starts the event loop. A lock file based on the name of the device in use is
  employed to ensure two cocky instances aren't trying to use the same device.
  This is cleaned up on exit via the traps established in the function.
 
  cocky_validate device

  Ensures that cocky is able to service the device
 
  cocky_read device

  Starts the jstest process or an equivalent. See usage comments above.
 
  cocky_trap lockfile

  Trap handler which is associated to the cocky instance in use - removes the 
  lock file on completion.
 
  cocky_process

  Read and parse an event.

  If no event is received in 0.01s, simply call the cocky_event function.

  Otherwise, parse the event description, determine which function to call and
  pass the derived "$number" "$value" "$time" values.
 
  cocky_button <number> <value> <time>

  Invoked by cocky_process each time the state of a button changes.
 
  cocky_axis <number> <value> <time>

  Invoked by cocky_process each time the state of an axis changes.
 
  cocky_event

  Invoked by cocky_process each time a timeout occurs
```
