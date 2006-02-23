//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2004 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"

@class JKMainDocument;

@interface JKDataModel : NSObject {
    JKMainDocument *document;
    int ncid;
    int numberOfPoints;
    int intensityCount;
	
    double *time;
    double *totalIntensity;
	double *times;
	double *intensities;
	
    double maxTime;
    double minTime;
    double maxTotalIntensity;
    double minTotalIntensity;
    
    double maxXValuesSpectrum;
    double minXValuesSpectrum;
    double maxYValuesSpectrum;
    double minYValuesSpectrum;   

    BOOL hasSpectra;
    
    NSMutableArray *peaks;
    NSMutableArray *baseline;
}


#pragma mark INITIALIZATION

-(id)initWithDocument:(JKMainDocument *)inDocument;
    // designated initializer

#pragma mark ACCESSORS

-(JKMainDocument *)document;

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

-(double)maxTime;
-(double)minTime;
-(double)maxTotalIntensity;
-(double)minTotalIntensity;

-(double)maxXValuesSpectrum;
-(double)minXValuesSpectrum;
-(double)maxYValuesSpectrum;
-(double)minYValuesSpectrum;


-(void)setPeaks:(NSMutableArray *)inValue;
-(NSMutableArray *)peaks;
-(void)setBaseline:(NSMutableArray *)inValue ;
-(NSMutableArray *)baseline;

#pragma mark ACTIONS

//-(void)getChromatogramData;
-(double *)xValuesSpectrum:(int)scan;
-(double *)yValuesSpectrum:(int)scan;
-(double *)intensities;
-(double *)yValuesIonChromatogram:(double)mzValue;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

@end

