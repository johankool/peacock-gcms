//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class ChromatogramGraphDataSerie;

@interface JKDataModel : NSObject {
    int ncid;
    int numberOfPoints;
    int intensityCount;
	
    double *time;
    double *totalIntensity;
//	double *times;
//	double *intensities;
	
 //   double maxTime;
//    double minTime;
//    double maxTotalIntensity;
//    double minTotalIntensity;
//    
//    double maxXValuesSpectrum;
//    double minXValuesSpectrum;
//    double maxYValuesSpectrum;
//    double minYValuesSpectrum;   

    BOOL hasSpectra;
	
    NSMutableArray *chromatograms;    
	
    NSMutableArray *peaks;
    NSMutableArray *baseline;
	NSMutableDictionary *metadata;
	
	// Search options
	BOOL penalizeForRetentionIndex;
	double retentionSlope;     // retentionIndex = retentionSlope * retentionTime +  retentionRemainder
	double retentionRemainder; //
}
//-(void)finishInit;
-(BOOL)finishInitWithError:(NSError **)anError;
-(ChromatogramGraphDataSerie *)chromatogram;
#pragma mark ACTIONS
//-(void)getChromatogramData;
-(void)getBaselineData;
-(ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString;

#pragma mark ACCESSORS
-(void)setNcid:(int)inValue;
-(int)ncid;

-(int)numberOfPoints;

-(void)setHasSpectra:(BOOL)inValue;
-(BOOL)hasSpectra;

-(int)intensityCount;
-(void)setIntensityCount:(int)inValue;

-(void)setTime:(double *)inArray withCount:(int)inValue;
-(double *)time;
-(double)timeForScan:(int)scan;

-(void)setTotalIntensity:(double *)inArray withCount:(int)inValue;
-(double *)totalIntensity;

//-(double)maxTime;
//-(double)minTime;
//-(double)maxTotalIntensity;
//-(double)minTotalIntensity;
//
//-(double)maxXValuesSpectrum;
//-(double)minXValuesSpectrum;
//-(double)maxYValuesSpectrum;
//-(double)minYValuesSpectrum;

-(NSMutableArray *)chromatograms;
//-(void)setChromatograms:(NSMutableArray *)inValue;

-(void)setPeaks:(NSMutableArray *)inValue;
-(NSMutableArray *)peaks;
-(void)setBaseline:(NSMutableArray *)inValue ;
-(NSMutableArray *)baseline;
-(NSMutableDictionary *)metadata;

-(float *)xValuesSpectrum:(int)scan;
-(float *)yValuesSpectrum:(int)scan;
-(double *)yValuesIonChromatogram:(double)mzValue;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

#pragma mark FUNCTIONS
void normalize(double *input, int count);

@end

