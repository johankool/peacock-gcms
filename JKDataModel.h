//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class ChromatogramGraphDataSerie;
@class JKSpectrum;
@class JKPeakRecord;

@interface JKDataModel : NSObject {
    int ncid;
    int numberOfPoints;
    int intensityCount;
	
    float *time;
    float *totalIntensity;

    BOOL hasSpectra;
	
    NSMutableArray *chromatograms;    
	
    NSMutableArray *peaks;
    NSMutableArray *baseline;
	NSMutableDictionary *metadata;
	
	// Search options
	BOOL penalizeForRetentionIndex;
	float retentionSlope;     // retentionIndex = retentionSlope * retentionTime +  retentionRemainder
	float retentionRemainder; //
}
//-(void)finishInit;
-(BOOL)finishInitWithError:(NSError **)anError;
-(ChromatogramGraphDataSerie *)chromatogram;
#pragma mark ACTIONS
//-(void)getChromatogramData;
-(void)getBaselineData;
-(ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString;
-(JKSpectrum *)getSpectrumForPeak:(JKPeakRecord *)peak;

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


-(NSMutableArray *)chromatograms;
//-(void)setChromatograms:(NSMutableArray *)inValue;

-(void)setPeaks:(NSMutableArray *)inValue;
-(NSMutableArray *)peaks;
-(void)setBaseline:(NSMutableArray *)inValue ;
-(NSMutableArray *)baseline;
-(NSMutableDictionary *)metadata;

-(float *)xValuesSpectrum:(int)scan;
-(float *)yValuesSpectrum:(int)scan;
-(float *)yValuesIonChromatogram:(float)mzValue;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

#pragma mark FUNCTIONS
void normalize(float *input, int count);

@end

