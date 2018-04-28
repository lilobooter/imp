# map
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
 
```
#  USAGE:
```

  map name [ key=value ]

```
#  EXECUTIVE SUMMARY:
```

  Constructs an associative array object and populates with the specified 
  key/value pairs. Provides additional high level access to the array.

```
#  EXAMPLE OF USE:
```

  To instantiate an imp, simply source the split_map.sh changing the path 
  specified as appropriate:

  $ source src/split_map.sh

  Then create your map:

  $ map name

  Assign some values:

  $ name.assign key=value foo=bar fufu=snusnu

  Obtain the list of keys:

  $ echo $( name.keys )
  key foo fufu

  Obtain a value from the map by its key:

  $ echo $( name.value key )
  value

  Remove a key:

  $ name.remove key
  $ echo $( name.keys )
  foo fufu

  Use tab completion to see all available methods:

  name.assign    name.clear     name.contains  name.copy      name.destroy   
  name.dump      name.keys      name.read      name.remove    name.size      
  name.value     name.values

```
#  RATIONALE:
```

  The intent is to wrap the ugly (but powerful) bash associative array in a
  prettier, more convenient manner.
 
```
#  METHODS:
```
 
  name.destroy

  Destroys the map
 
  name.copy other

  Creates a copy of the map as other
 
  name.assign [ key=value ]*

  Assign entries in the map
 
  name.pair key value ...

  Assign entries in the map - allows keys to hold = symbols if required
 
  name.keys

  Outputs the known keys
 
  name.contains key

  Returns 0 if the key has been assigned
 
  name.values

  Outputs the current list of values
 
  name.value key ...

  Outputs the value of the requested keys
 
  name.remove key ...

  Removes the specified keys
 
  name.size

  Outputs the number of entries in the map
 
  name.dump

  Convenience method which lists the contents of the map
 
  name.clear

  Removes everything from the map
 
  name.read

  Read values from stdin and assign to the map
 
```
#  PUBLIC:
```
 
  map.ls

  List the defined map objects
```
