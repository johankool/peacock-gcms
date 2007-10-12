//
//  JKSummarizer.h
//  Peacock
//
//  Created by Johan Kool on 28-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKCombinedPeak;

@interface JKSummarizer : NSObject {
    NSMutableArray *combinedPeaks;
    NSMutableArray *ratios;
}

- (void)didConfirmPeak:(NSNotification *)aNotification;
- (void)didUnconfirmPeak:(NSNotification *)aNotification;
- (JKCombinedPeak *)combinedPeakForLabel:(NSString *)label;

@end
