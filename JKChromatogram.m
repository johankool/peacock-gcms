//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKChromatogram.h"
#import "JKSpectrum.h"
#import "JKMainDocument.h"
#import "netcdf.h"
#import "JKDataModel.h"

@implementation JKChromatogram

#pragma mark INITIALIZATION

-(id)init {
    return [self initWithDocument:nil];
}

-(id)initWithDocument:(JKMainDocument *)inDocument {
    // designated initializer
    if (self = [super init]) {
        document = inDocument;
    }
    return self;
}

#pragma mark ACCESSORS

-(JKMainDocument *)document {
    return document;
}

-(void)setNcid:(int)inValue {
    ncid = inValue;
}

-(int)ncid {
    return ncid;
}

-(int)numberOfPoints {
    return numberOfPoints;
}

-(void)setTime:(double *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    time = (double *) realloc(time, numberOfPoints*sizeof(double));
    memcpy(time, inArray, numberOfPoints*sizeof(double));
}

-(double *)time {
    return time;
}

-(void)setTotalIntensity:(double *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    totalIntensity = (double *) realloc(totalIntensity, numberOfPoints*sizeof(double));
    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(double));
}

-(double *)totalIntensity {
    return totalIntensity;
}

-(double)maxTime {
    return maxTime;
}

-(double)minTime {
    return minTime;
}

-(double)maxTotalIntensity {
    return maxTotalIntensity;
}

-(double)minTotalIntensity {
    return minTotalIntensity;
}

-(double)maxXValuesSpectrum {
    return maxXValuesSpectrum;
}

-(double)minXValuesSpectrum {
    return minXValuesSpectrum;
}

-(double)maxYValuesSpectrum {
    return maxYValuesSpectrum;
}

-(double)minYValuesSpectrum {
    return minYValuesSpectrum;
}


#pragma mark ACTIONS

//-(void)getChromatogramData
//{
//    int		num_pts;
//    double	*x;
//    double 	*y;
//    int     	dummy, dimid, varid_scanaqtime, varid_totintens;
//    BOOL	hasVarid_scanaqtime;
//    
//    // NSDate *startT;
//    // startT = [NSDate date];
//    hasVarid_scanaqtime = YES;
//
//    if ([[[self document] dataModel] hasSpectra]) {
//        // GCMS file
//        dummy = nc_inq_dimid([self ncid], "scan_number", &dimid);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return; }
//
//        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return;}
//        
//        dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return;}
//
//        dummy = nc_inq_varid([self ncid], "total_intensity", &varid_totintens);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting total_intensity variable failed. Report error #%d.", dummy);  return;}
//        
//    } else {
//        // GC file
//        dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return;}
//
//        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return;}
//        
//        dummy = nc_inq_varid([self ncid], "raw_data_retention", &varid_scanaqtime);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
//        
//        dummy = nc_inq_varid([self ncid], "ordinate_values", &varid_totintens);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting ordinate_values variable failed. Report error #%d.", dummy);            return;}
//    }
//
//    // stored as doubles in file, but I need doubles which can be converted automatically by NetCDF so no worry!
//    x = (double *) malloc(num_pts*sizeof(double));
//    y = (double *) malloc(num_pts*sizeof(double));
//
//     dummy = nc_get_var_double([self ncid], varid_scanaqtime, x);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scanaqtime variables failed. Report error #%d.", dummy); return;}
//     minTime = 0.0; maxTime = 3600.0; // replace with sensible times
//     
//     dummy = nc_get_var_double([self ncid], varid_totintens, y);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting totintens variables failed. Report error #%d.", dummy); return;}
//     minTotalIntensity = 0.0; maxTotalIntensity = 1e8; // replace with sensible values
//
//     [self setTime:x withCount:num_pts];
//     [self setTotalIntensity:y withCount:num_pts];
//
//    //    JKLogDebug(@"Read time: %g seconds", -[startT timeIntervalSinceNow]);
//}

-(double)timeForScan:(int)scan {
    int dummy, varid_scanaqtime;
    double   x;
    
    dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
        
    dummy = nc_get_var1_double([self ncid], varid_scanaqtime, (void *) &scan, &x);
    
    return x;
}

-(double *)xValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_mass_value;
    double 	xx;
    double 	*x;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return x;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
    x = (double *) malloc((num_pts+1)*sizeof(double));

    for(i = start; i < end; i++) {
        dummy = nc_get_var1_double([self ncid], varid_mass_value, (void *) &i, &xx);
        *(x + (i-start)) = xx;
        if(maxXValuesSpectrum < xx) {
            maxXValuesSpectrum = xx;
        }
        if(minXValuesSpectrum > xx || i == start) {
            minXValuesSpectrum = xx;
        }

    }

    return x;    
}

-(double *)yValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_intensity_value;
    double     	yy;
    double 	*y;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
    y = (double *) malloc((num_pts)*sizeof(double));
    
//    dummy = nc_get_vara_double([self ncid], varid_intensity_value, start, num_pts, y);
//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;
 
    for(i = start; i < end; i++) {
        dummy = nc_get_var1_double([self ncid], varid_intensity_value, (void *) &i, &yy);
        *(y + (i-start)) = yy;
        if(maxYValuesSpectrum < yy) {
            maxYValuesSpectrum = yy;
        }
        if(minYValuesSpectrum > yy || i == start) {
            minYValuesSpectrum = yy;
        }
    };

    return y;
}

-(int)startValuesSpectrum:(int)scan {
    int dummy, start, varid_scan_index;

    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}

    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}

    return start;
}


-(int)endValuesSpectrum:(int)scan {
    int dummy, end, varid_scan_index;

    dummy = nc_inq_varid([self ncid], "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}

    scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}

    return end;
}


-(unsigned int)countOfSpectra {
    // implementation specific code
    return [self numberOfPoints]; 
}

-(JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index {
    // implementation specific code
    return nil;
}
@end

