//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
