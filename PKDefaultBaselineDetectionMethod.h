//
//  PKDefaultBaselineDetectionMethod.h
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PKPluginProtocol.h"

@interface PKDefaultBaselineDetectionMethod : NSObject <PKBaselineDetectionMethodProtocol> {
    NSDictionary *settings;
}

@end