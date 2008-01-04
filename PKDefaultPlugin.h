//
//  PKDefaultPlugin.h
//  Peacock Default Plugin
//
//  Created by Johan Kool on 28-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PKPluginProtocol.h"

@class PKAbundanceSpectraMatchingMethod;
@class PKMZValuesSpectraMatchingMethod;

@interface PKDefaultPlugin : NSObject <PKPluginProtocol> {
    PKAbundanceSpectraMatchingMethod *abundanceMethodObject;
    PKMZValuesSpectraMatchingMethod *mzValuesMethodObject;
}

@end
