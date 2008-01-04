//
//  PKDefaultPlugin.m
//  Peacock Default Plugin
//
//  Created by Johan Kool on 28-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDefaultPlugin.h"

#import "JKLog.h"
#import "PKDefaultBaselineDetectionMethod.h"
#import "PKDefaultPeakDetectionMethod.h"
#import "PKAbundanceSpectraMatchingMethod.h"
#import "PKMZValuesSpectraMatchingMethod.h"

@implementation PKDefaultPlugin

- (id)init {
    self = [super init];
    if (self != nil) {
        JKLogDebug(@"init");
    }
    return self;
}

- (void) dealloc {
    if (abundanceMethodObject) 
        [abundanceMethodObject release];
    if (mzValuesMethodObject)
        [mzValuesMethodObject release];
    [super dealloc];
}


/*!
 @abstract   Returns an array of NSStrings for baseline detection methods implemented through the plugin.
 */
- (NSArray *)baselineDetectionMethodNames {
    return [NSArray arrayWithObject:@"Default Baseline Detection Method"];
}

/*!
 @abstract   Returns an array of NSStrings for peak detection methods implemented through the plugin.
 */
- (NSArray *)peakDetectionMethodNames {
    return [NSArray arrayWithObject:@"Default Peak Detection Method"];
}

/*!
 @abstract   Returns an array of NSStrings for forward search methods implemented through the plugin.
 */
- (NSArray *)spectraMatchingMethodNames {
    return [NSArray arrayWithObjects:@"Abundance", @"m/z Values", nil];
}

/*!    
 @abstract   Returns an object that implements the method.
 @param methodName The name of the method. This should be one of the strings returned by one of the +(NSArray *)...MethodNames; methods.
 @discussion Used to find the object that implements the method with the name methodName. The returned object should conform to the related protocol.
 @result     Returns an object that implements the method. Returns nil in case of an error.
 */
- (id)sharedObjectForMethod:(NSString *)methodName {
    JKLogEnteringMethod();
    if ([methodName isEqualToString:@"Default Baseline Detection Method"]) {
        return [[[PKDefaultBaselineDetectionMethod alloc] init] autorelease];
    } else if ([methodName isEqualToString:@"Default Peak Detection Method"]) {
        return [[[PKDefaultPeakDetectionMethod alloc] init] autorelease];
    } else if ([methodName isEqualToString:@"Abundance"]) {
        if (!abundanceMethodObject) {
            abundanceMethodObject = [[PKAbundanceSpectraMatchingMethod alloc] init];
        }
        return abundanceMethodObject;
    } else if ([methodName isEqualToString:@"m/z Values"]) {
        if (!mzValuesMethodObject) {
            mzValuesMethodObject = [[PKMZValuesSpectraMatchingMethod alloc] init];
        }
        return mzValuesMethodObject;
    } else {
        return nil;  
    }

}

@end
