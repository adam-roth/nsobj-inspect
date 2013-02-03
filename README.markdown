### NSString+JavaAPI

An NSObject category that uses reflection to display details about arbitrary objects.

### Building

Nothing fancy here, just add the sources to your project and go.

### Usage

To use this code, you must do two things:

1.  `#import "NSObject+Inspect.h"`.

2.  Call `inspect` on whatever object you are interested in.  You can also pass an object to `inspect`, if you'd like to inspect something that is not itself derived from `NSObject`.
    

### Limitations

None known.  Note that this does not mean that none exist. 

### FAQ

**_Why create this category?_**<br />
Curiosity mostly, and to become more familiar with Objective-C and the iOS SDK.  This was a learning-experience for me more than anything else.  Also, reflection is just plain cool.

**_Why should I use this library?_**<br />
Use this code if you're curious about your runtime environment and you want to do a bit of poking around.  It's handy for discovering internal/undocumented API's, for one thing.

**_Why should I NOT use this library?_**<br />
If you're trying to do anything practical, this code will not help you.

**_What are your license terms?_**<br />
Use this code if you want, otherwise don't.  That's it.  
