# imp_utils
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
 
```
###  USAGE:
```

  source split_imp_utils.sh

  This script provides a collection of functions which provide preconfigured 
  imps.

  It also introduces the concept of object.extends where new methods can be 
  added to an existing object.
 
```
###  BC:
```
 
  imp.bc [ imp-config ]

  Courtesy wrapper for bc
 
```
###  BASH:
```
 
  imp.bash [ imp-config ]

  Silly - create an imp of a bash shell
 
```
###  PYTHON:
```
 
  imp.python [ imp-config ]

  Silly - create an imp of an interactive python
 
```
###  FESTIVAL:
```
 
  imp.festival [ imp-config ]

  Silly - text to speech thing
 
```
###  CONFIGURATION:
```

  The imps above can be controlled via the following env var:

  imp_pager

  Typically, you can leave this as default.
 
```
###  TERMBIN:
```
 
  tbc [ file ]*

  Uploads files or stdin to termbin.com and returns url.

  Nothing at all to do with imp - temporary placement.
```
