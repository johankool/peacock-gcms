//
//  NSEvent+ModifierKeys.m
//  Peacock
//
//  Created by Johan Kool on 7-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "NSEvent+ModifierKeys.h"
#import <Carbon/Carbon.h>

@implementation NSEvent (ModifierKeys)

+ (BOOL)isControlKeyDown {
    return (GetCurrentKeyModifiers() & controlKey) != 0;
}

+ (BOOL)isOptionKeyDown {
    return (GetCurrentKeyModifiers() & optionKey) != 0;
}

+ (BOOL)isCommandKeyDown {
    return (GetCurrentKeyModifiers() & cmdKey) != 0;
}

+ (BOOL)isShiftKeyDown {
    return (GetCurrentKeyModifiers() & shiftKey) != 0;
}

@end
