//
//  PKGCMSMeasurement.h
//  Peacock1
//
//  Created by Johan Kool on 13-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PKMeasurement.h"

@class PKChromatogram;

@interface PKGCMSMeasurement : PKMeasurement {
    NSMutableArray *chromatograms;

    // File representation
	int ncid;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
    
    NSNumber *minimumScannedMassRange;
	NSNumber *maximumScannedMassRange;
	// RetentionIndex = retentionSlope * retentionTime +  retentionRemainder
	NSNumber *retentionIndexSlope;     
	NSNumber *retentionIndexRemainder;
    
}

- (id)initWithFilePath:(NSString *)filePath;
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;

- (PKChromatogram *)ticChromatogram;
- (float)retentionIndexForScan:(int)scan;
- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)time;

@property(retain, readwrite) NSMutableArray *chromatograms;
@property(copy, readwrite) NSString *label;
@property int ncid;
@property(copy) NSString * absolutePathToNetCDF;
@end
