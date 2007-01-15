//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKSpectrum;
@class JKGCMSDocument;
@class ChromatogramGraphDataSerie;

@interface JKChromatogram : NSObject {
    JKGCMSDocument *document;
    NSString *model;
    NSMutableArray *baseline;
    
    int ncid;
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


#pragma mark INITIALIZATION
/*! @functiongroup Initialization */

-(id)initWithDocument:(JKGCMSDocument *)inDocument;
    /*! Designated initializer. */
-(id)initWithDocument:(JKGCMSDocument *)inDocument forModel:(NSString *)model;


#pragma mark ACTIONS

- (void)obtainBaseline;
- (void)identifyPeaks;

- (ChromatogramGraphDataSerie *)chromatogramDataSerie;


#pragma mark ACCESSORS
/*! @functiongroup Accessors */

/*! The document containing our chromatogram. */
-(JKGCMSDocument *)document;

/*! ID needed for reading NetCDF file. */
-(int)ncid;
-(void)setNcid:(int)inValue;
-(int)numberOfPoints;

/*! Returns array of floats for the time. */
-(float *)time;
-(void)setTime:(float *)inArray withCount:(int)inValue;

-(float *)totalIntensity;
-(void)setTotalIntensity:(float *)inArray withCount:(int)inValue;

-(unsigned int)countOfSpectra;

-(float)timeForScan:(int)scan;

-(float)maxTime;
-(float)minTime;
-(float)maxTotalIntensity;
-(float)minTotalIntensity;

#pragma mark OBSOLETE

- (void)getChromatogramData;

-(JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index;
-(float *)xValuesSpectrum:(int)scan;
-(float *)yValuesSpectrum:(int)scan;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;
-(float)maxXValuesSpectrum;
-(float)minXValuesSpectrum;
-(float)maxYValuesSpectrum;
-(float)minYValuesSpectrum;

@end

