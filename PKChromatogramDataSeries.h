//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGraphDataSeries.h"

@class JKChromatogram;

@interface PKChromatogramDataSeries : PKGraphDataSeries {
	BOOL shouldDrawPeaks;	
	BOOL shouldDrawBaseline;	
    JKChromatogram *chromatogram;
    NSPredicate *filterPredicate;
}

#pragma mark INITIALIZATION
- (id)initWithChromatogram:(JKChromatogram *)aChromatogram;

#pragma mark DRAWING ROUTINES
- (void)drawPeaksWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view;

#pragma mark CONVENIENCE METHOD
- (NSArray *)peaks;

#pragma mark ACCESSORS
- (JKChromatogram *)chromatogram;
- (void)setChromatogram:(JKChromatogram *)aChromatogram;
- (BOOL)shouldDrawPeaks;
- (void)setShouldDrawPeaks:(BOOL)inValue;
- (NSPredicate *)filterPredicate;
- (void)setFilterPredicate:(NSPredicate *)filterPredicate;
- (BOOL)shouldDrawBaseline;
- (void)setShouldDrawBaseline:(BOOL)inValue;
- (NSBezierPath *)baselineBezierPath;

@property (getter=shouldDrawBaseline,setter=setShouldDrawBaseline:) BOOL shouldDrawBaseline;
@property (getter=shouldDrawPeaks,setter=setShouldDrawPeaks:) BOOL shouldDrawPeaks;
@end