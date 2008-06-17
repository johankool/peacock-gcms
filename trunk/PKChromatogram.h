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

#import "PKModelObject.h"

@class PKChromatogramDataSeries;
@class PKGCMSDocument;
@class PKLibraryEntry;
@class PKPeakRecord;
@class PKSpectrum;

@interface PKChromatogram : PKModelObject <NSCoding> {
    NSString *model;
    NSMutableArray *peaks;
    NSMutableArray *baselinePoints;
    
    int numberOfPoints;
    
    float *time;
    float *totalIntensity;
    float highestPeakHeight;
    float largestPeakSurface;
    
    // baseline points cache (for baselineValueAtScan bottle neck)
    int baselinePointsCount;
    int *baselinePointsScans;
    float *baselinePointsIntensities;
    BOOL _baselinePointsCacheUpToDate;
}

/*! @functiongroup Initialization */
#pragma mark Initialization

/*! Designated initializer. */
- (id)initWithModel:(NSString *)model;
#pragma mark -

#pragma mark Action PlugIn style
- (BOOL)detectBaselineAndReturnError:(NSError **)error;
- (BOOL)detectPeaksAndReturnError:(NSError **)error;
#pragma mark -
   
    /*! @functiongroup Actions */
#pragma mark Actions
- (PKPeakRecord *)peakFromScan:(int)startScan toScan:(int)endScan;
//- (void)addPeakFromScan:(int)startScan toScan:(int)endScan withLeftBaseline:(float)baselineLeft andRightBaseline:(float)baselineRight;
- (BOOL)combinePeaks:(NSArray *)peaksToCombine;

- (int)baselinePointsIndexAtScan:(int)inValue;
- (float)baselineValueAtScan:(int)inValue;
- (void)removeUnidentifiedPeaks;

- (float)highestPeakHeight;
- (float)largestPeakSurface;

- (float)maxTime;
- (float)minTime;
- (float)maxTotalIntensity;
- (float)minTotalIntensity;


#pragma mark -
- (NSString *)legendEntry;

#pragma mark Document
- (PKGCMSDocument *)document;
#pragma mark -

#pragma mark Accessors
/*! @functiongroup Accessors */

- (NSString *)model;
- (void)setModel:(NSString *)inString;

/*! ID needed for reading NetCDF file. */
- (int)numberOfPoints;

/*! Returns array of floats for the time. */
- (float *)time;
- (void)setTime:(float *)inArray withCount:(int)inValue;

- (float *)totalIntensity;
- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue;


- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)inTime;

// Mutable To-Many relationship baselinePoint
- (NSMutableArray *)baselinePoints;
- (void)setBaselinePoints:(NSMutableArray *)inValue;
- (int)countOfBaselinePoints;
- (NSDictionary *)objectInBaselinePointsAtIndex:(int)index;
- (void)getBaselinePoint:(NSDictionary **)someBaselinePoints range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index;
- (void)removeObjectFromBaselinePointsAtIndex:(int)index;
- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSDictionary *)aBaselinePoint;
- (BOOL)validateBaselinePoint:(NSDictionary **)aBaselinePoint error:(NSError **)outError;
- (void)cacheBaselinePoints;

// Mutable To-Many relationship peak
- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)inValue;
- (int)countOfPeaks;
- (PKPeakRecord *)objectInPeaksAtIndex:(int)index;
- (void)getPeak:(PKPeakRecord **)somePeaks range:(NSRange)inRange;
- (void)insertObject:(PKPeakRecord *)aPeak inPeaksAtIndex:(int)index;
- (void)removeObjectFromPeaksAtIndex:(int)index;
- (void)replaceObjectInPeaksAtIndex:(int)index withObject:(PKPeakRecord *)aPeak;
- (BOOL)validatePeak:(PKPeakRecord **)aPeak error:(NSError **)outError;

@property (getter=time) float *time;
@property (getter=totalIntensity) float *totalIntensity;
@property (getter=numberOfPoints) int numberOfPoints;
@property (retain) NSMutableArray *baselinePoints;

@end

