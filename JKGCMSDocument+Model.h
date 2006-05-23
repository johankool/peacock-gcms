//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKGCMSDocument.h"

@class ChromatogramGraphDataSerie;
@class JKSpectrum;
@class JKPeakRecord;

@interface JKGCMSDocument (Model) {
    int ncid;
    int numberOfPoints;
    int intensityCount;
	
    float *time;
    float *totalIntensity;
	
	float minimumTime;
	float maximumTime;
	float minimumTotalIntensity;
	float maximumTotalIntensity;
	
    BOOL hasSpectra;
	
    NSMutableArray *chromatograms;    
	
    NSMutableArray *peaks;
    NSMutableArray *baseline;
	NSMutableDictionary *metadata;
	
	// Search options
	BOOL penalizeForRetentionIndex;
	NSNumber *retentionIndexSlope;     // retentionIndex = retentionSlope * retentionTime +  retentionRemainder
	NSNumber *retentionIndexRemainder; //
}
//-(void)finishInit;
-(BOOL)finishInitWithError:(NSError **)anError;
-(ChromatogramGraphDataSerie *)chromatogram;
#pragma mark ACTIONS
//-(void)getChromatogramData;
-(void)getBaselineData;
-(void)addChromatogramForMass:(NSString *)inString;
-(ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString;

-(void)identifyPeaks;
-(float)baselineValueAtScan:(int)inValue;
-(JKSpectrum *)getSpectrumForPeak:(JKPeakRecord *)peak;
-(JKSpectrum *)getCombinedSpectrumForPeak:(JKPeakRecord *)peak;

#pragma mark ACCESSORS
-(void)setNcid:(int)inValue;
-(int)ncid;

-(int)numberOfPoints;

-(void)setHasSpectra:(BOOL)inValue;
-(BOOL)hasSpectra;

-(int)intensityCount;
-(void)setIntensityCount:(int)inValue;

-(void)setTime:(float *)inArray withCount:(int)inValue;
-(float *)time;
-(float)timeForScan:(int)scan;

-(void)setTotalIntensity:(float *)inArray withCount:(int)inValue;
-(float *)totalIntensity;

-(float)maximumTime;
-(float)minimumTime;
-(float)maximumTotalIntensity;
-(float)minimumTotalIntensity;

-(NSMutableArray *)chromatograms;
//-(void)setChromatograms:(NSMutableArray *)inValue;

-(void)setPeaks:(NSMutableArray *)inValue;
-(NSMutableArray *)peaks;
-(void)setBaseline:(NSMutableArray *)inValue ;
-(NSMutableArray *)baseline;
-(NSMutableDictionary *)metadata;

-(void)setRetentionIndexSlope:(NSNumber *)inValue;
-(NSNumber *)retentionIndexSlope;
-(void)setRetentionIndexRemainder:(NSNumber *)inValue;
-(NSNumber *)retentionIndexRemainder;

-(float *)xValuesSpectrum:(int)scan;
-(float *)yValuesSpectrum:(int)scan;
-(float *)yValuesIonChromatogram:(float)mzValue;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

@end

