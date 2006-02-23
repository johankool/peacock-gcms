//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKSpectrum;
@class JKMainDocument;

@interface JKChromatogram : NSObject {
    JKMainDocument *document;
    
    int ncid;
    int numberOfPoints;
    
    double *time;
    double *totalIntensity;

    double maxTime;
    double minTime;
    double maxTotalIntensity;
    double minTotalIntensity;
    
    double maxXValuesSpectrum;
    double minXValuesSpectrum;
    double maxYValuesSpectrum;
    double minYValuesSpectrum;   

}


#pragma mark INITIALIZATION
/*! @functiongroup Initialization */

/*! Designated initializer. */
-(id)initWithDocument:(JKMainDocument *)inDocument;

#pragma mark ACCESSORS
/*! @functiongroup Accessors */

/*! The document containing our chromatogram. */
-(JKMainDocument *)document;

/*! Set ID needed for reading NetCDF file. */
-(void)setNcid:(int)inValue;

/*! ID needed for reading NetCDF file. */
-(int)ncid;
-(int)numberOfPoints;

-(void)setTime:(double *)inArray withCount:(int)inValue;
/*! Returns array of doubles for the time. */
-(double *)time;

-(void)setTotalIntensity:(double *)inArray withCount:(int)inValue;
-(double *)totalIntensity;

-(unsigned int)countOfSpectra;
-(JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index;

#pragma mark PROPERTIES 

-(double)timeForScan:(int)scan;

-(double)maxTime;
-(double)minTime;
-(double)maxTotalIntensity;
-(double)minTotalIntensity;

-(double)maxXValuesSpectrum;
-(double)minXValuesSpectrum;
-(double)maxYValuesSpectrum;
-(double)minYValuesSpectrum;



#pragma mark ACTIONS

-(void)getChromatogramData;
-(double *)xValuesSpectrum:(int)scan;
-(double *)yValuesSpectrum:(int)scan;
-(int)startValuesSpectrum:(int)scan;
-(int)endValuesSpectrum:(int)scan;

@end

