//
//  PKDefaultPlugin.m
//  Peacock Default Plugin
//
//  Created by Johan Kool on 28-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDefaultPlugin.h"


@implementation PKDefaultPlugin
/*!
 @abstract   Returns an array of NSStrings for baseline detection methods implemented through the plugin.
 */
+ (NSArray *)baselineDetectionMethodNames {
    return [NSArray arrayWithObject:@"Default Baseline Detection Method"];
}

/*!
 @abstract   Returns an array of NSStrings for peak detection methods implemented through the plugin.
 */
+ (NSArray *)peakDetectionMethodNames {
    return [NSArray arrayWithObject:@"Default Peak Detection Method"];
}

/*!
 @abstract   Returns an array of NSStrings for forward search methods implemented through the plugin.
 */
+ (NSArray *)forwardSearchMethodNames {
    return [NSArray arrayWithObject:@"Default Forward Search Method"];
}

/*!
 @abstract   Returns an array of NSStrings for backward search methods implemented through the plugin.
 */
+ (NSArray *)backwardSearchMethodNames {
    return [NSArray arrayWithObject:@"Default Backward Search Method"];
}


/*!    
 @abstract   Returns an object that implements the method.
 @param methodName The name of the method. This should be one of the strings returned by one of the +(NSArray *)...MethodNames; methods.
 @discussion Used to find the object that implements the method with the name methodName. The returned object should conform to the related protocol.
 @result     Returns an object that implements the method. Returns nil in case of an error.
 */
- (id)sharedObjectForMethod:(NSString *)methodName {
    if ([methodName isEqualToString:@"Default Baseline Detection Method"]) {
        return self;
    } 
    return nil;
}

@end
