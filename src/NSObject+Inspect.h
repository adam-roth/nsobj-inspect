//
//  NSObject+Inspect.h
//
//  Created by aroth on 4/02/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (Inspect)

- (void) inspect;
- (void) inspectToDepth: (int)maxDepth;
- (void) inspect: (id)anObject toDepth: (int)maxDepth;

@end
