//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2004 Johan Kool. All rights reserved.
//

#import "JKDataModel.h"
#import "JKMainDocument.h"
#import "netcdf.h"


@implementation JKDataModel

#pragma mark INITIALIZATION

-(id)init {
    return [self initWithDocument:nil];
}

-(id)initWithDocument:(JKMainDocument *)inDocument
{
    // designated initializer
    if (self = [super init]) {
        document = inDocument;
        
        peaks = [[NSMutableArray alloc] init];
		baseline = [[NSMutableArray alloc] init];
				
		//[self getChromatogramData];
		
//		// for debugging:
		[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"0", @"scan", @"100000", @"intensity",nil]];
		[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"2800", @"scan", @"100000", @"intensity",nil]];
    }
    return self;
}

-(void) dealloc
{
    free(intensities);
	[peaks release];
	[baseline release];
    [super dealloc];
}



#pragma mark ACCESSORS

-(JKMainDocument *)document
{
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

-(void)setHasSpectra:(BOOL)inValue {
    hasSpectra = inValue;
}

-(BOOL)hasSpectra {
    return hasSpectra;
}

-(int)intensityCount {
    return intensityCount;
}
-(void)setIntensityCount:(int)inValue {
    intensityCount = inValue;
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

-(void)setPeaks:(NSMutableArray *)inValue {
	[inValue retain];
	[peaks autorelease];
	peaks = inValue;
}

-(NSMutableArray *)peaks {
	return peaks;
}

-(void)setBaseline:(NSMutableArray *)inValue {
	[inValue retain];
	[baseline autorelease];
	baseline = inValue;
}

-(NSMutableArray *)baseline {
	return baseline;
}


#pragma mark ACTIONS

-(void)getChromatogramData
{
    int		num_pts;
    double	*x;
    double 	*y;
    int     	dummy, dimid, varid_scanaqtime, varid_totintens;
    BOOL	hasVarid_scanaqtime;
    
    // NSDate *startT;
    // startT = [NSDate date];
    hasVarid_scanaqtime = YES;

    if ([self hasSpectra]) {
        // GCMS file
        dummy = nc_inq_dimid([self ncid], "scan_number", &dimid);
		if(dummy != NC_NOERR) { NSBeep(); NSRunCriticalAlertPanel(@"Error reading file",@"Getting scan_number dimension failed.",@"OK",nil,nil); NSLog(@"Getting scan_number dimension failed. Report error #%d.", dummy); return; }
//        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_number dimension failed. Report error #%d.", dummy); return; }

        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return;}
        
        dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return;}

        dummy = nc_inq_varid([self ncid], "total_intensity", &varid_totintens);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting total_intensity variable failed. Report error #%d.", dummy);  return;}
        
    } else {
        // GC file
        dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension failed. Report error #%d.", dummy); return;}

        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension length failed. Report error #%d.", dummy); return;}
        
        dummy = nc_inq_varid([self ncid], "raw_data_retention", &varid_scanaqtime);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
        
        dummy = nc_inq_varid([self ncid], "ordinate_values", &varid_totintens);
        if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting ordinate_values variable failed. Report error #%d.", dummy);            return;}
    }

    // stored as doubles in file, but I need doubles which can be converted automatically by NetCDF so no worry!
    x = (double *) malloc(num_pts*sizeof(double));
    y = (double *) malloc(num_pts*sizeof(double));

     dummy = nc_get_var_double([self ncid], varid_scanaqtime, x);
     if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scanaqtime variables failed. Report error #%d.", dummy); return;}
     minTime = 0.0; maxTime = 3600.0; // replace with sensible times
     
     dummy = nc_get_var_double([self ncid], varid_totintens, y);
     if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting totintens variables failed. Report error #%d.", dummy); return;}
     minTotalIntensity = 0.0; maxTotalIntensity = 1e8; // replace with sensible values

     [self setTime:x withCount:num_pts];
     [self setTotalIntensity:y withCount:num_pts];

    //    NSLog(@"Read time: %g seconds", -[startT timeIntervalSinceNow]);
}

-(double)timeForScan:(int)scan {
    int dummy, varid_scanaqtime;
    double   x;
    
    dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
        
    dummy = nc_get_var1_double([self ncid], varid_scanaqtime, (void *) &scan, &x);
    
    return x/60;
}

-(double *)xValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_mass_value;
    double 	xx;
    double 	*x;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting mass_value variable failed. Report error #%d.", dummy);        return x;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
//	NSLog(@"start= %d, end = %d, count = %d",start, end, num_pts);
 //   x = (double *) malloc((num_pts+1)*sizeof(double));
	
	x = (double *) malloc(num_pts*sizeof(double));
//	dummy = nc_get_var_double([self ncid], varid_mass_value, x);

//	dummy = nc_get_vara_double([self ncid], varid_mass_value, (const size_t *) &i, (const size_t *) &num_pts, x);
//    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting mass_values failed. Report error #%d.", dummy); return x;}
	
    for(i = start; i < end; i++) {
        dummy = nc_get_var1_double([self ncid], varid_mass_value, (void *) &i, &xx);
        *(x + (i-start)) = xx;
//        if(maxXValuesSpectrum < xx) {
//            maxXValuesSpectrum = xx;
//        }
//        if(minXValuesSpectrum > xx || i == start) {
//            minXValuesSpectrum = xx;
//        }

    }
	
    return x;    
}

-(double *)yValuesSpectrum:(int)scan {
    int i, dummy, start, end, varid_intensity_value;
    double 	yy;
    double 	*y;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}

    start = [self startValuesSpectrum:scan];
    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
	
	y = (double *) malloc((num_pts)*sizeof(double));
//	dummy = nc_get_var_double([self ncid], varid_intensity_value, y);

//	dummy = nc_get_vara_double([self ncid], varid_intensity_value, (const size_t *) &i, (const size_t *) &num_pts, y);
//    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting intensity_values failed. Report error #%d.", dummy); return y;}
	
	//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;	
    for(i = start; i < end; i++) {
        dummy = nc_get_var1_double([self ncid], varid_intensity_value, (void *) &i, &yy);
        *(y + (i-start)) = yy;
		//        if(maxXValuesSpectrum < yy) {
		//            maxXValuesSpectrum = yy;
		//        }
		//        if(minXValuesSpectrum > yy || i == start) {
		//            minXValuesSpectrum = yy;
		//        }
		
    }
	
    return y;
}

-(double *)intensities {
    int     dummy, dimid, varid_intensity_value, num_pts;
	
	// We only read this in when required, keeping it around if it's needed again
    if (intensities == nil) {	
		dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
		if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting intensity_value variable failed. Report error #%d.", dummy); return intensities;}
		
		dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
		if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension failed. Report error #%d.", dummy); return intensities;}
		
		dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
		if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension length failed. Report error #%d.", dummy); return intensities;}
		
		intensities = (double *) malloc((num_pts)*sizeof(double));
		dummy = nc_get_var_double([self ncid], varid_intensity_value, intensities);
		if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting intensity_values failed. Report error #%d.", dummy); return intensities;}
		
		[self setIntensityCount:num_pts];
	}
    return intensities;
}

-(double *)yValuesIonChromatogram:(double)mzValue {
    int         i, dummy, dimid, varid_intensity_value, varid_mass_value;
    double     	xx, yy;
    double 	*y;
    int		num_pts, scanCount;
    scanCount = 0;
    
    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting mass_values variable failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting point_number dimension length failed. Report error #%d.", dummy); return y;}
    
	
	//	dummy = nc_get_vara_double([self ncid], varid_intensity_value, (const size_t *) &i, (const size_t *) &num_pts, &xx);
	//	nc_get_vara_double(int ncid, int varid,
	//					   const size_t *startp, const size_t *countp, double *ip);
    for(i = 0; i < num_pts; i++) {
        dummy = nc_get_var1_double([self ncid], varid_mass_value, (void *) &i, &xx);
        if (fabs(xx-mzValue) < 0.5) {
            y = (double *) malloc((scanCount+1)*sizeof(double));
            dummy = nc_get_var1_double([self ncid], varid_intensity_value, (const size_t *) &i, &yy);
			// *(y + (scanCount)) = yy;
            y[scanCount] = yy;
			//         NSLog(@"scan %d: mass %f = %f %f", scanCount, xx, yy, y[scanCount]);
            scanCount++;
        }
    };
    
    return y;
}

-(int)startValuesSpectrum:(int)scan {
    int dummy, start, varid_scan_index;

    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}

    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}

    return start;
}


-(int)endValuesSpectrum:(int)scan {
    int dummy, end, varid_scan_index;

    dummy = nc_inq_varid([self ncid], "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}

    scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); NSLog(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}

    return end;
}


-(void)encodeWithCoder:(NSCoder *)coder
{
//    [super encodeWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeObject:[self baseline] forKey:@"baseline"];
		[coder encodeObject:[self peaks] forKey:@"peaks"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
//    self = [super initWithCoder:coder];
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		[self setBaseline:[coder decodeObjectForKey:@"baseline"]];
		[self setPeaks:[coder decodeObjectForKey:@"peaks"]];
      } 
    return self;
}

@end

