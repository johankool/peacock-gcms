//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class JKSpectrum;
@class JKGCMSDocument;
@class ChromatogramGraphDataSerie;
@class JKPeakRecord;

@interface JKChromatogram : NSObject {
    JKGCMSDocument *document;
    NSString *model;
    NSMutableArray *baselinePoints;
    NSMutableArray *peaks;
    
    int numberOfPoints;
    
    float *time;
    float *totalIntensity;

    @private
    float maxTime;
    float minTime;
    float maxTotalIntensity;
    float minTotalIntensity;
    
    float maxXValuesSpectrum;
    float minXValuesSpectrum;
    float maxYValuesSpectrum;
    float minYValuesSpectrum;   

}

/*! @functiongroup Initialization */
#pragma mark INITIALIZATION

- (id)initWithDocument:(JKGCMSDocument *)inDocument;
    /*! Designated initializer. */
- (id)initWithDocument:(JKGCMSDocument *)inDocument forModel:(NSString *)model;

    /*! @functiongroup Actions */
#pragma mark ACTIONS

- (void)obtainBaseline;
- (void)identifyPeaks;
- (void)addPeakFromScan:(int)startScan toScan:(int)endScan;
- (void)addPeakFromScan:(int)startScan toScan:(int)endScan withLeftBaseline:(float)baselineLeft andRightBaseline:(float)baselineRight;
- (BOOL)combinePeaks:(NSArray *)peaksToCombine;

- (int)baselinePointsIndexAtScan:(int)inValue;
- (float)baselineValueAtScan:(int)inValue;

#pragma mark ACCESSORS
/*! @functiongroup Accessors */

/*! The document containing our chromatogram. */
- (JKGCMSDocument *)document;
- (void)setDocument:(JKGCMSDocument *)inDocument;
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
- (NSMutableDictionary *)objectInBaselinePointsAtIndex:(int)index;
- (void)getBaselinePoint:(NSMutableDictionary **)someBaselinePoints range:(NSRange)inRange;
- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index;
- (void)removeObjectFromBaselinePointsAtIndex:(int)index;
- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSMutableDictionary *)aBaselinePoint;
- (BOOL)validateBaselinePoint:(NSMutableDictionary **)aBaselinePoint error:(NSError **)outError;

// Mutable To-Many relationship peak
- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)inValue;
- (int)countOfPeaks;
- (JKPeakRecord *)objectInPeaksAtIndex:(int)index;
- (void)getPeak:(JKPeakRecord **)somePeaks range:(NSRange)inRange;
- (void)insertObject:(JKPeakRecord *)aPeak inPeaksAtIndex:(int)index;
- (void)removeObjectFromPeaksAtIndex:(int)index;
- (void)replaceObjectInPeaksAtIndex:(int)index withObject:(JKPeakRecord *)aPeak;
- (BOOL)validatePeak:(JKPeakRecord **)aPeak error:(NSError **)outError;



- (float)maxTime;
- (float)minTime;
- (float)maxTotalIntensity;
- (float)minTotalIntensity;

#pragma mark OBSOLETE

//- (void)getChromatogramData;
//
//- (JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index;
//- (float *)xValuesSpectrum:(int)scan;
//- (float *)yValuesSpectrum:(int)scan;
//- (int)startValuesSpectrum:(int)scan;
//- (int)endValuesSpectrum:(int)scan;
//- (float)maxXValuesSpectrum;
//- (float)minXValuesSpectrum;
//- (float)maxYValuesSpectrum;
//- (float)minYValuesSpectrum;

@end

