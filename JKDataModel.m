//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKDataModel.h"
#import "JKPeakRecord.h"
#import "ChromatogramGraphDataSerie.h"
#import "netcdf.h"
#import "JKSpectrum.h"

@implementation JKDataModel

#pragma mark INITIALIZATION

-(id)init {
    if (self = [super init]) {
		peaks = [[NSMutableArray alloc] init];
		baseline = [[NSMutableArray alloc] init];
		metadata = [[NSMutableDictionary alloc] init];
		
		chromatograms = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc {
	[peaks release];
	[baseline release];
	[metadata release];
	
	int dummy;
	dummy = nc_close(ncid);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"File closing error",@"File closing error") format:NSLocalizedString(@"Closing NetCDF file caused problem.\nNetCDF error: %d",@""), dummy];

    [super dealloc];
}

#pragma mark ACTIONS

-(BOOL)finishInitWithError:(NSError **)anError {
	JKLogEnteringMethod();
	NSDate *startT = [NSDate date];
    int		num_pts;
    float	*x;
    float 	*y;
    int     errCode, dummy, dimid, varid_scanaqtime, varid_totintens;
    BOOL	hasVarid_scanaqtime;
	
//    NS_DURING
		
	if ([self ncid] == nil) {
		[NSException raise:NSLocalizedString(@"NetCDF data absent",@"NetCDF data absent") format:NSLocalizedString(@"No id for the NetCDF file could be obtained, which is critical for accessing the data.",@"")];
		return NO;
	}
    hasVarid_scanaqtime = YES;
	
	// Checks to ensure we have a correct NetCDF file and differentiate between GC and GCMS files
	errCode = nc_inq_dimid(ncid, "scan_number", &dimid);
	if(errCode != NC_NOERR) {
		// It's not a GCMS file, perhaps a GC file?
		errCode = nc_inq_dimid(ncid, "point_number", &dimid);
		if(errCode != NC_NOERR) {
			// It's not a GC file either ...
			if (anError != NULL)
				*anError = [[[NSError alloc] initWithDomain:@"JKNetCDFDomain" code:errCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unrecognized file", NSLocalizedDescriptionKey, @"The file was not recognized as a NetCDF file that contains GC or GC/MS data.", NSLocalizedFailureReasonErrorKey, @"Try exporting from the originating application again selecting NetCDF as the export file format.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
			return NO;
		} else {
			// It's a GC file
			[self setHasSpectra:NO];
		}
		
	} else {
		// It's a GCMS file
		[self setHasSpectra:YES];
	}
//	;
    if ([self hasSpectra]) {
        // GCMS file
        dummy = nc_inq_dimid([self ncid], "scan_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension failed.\nNetCDF error: %d",@""), dummy];

        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_acquisition_time variable failed.\nNetCDF error: %d",@""), dummy];

        dummy = nc_inq_varid([self ncid], "total_intensity", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting total_intensity dimension failed.\nNetCDF error: %d",@""), dummy];
        
    } else {
        // GC file
        dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension failed.\nNetCDF error: %d",@""), dummy];
 
        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid([self ncid], "raw_data_retention", &varid_scanaqtime);
//		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting raw_data_retention variable failed.\nNetCDF error: %d",@""), dummy];
        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
        
        dummy = nc_inq_varid([self ncid], "ordinate_values", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting ordinate_values variable failed.\nNetCDF error: %d",@""), dummy];
    }

    // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
    x = (float *) malloc(num_pts*sizeof(float));
    y = (float *) malloc(num_pts*sizeof(float));

     dummy = nc_get_var_float([self ncid], varid_scanaqtime, x);
	 if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scanaqtime variables failed.\nNetCDF error: %d",@""), dummy];
     
     dummy = nc_get_var_float([self ncid], varid_totintens, y);
	 if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting totintens variables failed.\nNetCDF error: %d",@""), dummy];

     [self setTime:x withCount:num_pts];
     [self setTotalIntensity:y withCount:num_pts];
	 
	 [chromatograms addObject:[self chromatogram]];
	 
	 if ([baseline count] <= 0)
		 [self getBaselineData];
	 
	 JKLogDebug(@"Time in -[finishInitWithError:]: %g seconds", -[startT timeIntervalSinceNow]);	 
	 return YES;
//	NS_HANDLER
//		NSRunAlertPanel([NSString stringWithFormat:@"Error: %@",[localException name]], @"%@", @"OK", nil, nil, localException);
//	NS_ENDHANDLER
}	 

-(ChromatogramGraphDataSerie *)chromatogram {
	NSDate *startT = [NSDate date];
	
	 ChromatogramGraphDataSerie *chromatogram = [[ChromatogramGraphDataSerie alloc] init];
	 int i, npts;
	 float *xpts, *ypts;
	 npts = [self numberOfPoints];
	 xpts = [self time];
	 ypts = [self totalIntensity];

	 NSMutableArray *mutArray = [[NSMutableArray alloc] init];
	 for (i = 0; i < npts; i++) {
		 NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:xpts[i]/60], @"Time",
																		   [NSNumber numberWithInt:i], @"Scan",
																		   [NSNumber numberWithFloat:ypts[i]], @"Total Intensity", nil];
		 [mutArray addObject:dict];      
		 [dict release];
//		 NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
//		 [mutDict setValue:[NSNumber numberWithFloat:xpts[i]/60] forKey:@"Time"]; // converting to minutes
//		 [mutDict setValue:[NSNumber numberWithInt:i] forKey:@"Scan"];
//		 [mutDict setValue:[NSNumber numberWithFloat:ypts[i]] forKey:@"Total Intensity"];
//		 [mutArray addObject:mutDict];      
//		 [mutDict release];
	 }
	 [chromatogram setDataArray:mutArray];
	 [mutArray release];
	 
	 [chromatogram setKeyForXValue:@"Scan"];
	 [chromatogram setKeyForYValue:@"Total Intensity"];
	 [chromatogram setSeriesTitle:NSLocalizedString(@"TIC Chromatogram",@"")];
	 
	 [chromatogram autorelease];

	 JKLogDebug(@"Time in -[chromatogram]: %g seconds", -[startT timeIntervalSinceNow]);

	 return chromatogram;
}

-(void)getBaselineData {
	NSDate *startT = [NSDate date];
	// get tot intensities
	// determing running minimum
		// dilute factor is e.g. 5
		// get minimum for scan 0 - 5 = min at scan 0
		// get minimum for scan 0 - 6 = min at scan 1
		// ...
		// get minimum for scan 0 - 10 = min at scan 5
		// get minimum for scan 1 - 11 = min at scan 6
		// get minimum for scan 2 - 12 = min at scan 7
	// distance to running min
		// distance[x] = intensity[x] - minimum[x]
		// normalize distance[x] ??
	// determine slope
		// slope[x] = (intensity[x+1]-intensity[x])/(time[x+1]-time[x])
		// normalize slope[x] ??
	// determine pointdensity
		// pointdensity[x] = sum of (1/distance to point n from x) / n  how about height/width ratio then?!
		// normalize pointdensity[x] ??
	// baseline if 
		// distance[x] = 0 - 0.1 AND
		// slope[x] = -0.1 - 0 - 0.1 AND
		// pointdensity[x] = 0.9 - 1
	int i, j, count;
	count = [self numberOfPoints];
	float minimumSoFar, densitySoFar, distanceSquared;
	float minimum[count];
	float distance[count];
	float slope[count];
	float density[count];
	float *intensity;
//	float *time;
	intensity = totalIntensity;
//	time = [self time];
	
	for (i = 0; i < count; i++) {
		minimumSoFar = intensity[i];
		for (j = i - 15; j < i + 15; j++) {
			if (intensity[j] < minimumSoFar) {
				minimumSoFar = intensity[j];
			}
		}
		minimum[i] = minimumSoFar;	
	}
	
	for (i = 0; i < count; i++) {
		distance[i] = fabs(intensity[i] - minimum[i]);
	}
	
	for (i = 0; i < count-1; i++) {
		slope[i] = (fabs((intensity[i+1]-intensity[i])/(time[i+1]-time[i])) + fabs((intensity[i]-intensity[i-1])/(time[i]-time[i-1])))/2;
	}
	slope[count-1] = 0.0;
	
	for (i = 0; i < count; i++) {
		densitySoFar = 0.0;
		for (j = i-15; j < i+15; j++) {
			distanceSquared = pow(fabs(intensity[j]-intensity[i]),2) + pow(fabs(time[j]-time[i]),2);
			if (distanceSquared != 0.0) densitySoFar = densitySoFar + 1/sqrt(distanceSquared);	
		}
		density[i] = densitySoFar;		
	}
	
	normalize(distance, count);
	normalize(slope, count);
	normalize(density, count);
	
	[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Scan", [NSNumber numberWithFloat:intensity[0]], @"Total Intensity", [NSNumber numberWithFloat:time[0]], @"Time",nil]];
	for (i = 0; i < count; i++) {
		if (distance[i] < 0.05 && (slope[i] > -0.005  && slope[i] < 0.005) && density[i] > 0.05) { 
			[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"Scan", [NSNumber numberWithFloat:intensity[i]], @"Total Intensity", [NSNumber numberWithFloat:time[i]], @"Time",nil]];
		}
	}
	[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:count-1], @"Scan", [NSNumber numberWithFloat:intensity[count-1]], @"Total Intensity", [NSNumber numberWithFloat:time[count-1]], @"Time",nil]];
//	JKLogDebug([baseline description]);
	JKLogDebug(@"Time in -[baseline]: %g seconds", -[startT timeIntervalSinceNow]);

}

void normalize(float *input, int count) {
    int i;
	float maximum;
	
	maximum = fabs(input[0]);
	for (i = 1; i < count; i++) {
		if (fabs(input[i]) > maximum) maximum = fabs(input[i]);
	}
	
	for (i = 0; i < count; i++) {
		input[i] = input[i]/maximum;
	}
}
	

-(float)timeForScan:(int)scan {
    int dummy, varid_scanaqtime;
    float   x;
    
    dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
        
    dummy = nc_get_var1_float([self ncid], varid_scanaqtime, (void *) &scan, &x);
    
    return x/60;
}

-(float *)xValuesSpectrum:(int)scan {
    int dummy, start, end, varid_mass_value, varid_scan_index;
 //   float 	xx;
    float 	*x;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return x;}

	
	dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
	
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}

	scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
	
//    start = [self startValuesSpectrum:scan];
//    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
    
//	JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
 //   x = (float *) malloc((num_pts+1)*sizeof(float));
	
	x = (float *) malloc(num_pts*sizeof(float));
//	dummy = nc_get_var_float([self ncid], varid_mass_value, x);

	dummy = nc_get_vara_float([self ncid], varid_mass_value, (const size_t *) &start, (const size_t *) &num_pts, x);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return x;}
	
//    for(i = start; i < end; i++) {
//        dummy = nc_get_var1_float([self ncid], varid_mass_value, (void *) &i, &xx);
//        *(x + (i-start)) = xx;
//        if(maxXValuesSpectrum < xx) {
//            maxXValuesSpectrum = xx;
//        }
//        if(minXValuesSpectrum > xx || i == start) {
//            minXValuesSpectrum = xx;
//        }

//    }
	
    return x;    
}

-(float *)yValuesSpectrum:(int)scan {
    int dummy, start, end, varid_intensity_value, varid_scan_index;
 //   float 	yy;
    float 	*y;
    int		num_pts;

    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}

	dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
	
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
	
	scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
	
//    start = [self startValuesSpectrum:scan];
//    end = [self endValuesSpectrum:scan];
    num_pts = end - start;
	
	y = (float *) malloc((num_pts)*sizeof(float));
//	dummy = nc_get_var_float([self ncid], varid_intensity_value, y);

	dummy = nc_get_vara_float([self ncid], varid_intensity_value, (const size_t *) &start, (const size_t *) &num_pts, y);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return y;}
	
//	//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;	
//    for(i = start; i < end; i++) {
//        dummy = nc_get_var1_float([self ncid], varid_intensity_value, (void *) &i, &yy);
//        *(y + (i-start)) = yy;
//		//        if(maxXValuesSpectrum < yy) {
//		//            maxXValuesSpectrum = yy;
//		//        }
//		//        if(minXValuesSpectrum > yy || i == start) {
//		//            minXValuesSpectrum = yy;
//		//        }
//		
//    }
	
    return y;
}

-(ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString {
	NSMutableArray *mzValues = [NSMutableArray array];
	NSArray *mzValuesPlus = [inString componentsSeparatedByString:@"+"];
	
	int i,j,k, mzValuesCount;
	for (i = 0; i < [mzValuesPlus count]; i++) {
		NSArray *mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
				for (j = [[mzValuesMin objectAtIndex:0] intValue]; j < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
					[mzValues addObject:[NSNumber numberWithInt:j]];
				}
			} else {
				for (j = [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j < [[mzValuesMin objectAtIndex:0] intValue]; j++) {
					[mzValues addObject:[NSNumber numberWithInt:j]];
				}
			}
		} else {
			[mzValues addObject:[NSNumber numberWithInt:[[mzValuesMin objectAtIndex:0] intValue]]];
		}
	}

	NSString *mzValuesString = [NSString stringWithFormat:@"%d",[[mzValues objectAtIndex:0] intValue]];
	mzValuesCount = [mzValues count];
	for (i = 1; i < mzValuesCount; i++) {
		mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];
	}
	// JKLogDebug(mzValuesString);
	
	
    int     dummy, scan, dimid, varid_intensity_value, varid_mass_value, varid_time_value, varid_scan_index, varid_point_count;
    float  timeL, mass, intensity;
    float	*times, *masses,	*intensities;
    int		num_pts, num_scan, scanCount;
    
    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}

    dummy = nc_inq_varid([self ncid], "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting varid_scan_index variable failed. Report error #%d.", dummy); return nil;}

    dummy = nc_inq_varid([self ncid], "point_count", &varid_point_count);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_count variable failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}

    dummy = nc_inq_dimid([self ncid], "scan_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_scan);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return nil;}
    
	masses = (float *) malloc((num_scan)*sizeof(float));
	times = (float *) malloc((num_scan)*sizeof(float));
	intensities = (float *) malloc((num_scan)*sizeof(float));

	for(i = 0; i < num_scan; i++) {
		dummy = nc_get_var1_int([self ncid], varid_scan_index, (void *) &i, &scan); // is this the start or the end?
		dummy = nc_get_var1_int([self ncid], varid_point_count, (void *) &i, &scanCount);
		for(j = scan; j < scan+scanCount; j++) {
			dummy = nc_get_var1_float([self ncid], varid_mass_value, (void *) &j, &mass);
			for(k = 0; k < mzValuesCount; k++) {
				if (fabs(mass-[[mzValues objectAtIndex:k] intValue]) < 0.5) {
					dummy = nc_get_var1_float([self ncid], varid_time_value, (const size_t *) &j, &timeL);
					dummy = nc_get_var1_float([self ncid], varid_intensity_value, (const size_t *) &j, &intensity);
					
					masses[i] = mass;
					times[i] = [self timeForScan:i];
					intensities[i] = intensities[i] + intensity;
				}
			}
		}
	}
	ChromatogramGraphDataSerie *chromatogram;

    //create a chromatogram object
    chromatogram = [[ChromatogramGraphDataSerie alloc] init];
	NSMutableArray *mutArray = [[NSMutableArray alloc] init];
	
    for(i=0;i<num_scan;i++){
		NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
		[mutDict setValue:[NSNumber numberWithFloat:times[i]] forKey:@"Time"];
		[mutDict setValue:[NSNumber numberWithInt:i] forKey:@"Scan"];
		[mutDict setValue:[NSNumber numberWithFloat:intensities[i]] forKey:@"Total Intensity"];
		[mutArray addObject:mutDict];      
		[mutDict release];
    }
	//JKLogDebug([mutArray description]);
	[chromatogram setDataArray:mutArray];
	[mutArray release];
	
	[chromatogram setSeriesTitle:mzValuesString];
	[chromatogram setSeriesColor:[NSColor redColor]];
	
	[chromatogram setKeyForXValue:@"Scan"];
	[chromatogram setKeyForYValue:@"Total Intensity"];
	
	[chromatogram autorelease];
	
	return chromatogram;
}	

-(float *)yValuesIonChromatogram:(float)mzValue {
    int         i, dummy, dimid, varid_intensity_value, varid_mass_value;
    float     	xx, yy;
    float 	*y;
    int		num_pts, scanCount;
    scanCount = 0;
    
    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return y;}
    
    dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return y;}
    
	
	//	dummy = nc_get_vara_float([self ncid], varid_intensity_value, (const size_t *) &i, (const size_t *) &num_pts, &xx);
	//	nc_get_vara_float(int ncid, int varid,
	//					   const size_t *startp, const size_t *countp, float *ip);
    for(i = 0; i < num_pts; i++) {
        dummy = nc_get_var1_float([self ncid], varid_mass_value, (void *) &i, &xx);
        if (fabs(xx-mzValue) < 0.5) {
            y = (float *) malloc((scanCount+1)*sizeof(float));
            dummy = nc_get_var1_float([self ncid], varid_intensity_value, (const size_t *) &i, &yy);
			// *(y + (scanCount)) = yy;
            y[scanCount] = yy;
//			JKLogDebug(@"scan %d: mass %f = %f %f", scanCount, xx, yy, y[scanCount]);
            scanCount++;
        } else {
			
		}
    };
    JKLogDebug(@"scanCount = %d", scanCount);
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

-(JKSpectrum *)getSpectrumForPeak:(JKPeakRecord *)peak {
	JKSpectrum *spectrum = [[JKSpectrum alloc] init];
	float *xpts, *ypts;
	int scan;
	int dummy, start, end, varid_mass_value, varid_intensity_value, varid_scan_index;
    int num_pts;
	
	scan = [[peak valueForKey:@"top"] intValue];

	dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return nil;}
	
	scan++;
	
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return nil;}
	
    num_pts = end - start;
	
	dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}
	
	
	xpts = (float *) malloc(num_pts*sizeof(float));
	
	dummy = nc_get_vara_float([self ncid], varid_mass_value, (const size_t *) &start, (const size_t *) &num_pts, xpts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return nil;}
	
	[spectrum setMasses:xpts withCount:num_pts];

				
	ypts = (float *) malloc((num_pts)*sizeof(float));

	dummy = nc_get_vara_float([self ncid], varid_intensity_value, (const size_t *) &start, (const size_t *) &num_pts, ypts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return nil;}
	
	[spectrum setIntensities:ypts withCount:num_pts];

	free(xpts);
	free(ypts);
	
	[spectrum setValue:[NSNumber numberWithFloat:[self timeForScan:scan]] forKey:@"retentionTime"];
	
	[spectrum autorelease];
	return spectrum;
}


#pragma mark NSCODING
-(void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeObject:[self baseline] forKey:@"baseline"];
		[coder encodeObject:[self peaks] forKey:@"peaks"];
		[coder encodeObject:[self metadata] forKey:@"metadata"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		baseline = [[coder decodeObjectForKey:@"baseline"] retain];
		peaks = [[coder decodeObjectForKey:@"peaks"] retain];
		metadata = [[coder decodeObjectForKey:@"metadata"] retain];
		if(metadata == nil) {
			metadata = [[NSMutableDictionary alloc] init];
		}
		
		chromatograms = [[NSMutableArray alloc] init];
	} 
    return self;
}
#pragma mark ACCESSORS
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

//-(float)maxTime {
//    return maxTime;
//}
//
//-(float)minTime {
//    return minTime;
//}
//
//-(float)maxTotalIntensity {
//    return maxTotalIntensity;
//}
//
//-(float)minTotalIntensity {
//    return minTotalIntensity;
//}
//
//-(float)maxXValuesSpectrum {
//    return maxXValuesSpectrum;
//}
//
//-(float)minXValuesSpectrum {
//    return minXValuesSpectrum;
//}
//
//-(float)maxYValuesSpectrum {
//    return maxYValuesSpectrum;
//}
//
//-(float)minYValuesSpectrum {
//    return minYValuesSpectrum;
//}

-(void)setPeaks:(NSMutableArray *)inValue {
	[inValue retain];
	[peaks autorelease];
	peaks = inValue;
}

-(NSMutableArray *)peaks {
	return peaks;
}
-(NSMutableDictionary *)metadata {
	return metadata;
}

-(void)setBaseline:(NSMutableArray *)inValue {
	[inValue retain];
	[baseline autorelease];
	baseline = inValue;
}

-(NSMutableArray *)baseline {
	return baseline;
}

-(NSMutableArray *)chromatograms {
	return chromatograms;
}


@end

