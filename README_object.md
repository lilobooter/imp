# object
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
 
  OBJECT FUNCTIONS

  These functions help automate object construction. The basic concept is that
  a class consists of a constructor and a collection of functions which all take
  an object name argument as the first argument as minimum. The names of these
  functions should all have a common leading pattern. The functionality here
  creates usable functions of the form '$name.$method' and when executed they
  call the real function as 'class:method name ...'.

```
###  EXAMPLE:
```

  stack( ) {
    local name=$1
    object.create "$name" stack || return
    ...
  }

  stack::push( ) {
    local name=$1
    ...
  }

  stack::pop( ) {
    local name=$1
    ...
  }

  Would create name.push and name.pop functions.

  By default the functions take the form:

  name.push( ) {
    object.check_exists name stack && stack::push name "$@"
  }

  name.pop( ) {
    object.check_exists name stack && stack::pop name "$@"
  }

  This ensures that what stack::push and stack::pop receive as arguments are 
  valid. In practice this is overkill, since we have already validated the
  name prior to creating the method, hence:

  name.push( ) {
    stack::push name "$@"
  }

  name.pop( ) {
    stack::pop name "$@"
  }

  is all that is really required. To turn on the simpler form:

  export OBJECT_TRUSTED=1

  prior to creating your objects.

  Constructors can create global variables or other state (such as files)
  incorporating the given name and the methods can access them.
 
```
###  PUBLIC FUNCTIONS:
```
 
  object.create name class

  Creates methods of the form name.method for all functions that match start
  with $class:: - the class is removed, and the remainder becomes the method
  ie: stack::push with a class of stack would create a method of $name.push.

  See notes above for usage.
 
  object.destroy name

  Destroys all methods which start with $name. - as created by object.create
  above.
 
  method.create name function args ...

  Creats a function of name which calls function (or script or execuable) with
  the remainder of the args and appending args provided at runtime.

  For example:

  method.create name.push stack::push name

  Would make a function called name.push with a usage of:

  name.push [ args ]*
 
  object.check_create name

  Verifies that 'name' indicates an object which can be created. Reports on 
  stderr and returns a non-zero value if fails.
 
  object.check_exists name [ class ]

  Verifies that 'name' indicates an existing object of type class if specified. 
  Reports on stderr and returns a non-zero value if fails.
 
  object.ls [ class ]

  Lists created objects
 
```
###  MISCELLANY:
```
 
  tool_up command env-var

  Example:

  tool_up piranha ENCODER= <<< "$( piranha --encoders )"

  Creates a function for each output of "piranha --encoders" of the form:

  piranha.name( ) { 
    piranha ENCODER=name "$@"
  }

  NOTE: this is incorrect:

  piranha --encoders | tool_up piranha ENCODER=

  In this case, the new functions would be created in the subshell created to
  run the tool_up function - once it's complete, any changes made in that 
  subshell are lost.
 
```
###  GLOBAL STATE:
```
 
  object_instances global array created here if necessary
```
