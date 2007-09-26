//
//  PKGCMSMeasurement.m
//  Peacock1
//
//  Created by Johan Kool on 13-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKGCMSMeasurement.h"

#import "PKChromatogram.h"
#import "PKTICChromatogram.h"
#import "netcdf.h"
#import "JKSpectrum.h"
#import "NSString+ModelCompare.h"
#include "jk_statistics.h"

@implementation PKGCMSMeasurement

- (id)initWithFilePath:(NSString *)filePath
{
	self = [super init];
    if (self != nil) {
        chromatograms = [[NSMutableArray alloc] init];
        NSLog(@"init meas %@", filePath);
        [self setLabel:[filePath lastPathComponent]];
        if ([self readNetCDFFile:filePath error:NULL]) {
            NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithPath:filePath];
            [fileWrapper setPreferredFilename:uniqueID];
            PKChromatogram *ticChromatogram = [self ticChromatogram];
            if (!ticChromatogram) {
                NSLog(@"Could not obtain TIC");
                return nil;
            }
            
            [chromatograms insertValue:ticChromatogram atIndex:0 inPropertyWithKey:@"chromatograms"];
       } else {
            NSLog(@"Could not init PKGCMSMeasurement.");
            return nil;
        }
   	}
    return self;
}

- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError {
	int errCode;
    int dimid;
    BOOL	hasVarid_scanaqtime;
    
	// Get the file's name and pull the id. Test to make sure that this all worked.
	errCode = nc_open([fileName cString], NC_NOWRITE, &ncid);
	if (errCode != NC_NOERR) {
		if (anError != NULL)
			*anError = [[[NSError alloc] initWithDomain:@"JKNetCDFDomain" 
												   code:errCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unreadable file", NSLocalizedDescriptionKey, @"The file was not readable as a NetCDF file.", NSLocalizedFailureReasonErrorKey, @"Try exporting from the originating application again selecting NetCDF as the export file format.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
		return NO;
	}
	
	[self setNcid:ncid];
	[self setAbsolutePathToNetCDF:fileName];
	
	//    NS_DURING
	
	if (![self ncid]) {
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
			return NO; // We should handle this case!
		}
		
	} else {
		// It's a GCMS file
	}	
	
	return YES;
}	 

- (NSString *)type
{
    return NSLocalizedString(@"GC/MS", @"");
}

- (PKChromatogram *)ticChromatogram {
    // Check if such a chromatogram is already available
    PKChromatogram *chromatogram;
    for (chromatogram in chromatograms) {
        if ([[chromatogram model] isEqualToString:@"TIC"]) {
            return chromatogram;
        }
    }
     
    float *time;
    float *totalIntensity;
    int dummy, dimid, numberOfPoints, varid_scanaqtime, varid_totintens;
//    BOOL hasVarid_scanaqtime;
    
        // GCMS file
        dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_dimlen(ncid, dimid, (void *) &numberOfPoints);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid(ncid, "scan_acquisition_time", &varid_scanaqtime);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_acquisition_time variable failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_varid(ncid, "total_intensity", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting total_intensity dimension failed.\nNetCDF error: %d",@""), dummy];
        
     // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
    time = (float *) malloc(numberOfPoints*sizeof(float));
    totalIntensity = (float *) malloc(numberOfPoints*sizeof(float));
	
	dummy = nc_get_var_float(ncid, varid_scanaqtime, time);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scanaqtime variables failed.\nNetCDF error: %d",@""), dummy];
	
	dummy = nc_get_var_float(ncid, varid_totintens, totalIntensity);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting totintens variables failed.\nNetCDF error: %d",@""), dummy];
	
    chromatogram = [[PKChromatogram alloc] initWithModel:@"TIC"];
    int i;
    for (i=0; i<numberOfPoints; i++) {
        time[i] = time[i]/60.0f;
    }
    [chromatogram setTime:time withCount:numberOfPoints];
    [chromatogram setTotalIntensity:totalIntensity withCount:numberOfPoints];
    
	[chromatogram autorelease];
	return chromatogram;
}

- (PKChromatogram *)chromatogramForModel:(NSString *)model {
    int     dummy, scan, dimid, varid_intensity_value, varid_mass_value, varid_scan_index, varid_point_count, scanCount; //varid_time_value
    float   mass, intensity;
    float	*times,	*intensities;
    unsigned int numberOfPoints, num_scan;
	unsigned int i,j,k, mzValuesCount;
    
    if ([model isEqualToString:@"TIC"]) {
        return [self ticChromatogram];
    }
    NSMutableArray *mzValues = [NSMutableArray array];
    [model stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
    if ([model isEqualToString:@""]) {
        return nil;
    }
	NSArray *mzValuesPlus = [model componentsSeparatedByString:@"+"];
	NSArray *mzValuesMin = nil;
	for (i = 0; i < [mzValuesPlus count]; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
                    if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                        [mzValues addObject:[NSNumber numberWithInt:j]];                        
                    }
				}
			} else {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j++) {
                    if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                        [mzValues addObject:[NSNumber numberWithInt:j]];
                    }
				}
			}
		} else {
            j = [[mzValuesMin objectAtIndex:0] intValue];
            if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                [mzValues addObject:[NSNumber numberWithInt:j]];
            }
		}
	}
    if ([mzValues count] < 1) {
        return nil;
    } 
	// Short mzValues
    mzValues = [[mzValues sortedArrayUsingFunction:intSort context:NULL] mutableCopy];
    
	NSString *mzValuesString = [NSString stringWithFormat:@"%d",[[mzValues objectAtIndex:0] intValue]];
	mzValuesCount = [mzValues count];
    float mzValuesF[mzValuesCount];
	for (i = 0; i < mzValuesCount; i++) {
        mzValuesF[i] = [[mzValues objectAtIndex:i] floatValue];
    }
    if (mzValuesCount > 1) {
        for (i = 1; i < mzValuesCount-1; i++) {
            if ((mzValuesF[i] == mzValuesF[i-1]+1.0f) && (mzValuesF[i+1] > mzValuesF[i]+1.0f)) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d",[[mzValues objectAtIndex:i] intValue]];            
            } else if (mzValuesF[i] != mzValuesF[i-1]+1.0f) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];            
            }
        }	
        if ((mzValuesF[i] == mzValuesF[i-1] + 1.0f)) {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d",[[mzValues objectAtIndex:i] intValue]];            
        } else {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];            
        }        
    }
    //JKLogDebug(@"%@ %@",mzValuesString,[mzValues description]);
    
    // Check if such a chromatogram is already available
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    PKChromatogram *chromatogram = nil;
    
    while ((chromatogram = [chromEnum nextObject]) != nil) {
        if ([[chromatogram model] isEqualToModelString:mzValuesString]) {
            return chromatogram;
        }
    }
    
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return nil;}
    
    //    dummy = nc_inq_varid(ncid, "time_values", &varid_time_value);
    //    if(dummy != NC_NOERR) { JKLogError(@"Getting time_values variable failed. Report error #%d. Continuing...", dummy);}
    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { JKLogError(@"Getting varid_scan_index variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "point_count", &varid_point_count);
    if(dummy != NC_NOERR) { JKLogError(@"Getting point_count variable failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
    if(dummy != NC_NOERR) { JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &numberOfPoints);
    if(dummy != NC_NOERR) { JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
    if(dummy != NC_NOERR) { JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_scan);
    if(dummy != NC_NOERR) { JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return nil;}
    
	times = (float *) malloc((num_scan)*sizeof(float));
	intensities = (float *) malloc((num_scan)*sizeof(float));
    
    scan = 0;
    scanCount = 0;
    int intScan;
    float *massValues;
    massValues = (float *) malloc(sizeof(float));
    // go through all scans
	for(i = 0; i < num_scan; i++) {
        times[i] = 0.0f;
        intensities[i] = 0.0f;
        
        times[i] = [self timeForScan:i];
        
        // go through the masses for the scan
		dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &i, &scan); // is this the start or the end?
		dummy = nc_get_var1_int(ncid, varid_point_count, (void *) &i, &scanCount);
	    
        massValues = (float *) realloc(massValues, scanCount*sizeof(float));
        
        dummy = nc_get_vara_float(ncid, varid_mass_value, (const size_t *) &scan, (const size_t *) &scanCount, massValues);
        if(dummy != NC_NOERR) { JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return nil;}
        
        
        for(j = 0; j < (unsigned)scanCount; j++) {
            mass = massValues[j];
            intensity = 0.0f;
			//dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &j, &mass);
            // find out wether the mass encountered is on the masses we are interested in
			for(k = 0; k < mzValuesCount; k++) {
				if (fabsf(mass-mzValuesF[k]) < 0.5f) {
                    intScan = j+ scan;
					dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &intScan, &intensity);					
					intensities[i] = intensities[i] + intensity;
				}
			}
		}
	}
    
	chromatogram = nil;
	
    //create a chromatogram object
    chromatogram = [[PKChromatogram alloc] initWithModel:mzValuesString];
    [chromatogram setContainer:self];
    [chromatogram setTime:times withCount:num_scan];
    [chromatogram setTotalIntensity:intensities withCount:num_scan];
    
    free(massValues);
	[chromatogram autorelease];	
	return chromatogram;    
}

- (BOOL)addChromatogramForModel:(NSString *)modelString {
    PKChromatogram *chromatogram = [self chromatogramForModel:modelString];
    if (!chromatogram) {
        return NO;
    }
    if (![[self chromatograms] containsObject:chromatogram]) {
        [self insertValue:chromatogram inPropertyWithKey:@"chromatograms"];
 //       [self insertObject:chromatogram inChromatogramsAtIndex:[[self chromatograms] count]];  
        return YES;
    }
    return NO;
}

- (JKSpectrum *)spectrumForScan:(int)scan {
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, start, end, varid_mass_value, varid_intensity_value, varid_scan_index;
    int numberOfPoints;
    float 	*massValues;
    float 	*intensities;
    
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return 0;}
    
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
    
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
    
    scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
    
    numberOfPoints = end - start;
    
    massValues = (float *) malloc(numberOfPoints*sizeof(float));
    
    dummy = nc_get_vara_float(ncid, varid_mass_value, (const size_t *) &start, (const size_t *) &numberOfPoints, massValues);
    if(dummy != NC_NOERR) { JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return nil;}
    
    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
    
    intensities = (float *) malloc((numberOfPoints)*sizeof(float));
    
    dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &start, (const size_t *) &numberOfPoints, intensities);
    if(dummy != NC_NOERR) { JKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return nil;}
    
    JKSpectrum *spectrum = [[JKSpectrum alloc] initWithModel:[NSString stringWithFormat:@"scan %d",scan-1]];
    
    [spectrum setMasses:massValues withCount:numberOfPoints];
    [spectrum setIntensities:intensities withCount:numberOfPoints];
    
	[spectrum autorelease];
	return spectrum;
}

- (float)timeForScan:(int)scan 
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    NSAssert([[self chromatograms] count] >= 0, @"[[self chromatograms] count] must be equal or larger than zero");
    float *time = [[[self chromatograms] objectAtIndex:0] time];
    return time[scan];    
}

- (int)scanForTime:(float)time 
{
    NSAssert([[self chromatograms] count] >= 0, @"[[self chromatograms] count] must be equal or larger than zero");
    return [[[self chromatograms] objectAtIndex:0] scanForTime:time];
}

- (float)retentionIndexForScan:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    float x;
    
    x = [self timeForScan:scan];
    
    return x * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
}

#pragma mark Tree structure
- (NSArray *)children
{
    return chromatograms;
}

- (int)count
{
    return [chromatograms count];
}

- (BOOL)isLeaf
{
    return [chromatograms count] > 0 ? YES : NO; 
}
#pragma mark -

#pragma mark Property synthesization
@synthesize chromatograms;
@synthesize ncid;
@synthesize absolutePathToNetCDF;
@synthesize label;

@end
