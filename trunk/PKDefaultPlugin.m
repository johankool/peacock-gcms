//
//  PKDefaultPlugin.m
//  Peacock Default Plugin
//
//  Created by Johan Kool on 28-11-07.
//  Copyright 2007-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKDefaultPlugin.h"

#import "PKLog.h"
#import "PKDefaultBaselineDetectionMethod.h"
#import "PKDefaultPeakDetectionMethod.h"
#import "PKAbundanceSpectraMatchingMethod.h"
#import "PKMZValuesSpectraMatchingMethod.h"

@implementation PKDefaultPlugin

- (id)init {
    self = [super init];
    if (self != nil) {
//        PKLogDebug(@"init");
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
//    PKLogEnteringMethod();
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
