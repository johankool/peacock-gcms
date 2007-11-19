//
//  JKSummarizer.h
//  Peacock
//
//  Created by Johan Kool on 28-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKCombinedPeak;
@class JKPeakRecord;

@interface JKSummarizer : NSObject {
    NSMutableArray *combinedPeaks;
    NSMutableArray *ratios;
}

- (void)setupRatios;

- (void)didConfirmPeak:(NSNotification *)aNotification;
- (void)didUnconfirmPeak:(NSNotification *)aNotification;
- (JKCombinedPeak *)combinedPeakForPeak:(JKPeakRecord *)peak;
- (NSMutableArray *)combinedPeaks;
- (void)setUniqueSymbols;
@end
