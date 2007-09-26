//
//  PKDocument.h
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKMainWindowController;
@class PKMeasurement;

@interface PKDocument : NSDocument {
    NSMutableArray *measurements; // contains PKMeasurements
    NSMutableArray *summaries; // contains ...
    NSMutableDictionary *metadata;
    NSMutableArray *measurementsMetadataKeys;
    PKMainWindowController *mainWindowController;
}

- (BOOL)addMeasurementWithFilePath:(NSString *)filePath atIndex:(int)index;

@property(retain, readwrite) NSMutableArray *measurementsMetadataKeys;
@property(retain, readwrite) NSMutableArray *measurements;
@property(retain, readwrite) NSMutableArray *summaries;
@property(retain, readwrite) NSMutableDictionary *metadata;

@end
