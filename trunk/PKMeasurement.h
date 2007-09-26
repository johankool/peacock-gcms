//
//  PKMeasurement.h
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PKObject.h"

@interface PKMeasurement : PKObject {
    NSString *uniqueID;
    NSString *label;
    NSMutableDictionary *metadata;
}

@property(copy, readonly) NSString *uniqueID;
@property(copy, readwrite) NSString *label;
@property(copy, readwrite) NSMutableDictionary *metadata;

@end
