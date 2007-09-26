//
//  NSEvent+ModifierKeys.h
//  Peacock
//
//  Created by Johan Kool on 7-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (ModifierKeys)

+ (BOOL)isControlKeyDown;
+ (BOOL)isOptionKeyDown;
+ (BOOL)isCommandKeyDown;
+ (BOOL)isShiftKeyDown;

@end
