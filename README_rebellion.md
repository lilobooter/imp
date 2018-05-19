# rebellion
```
  Copyright (C) 2018 Charles Yates
  Released under the LGPL
 
```
###  USAGE:
```

  rebellion [ device ]

  Simulates a mouse by way of a joystick.

  It seemed like a funny thing to do.
 
```
###  GLOBAL STATE:
```

  speed_x and speed_y hold the current speed of the pointer.
 
```
###  METHODS:
```
 
  cocky_button <number> <value> <time>

  Simulate the joystick to mouse button transalation
 
  cocky_axis <number> <value> <time>

  Various axis are used to move the pointer at different rates
 
  cocky_event

  Handle the pointer movements of the current speed
 
  Execute cocky if this is script is not sourced
```
