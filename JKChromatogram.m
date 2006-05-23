//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKChromatogram.h"
#import "JKSpectrum.h"
#import "JKGCMSDocument.h"
#import "netcdf.h"
#import "JKDataModel.h"

@implementation JKChromatogram

#pragma mark INITIALIZATION

-(id)init {
    return [self initWithDocument:nil];
}

-(id)initWithDocument:(JKGCMSDocument *)inDocument {
    // designated initializer
    if (self = [super init]) {
        document = inDocument;
    }
    return self;
}

#pragma mark ACCESSORS

-(JKGCMSDocument *)document {
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

-(void)setTime:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    time = (float *) realloc(time, numberOfPoints*sizeof(float));
    memcpy(time, inArray, numberOfPoints*sizeof(float));
}

-(float *)time {
    return time;
}

-(void)setTotalIntensity:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    totalIntensity = (float *) realloc(totalIntensity, numberOfPoints*sizeof(float));
    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(float));
}

-(float *)totalIntensity {
    return totalIntensity;
}

-(float)maxTime {
    return maxTime;
}

-(float)minTime {
    return minTime;
}

-(float)maxTotalIntensity {
    return maxTotalIntensity;
}

-(float)minTotalIntensity {
    return minTotalIntensity;
}

-(float)maxXValuesSpectrum {
    return maxXValuesSpectrum;
}

-(float)minXValuesSpectrum {
    return minXValuesSpectrum;
}

-(float)maxYValuesSpectrum {
    return maxYValuesSpectrum;
}

-(float)minYValuesSpectrum {
    return minYValuesSpectrum;
}


#pragma mark ACTIONS

//-(void)getChromatogramData
//{
//    int		num_pts;
//    float	*x;
//    float 	*y;
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
//    // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
//    x = (float *) malloc(num_pts*sizeof(float));
//    y = (float *) malloc(num_pts*sizeof(float));
//
//     dummy = nc_get_var_float([self ncid], varid_scanaqtime, x);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scanaqtime variables failed. Report error #%d.", dummy); return;}
//     minTime = 0.0; maxTime = 3600.0; // replace with sensible times
//     
//     dummy = nc_get_var_float([self ncid], varid_totintens, y);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting totintens variables failed. Report error #%d.", dummy); return;}
//     minTotalIntensity = 0.0; maxTotalIntensity = 1e8; // replace with sensible values
//
//     [self setTime:x withCount:num_pts];
//     [self setTotalIntensity:y withCount:num_pts];
//
//    //    JKLogDebug(@"Read time: %g seconds", -[startT timeIntervalSinceNow]);
//}

-(float)timeForScan:(int)scan {
    int dummy, varid_scanaqtime;
    float   x;
    
    dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
        
    dummy = nc_get_var1_float([self ncid], varid_scanaqtime, (void *) &scan, &x);
    
    return x;
}

-(float *)xValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_mass_value;
    float 	xx;
    float 	*x;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return x;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
    x = (float *) malloc((num_pts+1)*sizeof(float));

    for(i = start; i < end; i++) {
        dummy = nc_get_var1_float([self ncid], varid_mass_value, (void *) &i, &xx);
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

-(float *)yValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_intensity_value;
    float     	yy;
    float 	*y;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
    y = (float *) malloc((num_pts)*sizeof(float));
    
//    dummy = nc_get_vara_float([self ncid], varid_intensity_value, start, num_pts, y);
//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;
 
    for(i = start; i < end; i++) {
        dummy = nc_get_var1_float([self ncid], varid_intensity_value, (void *) &i, &yy);
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

