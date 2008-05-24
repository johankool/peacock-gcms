//
//  JKSummarizer.h
//  Peacock
//
//  Created by Johan Kool on 28-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKCombinedPeak;
@class PKPeakRecord;

@interface PKSummarizer : NSObject {
    NSMutableArray *combinedPeaks;
    NSMutableArray *ratios;
}

- (void)setupRatios;

- (void)didConfirmPeak:(NSNotification *)aNotification;
- (void)didUnconfirmPeak:(NSNotification *)aNotification;
- (PKCombinedPeak *)combinedPeakForPeak:(PKPeakRecord *)peak;
- (NSMutableArray *)combinedPeaks;
- (void)setUniqueSymbols;
@end
