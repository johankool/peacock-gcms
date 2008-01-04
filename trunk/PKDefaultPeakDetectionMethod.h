//
//  PKDefaultPeakDetectionMethod.h
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PKPluginProtocol.h"

@interface PKDefaultPeakDetectionMethod : NSObject <PKPeakDetectionMethodProtocol> {
    NSDictionary *settings;
}

@end
