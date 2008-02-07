//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKObject.h"

@class JKSpectrum;
@class JKGCMSDocument;
@class ChromatogramGraphDataSerie;
@class PKPeak;
@class JKLibraryEntry;

@interface PKChromatogram : PKObject <NSCoding> {
    NSString *model;
    NSMutableArray *peaks;
    
    int numberOfPoints;
    
    float *time;
    float *totalIntensity;
    float highestPeakHeight;
    float largestPeakSurface;
    
    // baseline points cache (for baselineValueAtScan bottle neck)
    int baselinePointsCount;
    int *baselinePointsScans;
    float *baselinePointsIntensities;

}

/*! @functiongroup Initialization */
#pragma mark Initialization

    /*! Designated initializer. */
- (id)initWithModel:(NSString *)model;
#pragma mark -

    /*! @functiongroup Actions */
#pragma mark Actions

- (void)obtainBaseline;
- (void)identifyPeaks;
- (void)identifyPeaksWithForce:(BOOL)forced;
- (PKPeak *)peakFromScan:(int)startScan toScan:(int)endScan;
//- (void)addPeakFromScan:(int)startScan toScan:(int)endScan withLeftBaseline:(float)baselineLeft andRightBaseline:(float)baselineRight;
- (BOOL)combinePeaks:(NSArray *)peaksToCombine;

- (int)baselinePointsIndexAtScan:(int)inValue;
- (float)baselineValueAtScan:(int)inValue;

- (float)highestPeakHeight;
- (float)largestPeakSurface;
- (void)removeUnidentifiedPeaks;
#pragma mark -

#pragma mark Document
- (JKGCMSDocument *)document;
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
//- (NSMutableArray *)baselinePoints;
//- (void)setBaselinePoints:(NSMutableArray *)inValue;
//- (int)countOfBaselinePoints;
//- (NSMutableDictionary *)objectInBaselinePointsAtIndex:(int)index;
//- (void)getBaselinePoint:(NSMutableDictionary **)someBaselinePoints range:(NSRange)inRange;
//- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index;
//- (void)removeObjectFromBaselinePointsAtIndex:(int)index;
//- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSMutableDictionary *)aBaselinePoint;
//- (BOOL)validateBaselinePoint:(NSMutableDictionary **)aBaselinePoint error:(NSError **)outError;
//- (void)cacheBaselinePoints;
- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index;

// Mutable To-Many relationship peak
- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)inValue;
- (int)countOfPeaks;
- (PKPeak *)objectInPeaksAtIndex:(int)index;
- (void)getPeak:(PKPeak **)somePeaks range:(NSRange)inRange;
- (void)insertObject:(PKPeak *)aPeak inPeaksAtIndex:(int)index;
- (void)removeObjectFromPeaksAtIndex:(int)index;
- (void)replaceObjectInPeaksAtIndex:(int)index withObject:(PKPeak *)aPeak;
- (BOOL)validatePeak:(PKPeak **)aPeak error:(NSError **)outError;

- (int)baselinePointsCount;
- (void)setBaselinePointsScans:(int *)inArray withCount:(int)inValue;
- (int *)baselinePointsScans;
- (void)setBaselinePointsIntensities:(float *)inArray withCount:(int)inValue;
- (float *)baselinePointsIntensities;
                


- (float)maxTime;
- (float)minTime;
- (float)maxTotalIntensity;
- (float)minTotalIntensity;

@property (getter=numberOfPoints) int numberOfPoints;
@property (getter=baselinePointsIntensities) float *baselinePointsIntensities;
@property (getter=baselinePointsScans) int *baselinePointsScans;
@property (getter=baselinePointsCount) int baselinePointsCount;
@property (getter=totalIntensity) float *totalIntensity;
@property (getter=time) float *time;
@end
