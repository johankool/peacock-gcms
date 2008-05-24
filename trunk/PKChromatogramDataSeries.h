//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGraphDataSeries.h"

@class PKChromatogram;

@interface PKChromatogramDataSeries : PKGraphDataSeries {
	BOOL shouldDrawPeaks;	
	BOOL shouldDrawBaseline;	
    PKChromatogram *chromatogram;
    NSPredicate *filterPredicate;
}

#pragma mark INITIALIZATION
- (id)initWithChromatogram:(PKChromatogram *)aChromatogram;

#pragma mark DRAWING ROUTINES
- (void)drawPeaksWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view;

#pragma mark CONVENIENCE METHOD
- (NSArray *)peaks;

#pragma mark ACCESSORS
- (PKChromatogram *)chromatogram;
- (void)setChromatogram:(PKChromatogram *)aChromatogram;
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