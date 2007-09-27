//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

@class JKChromatogram;

@interface ChromatogramGraphDataSerie : MyGraphDataSerie {
	BOOL shouldDrawPeaks;	
	BOOL shouldDrawBaseline;	
    JKChromatogram *chromatogram;
    NSPredicate *filterPredicate;
}

#pragma mark INITIALIZATION
- (id)initWithChromatogram:(JKChromatogram *)aChromatogram;

#pragma mark DRAWING ROUTINES
- (void)drawPeaksWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view;

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

@end
