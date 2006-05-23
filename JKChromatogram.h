//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKSpectrum;
@class JKGCMSDocument;

@interface JKChromatogram : NSObject {
    JKGCMSDocument *document;
    
    int ncid;
    int numberOfPoints;
    
    float *time;
    float *totalIntensity;

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

/*! Designated initializer. */
-(id)initWithDocument:(JKGCMSDocument *)inDocument;

#pragma mark ACCESSORS
/*! @functiongroup Accessors */

/*! The document containing our chromatogram. */
-(JKGCMSDocument *)document;

/*! Set ID needed for reading NetCDF file. */
-(void)setNcid:(int)inValue;

/*! ID needed for reading NetCDF file. */
-(int)ncid;
-(int)numberOfPoints;

-(void)setTime:(float *)inArray withCount:(int)inValue;
/*! Returns array of floats for the time. */
-(float *)time;

-(void)setTotalIntensity:(float *)inArray withCount:(int)inValue;
-(float *)totalIntensity;

-(unsigned int)countOfSpectra;
-(JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index;

#pragma mark PROPERTIES 

-(float)timeForScan:(int)scan;

-(float)maxTime;
-(float)minTime;
-(float)maxTotalIntensity;
-(float)minTotalIntensity;

-(float)maxXValuesSpectrum;
-(float)minXValuesSpectrum;
-(float)maxYValuesSpectrum;
-(float)minYValuesSpectrum;



#pragma mark ACTIONS

-(void)getChromatogramData;
-(float *)xValuesSpectrum:(int)scan;
-(float *)yValuesSpectrum:(int)scan;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

@end

