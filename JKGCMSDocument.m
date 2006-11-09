//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKGCMSDocument.h"

#import "BDAlias.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKLibrary.h"
#import "JKLibraryEntry.h"
#import "JKMainWindowController.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "netcdf.h"
#import "JKDataModelProxy.h"
#import "jk_statistics.h"

NSString *const JKGCMSDocument_DocumentDeactivateNotification = @"JKGCMSDocument_DocumentDeactivateNotification";
NSString *const JKGCMSDocument_DocumentActivateNotification   = @"JKGCMSDocument_DocumentActivateNotification";
NSString *const JKGCMSDocument_DocumentLoadedNotification     = @"JKGCMSDocument_DocumentLoadedNotification";
int const JKGCMSDocument_Version = 4;
static void *DocumentObservationContext = (void *)1100;

@implementation JKGCMSDocument

#pragma mark INITIALIZATION

- (id)init  
{
	self = [super init];
    if (self != nil) {
        mainWindowController = [[[JKMainWindowController alloc] init] autorelease];
		peaks = [[NSMutableArray alloc] init];
		baseline = [[NSMutableArray alloc] init];
		metadata = [[NSMutableDictionary alloc] init];
		chromatograms = [[NSMutableArray alloc] init];
		
		remainingString = [NSString stringWithString:@""];
		
		id defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        absolutePathToNetCDF = @"";
		baselineWindowWidth = [[defaultValues valueForKey:@"baselineWindowWidth"] retain];
		baselineDistanceThreshold = [[defaultValues valueForKey:@"baselineDistanceThreshold"] retain];
		baselineSlopeThreshold = [[defaultValues valueForKey:@"baselineSlopeThreshold"] retain];
		baselineDensityThreshold = [[defaultValues valueForKey:@"baselineDensityThreshold"] retain];
		peakIdentificationThreshold = [[defaultValues valueForKey:@"peakIdentificationThreshold"] retain];
		retentionIndexSlope = [[defaultValues valueForKey:@"retentionIndexSlope"] retain];
		retentionIndexRemainder = [[defaultValues valueForKey:@"retentionIndexRemainder"] retain];
		libraryAlias = [[BDAlias aliasWithPath:[defaultValues valueForKey:@"libraryAlias"]] retain];
		scoreBasis = [[defaultValues valueForKey:@"scoreBasis"] intValue];
		penalizeForRetentionIndex = [[defaultValues valueForKey:@"penalizeForRetentionIndex"] boolValue];
		markAsIdentifiedThreshold = [[defaultValues valueForKey:@"markAsIdentifiedThreshold"] retain];
		minimumScoreSearchResults = [[defaultValues valueForKey:@"minimumScoreSearchResults"] retain];
        
        [self addObserver:mainWindowController forKeyPath:@"metadata.sampleCode" options:nil context:DocumentObservationContext];
        [self addObserver:mainWindowController forKeyPath:@"metadata.sampleDescription" options:nil context:DocumentObservationContext];

//        [self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
//        NSLog(@"%d", [[NSPrintInfo sharedPrintInfo] orientation]);
//        NSLog(@"%d", [[self printInfo] orientation]);
	}
    return self;
}

- (void)removeWindowController:(NSWindowController *)windowController {
//    if (windowController == mainWindowController) {
//        [self removeObserver:mainWindowController forKeyPath:@"metadata.sampleCode"];
//        [self removeObserver:mainWindowController forKeyPath:@"metadata.sampleDescription"];        
//    }
        
    [super removeWindowController:windowController];
}

- (void)dealloc  
{
	[peaks release];	
    [baseline release];
	[metadata release];
	[chromatograms release];
	[baselineWindowWidth release];
	[baselineDistanceThreshold release];
	[baselineSlopeThreshold release];
	[baselineDensityThreshold release];
	[peakIdentificationThreshold release];
	[retentionIndexSlope release];
	[retentionIndexRemainder release];
	[libraryAlias release];
	[markAsIdentifiedThreshold release];
	[minimumScoreSearchResults release];
	
	int dummy;
	dummy = nc_close(ncid);
//	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"File closing error",@"File closing error") format:NSLocalizedString(@"Closing NetCDF file caused problem.\nNetCDF error: %d",@""), dummy];
//	[mainWindowController release];
    [super dealloc];
}

// Great debug snippet!
//- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
//    NSLog(@"addObserver:    %@ %@", anObserver, keyPath);
//    [super addObserver:anObserver forKeyPath:keyPath options:options context:context];
//}
//- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
//    NSLog(@"removeObserver: %@ %@", anObserver, keyPath);
//    [super removeObserver:anObserver forKeyPath:keyPath];
//}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers  
{
	[[NSNotificationCenter defaultCenter] postNotificationName:JKGCMSDocument_DocumentLoadedNotification object:self];
	NSAssert(mainWindowController != nil, @"mainWindowController is nil");
	[self addWindowController:mainWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType 
{
	if ([aType isEqualToString:@"Peacock File"]) {

		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver encodeInt:JKGCMSDocument_Version forKey:@"version"];
		[archiver encodeObject:[self baseline] forKey:@"baseline"];
		[archiver encodeObject:[self peaks] forKey:@"peaks"];
		[archiver encodeObject:[self metadata] forKey:@"metadata"];		
		[archiver encodeObject:baselineWindowWidth forKey:@"baselineWindowWidth"];
		[archiver encodeObject:baselineDistanceThreshold forKey:@"baselineDistanceThreshold"];
		[archiver encodeObject:baselineSlopeThreshold forKey:@"baselineSlopeThreshold"];
		[archiver encodeObject:baselineDensityThreshold forKey:@"baselineDensityThreshold"];
		[archiver encodeObject:peakIdentificationThreshold forKey:@"peakIdentificationThreshold"];
		[archiver encodeObject:[self retentionIndexSlope] forKey:@"retentionIndexSlope"];
		[archiver encodeObject:[self retentionIndexRemainder] forKey:@"retentionIndexRemainder"];
		[archiver encodeObject:libraryAlias forKey:@"libraryAlias"];
		[archiver encodeInt:scoreBasis forKey:@"scoreBasis"];
		[archiver encodeBool:penalizeForRetentionIndex forKey:@"penalizeForRetentionIndex"];
		[archiver encodeObject:[self markAsIdentifiedThreshold] forKey:@"markAsIdentifiedThreshold"];
		[archiver encodeObject:[self minimumScoreSearchResults] forKey:@"minimumScoreSearchResults"];
		
		[archiver finishEncoding];
		[archiver release];
		
		if (peacockFileWrapper) {
			// This is when we save back to a peacock file

			[peacockFileWrapper removeFileWrapper:[[peacockFileWrapper fileWrappers] valueForKey:@"peacock-data"]];
			NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:data];
			[fileWrapperForData setPreferredFilename:@"peacock-data"];
			[peacockFileWrapper addFileWrapper:fileWrapperForData];

			// NetCDF file should not have changed!
			
		} else {
			// First time save to a peacock file
			NSMutableDictionary *fileWrappers = [[NSMutableDictionary alloc] init];
				
			NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:data];
			NSAssert(data != nil, @"data = nil!");
			NSAssert(fileWrapperForData != nil, @"fileWrapperForData = nil!");
			[fileWrapperForData setPreferredFilename:@"peacock-data"];
			[fileWrappers setObject:fileWrapperForData forKey:@"peacock-data"];	
			NSFileWrapper *fileWrapperForNetCDF = [[NSFileWrapper alloc] initWithPath:absolutePathToNetCDF];
			NSAssert(fileWrapperForNetCDF != nil, @"fileWrapperForNetCDF = nil!");
			
			[fileWrapperForNetCDF setPreferredFilename:@"netcdf"];
			[fileWrappers setObject:fileWrapperForNetCDF forKey:@"netcdf"];		
			
			peacockFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers];
			
		}

		return peacockFileWrapper;	
		
	} else if ([aType isEqualToString:@"Tab Delimited Text File"]) {
		NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:[[self exportTabDelimitedText] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
		[fileWrapperForData autorelease];
		return fileWrapperForData;
	} else {
		return nil;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError  
{
	if ([typeName isEqualToString:@"NetCDF/ANDI File"]) {
        absolutePathToNetCDF = [absoluteURL path];
        return [self readNetCDFFile:[absoluteURL path] error:outError];
	} else if ([typeName isEqualToString:@"Peacock File"]) {
		BOOL result;		
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
		NSData *data;
		NSKeyedUnarchiver *unarchiver;
		data = [[[wrapper fileWrappers] valueForKey:@"peacock-data"] regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		int version = [unarchiver decodeIntForKey:@"version"];
		if (version < 3) {
			NSRunAlertPanel(@"File format no longer supported",@"The file you are trying to open was saved with an earlier beta-version of Peacock. It can be opened, but its content is partially incomplete. To fix this, press after loading the key combination \"shift-control-option-command O.\"",@"Continue",nil,nil);
			[unarchiver setClass:[JKDataModelProxy class] forClassName:@"JKDataModel"];
			JKDataModelProxy *dataModel = [unarchiver decodeObjectForKey:@"dataModel"];
			peaks = [[dataModel peaks] retain];
            NSEnumerator *e = [peaks objectEnumerator];
            JKPeakRecord *peak;
            e = [peaks objectEnumerator];
            while ((peak = [e nextObject])) {
                [peak setDocument:self];
                //[self startObservingPeak:peak];
            }
            
			baseline = [[dataModel baseline] retain];
			metadata = [[dataModel metadata] retain];
			// These are not stored but refetched from cdf file when needed
			chromatograms = [[NSMutableArray alloc] init];
			
			[unarchiver finishDecoding];
			[unarchiver release];
			
			result = [self readNetCDFFile:[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"] error:outError];
			if (result) {
				peacockFileWrapper = wrapper;
			}
            
            
			return result;	
			
		}
		baseline = [[unarchiver decodeObjectForKey:@"baseline"] retain];
		peaks = [[unarchiver decodeObjectForKey:@"peaks"] retain];
		NSEnumerator *e = [peaks objectEnumerator];
		JKPeakRecord *peak;
		e = [peaks objectEnumerator];
		while ((peak = [e nextObject])) {
            [peak setDocument:self];
//			[self startObservingPeak:peak];
		}
		metadata = [[unarchiver decodeObjectForKey:@"metadata"] retain];
		baselineWindowWidth = [[unarchiver decodeObjectForKey:@"baselineWindowWidth"] retain];
		baselineDistanceThreshold = [[unarchiver decodeObjectForKey:@"baselineDistanceThreshold"] retain];
		baselineSlopeThreshold = [[unarchiver decodeObjectForKey:@"baselineSlopeThreshold"] retain];
		baselineDensityThreshold = [[unarchiver decodeObjectForKey:@"baselineDensityThreshold"] retain];
		peakIdentificationThreshold = [[unarchiver decodeObjectForKey:@"peakIdentificationThreshold"] retain];
		retentionIndexSlope = [[unarchiver decodeObjectForKey:@"retentionIndexSlope"] retain];
		retentionIndexRemainder = [[unarchiver decodeObjectForKey:@"retentionIndexRemainder"] retain];		
		libraryAlias = [[unarchiver decodeObjectForKey:@"libraryAlias"] retain];
		scoreBasis = [unarchiver decodeIntForKey:@"scoreBasis"];
		penalizeForRetentionIndex = [unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"];
		markAsIdentifiedThreshold = [[unarchiver decodeObjectForKey:@"markAsIdentifiedThreshold"] retain];		
		minimumScoreSearchResults = [[unarchiver decodeObjectForKey:@"minimumScoreSearchResults"] retain];		
		
		// These are not stored but refetched from cdf file when needed
		chromatograms = [[NSMutableArray alloc] init];
		
		[unarchiver finishDecoding];
		[unarchiver release];
		
		result = [self readNetCDFFile:[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"] error:outError];
		if (result) {
			peacockFileWrapper = wrapper;
		}
                
		return result;	
//	} else if ([typeName isEqualToString:@"GAML File"]) {
//        xmlDoc = [[NSXMLDocument alloc] initWithContentsOfURL:absoluteURL options:nil error:outError];
//        
//        NSXMLNode *aNode = [xmlDoc rootElement];
//        NSMutableString *translator_notes=nil;
//        while (aNode = [aNode nextNode]) {
//            if ( [[aNode localName] isEqualToString:@"experiment"] ) {
//                JKExperiment *experiment = [[JKExperiment alloc] init];
//                [experiment setName:[aNode attributeForName:@"name"]];
//                
//                while (aNode = [aNode nextNode]) {
//                    if ( [[aNode localName] isEqualToString:@"collectdate"] ) {
//
//                    } else if ( [[aNode localName] isEqualToString:@"parameter"] ) {
//                        
//                    }
//                    
//                if (!translator_notes) {
//                    translator_notes = [[NSMutableString alloc] init];
//                }
//                [translator_notes appendString:[aNode stringValue]];
//                [translator_notes appendString:@" ========> "];
//                aNode = [aNode nextNode]; // element to be translated
//                [translator_notes appendString:[aNode stringValue]];
//                [translator_notes appendString:@"\n"];
//            }
//        }
////        if (translator_notes) {
////            [translator_notes writeToFile:[NSString stringWithFormat:@"%@/translator_notes.txt", NSHomeDirectory()] atomically:YES];
////            [translator_notes release];
////        }
//        
    } else {
        if (outError != NULL)
			*outError = [[[NSError alloc] initWithDomain:NSCocoaErrorDomain
												   code:NSFileReadUnknownError userInfo:nil] autorelease];
        
		return NO;
	}	
}

- (NSString *)autosavingFileType {
    return @"Peacock File";
}

#pragma mark IBACTIONS

- (IBAction)openNext:(id)sender  
{
	NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:[[self fileName] stringByDeletingLastPathComponent]];
	NSError *error = [[NSError alloc] init];
	BOOL openNext = NO;
	unsigned int i;
	for (i=0; i < [content count]; i++) {
		if (openNext) {
			[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[content objectAtIndex:i]]] display:YES error:&error];
			break;
		}
		if ([[content objectAtIndex:i] isEqualToString:[[self fileName] lastPathComponent]]) {
			openNext = YES;
		}
	}
	[error release];
}

#pragma mark IMPORT/EXPORT ACTIONS

- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError  
{
	int errCode;

	// Get the file's name and pull the id. Test to make sure that this all worked.
	errCode = nc_open([fileName cString], NC_NOWRITE, &ncid);
	if (errCode != NC_NOERR) {
		if (anError != NULL)
			*anError = [[[NSError alloc] initWithDomain:@"JKNetCDFDomain" 
												   code:errCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unreadable file", NSLocalizedDescriptionKey, @"The file was not readable as a NetCDF file.", NSLocalizedFailureReasonErrorKey, @"Try exporting from the originating application again selecting NetCDF as the export file format.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
		return NO;
	}
	
	[self setNcid:ncid];
	
	absolutePathToNetCDF = fileName;

    int		num_pts;
    float	*x;
    float 	*y;
    int     dummy, dimid, varid_scanaqtime, varid_totintens;
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
        dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid(ncid, "scan_acquisition_time", &varid_scanaqtime);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_acquisition_time variable failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_varid(ncid, "total_intensity", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting total_intensity dimension failed.\nNetCDF error: %d",@""), dummy];
        
    } else {
        // GC file
        dummy = nc_inq_dimid(ncid, "point_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid(ncid, "raw_data_retention", &varid_scanaqtime);
		//		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting raw_data_retention variable failed.\nNetCDF error: %d",@""), dummy];
        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
        
        dummy = nc_inq_varid(ncid, "ordinate_values", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting ordinate_values variable failed.\nNetCDF error: %d",@""), dummy];
    }
	
    // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
    x = (float *) malloc(num_pts*sizeof(float));
    y = (float *) malloc(num_pts*sizeof(float));
	
	dummy = nc_get_var_float(ncid, varid_scanaqtime, x);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scanaqtime variables failed.\nNetCDF error: %d",@""), dummy];
	
	dummy = nc_get_var_float(ncid, varid_totintens, y);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting totintens variables failed.\nNetCDF error: %d",@""), dummy];
	
	[self setTime:x withCount:num_pts];
	[self setTotalIntensity:y withCount:num_pts];
	
	[chromatograms addObject:[self obtainTICChromatogram]];
	
//	if ([baseline count] <= 0)
//		[self obtainBaseline];
	
	return YES;
	//	NS_HANDLER
	//		NSRunAlertPanel([NSString stringWithFormat:@"Error: %@",[localException name]], @"%@", @"OK", nil, nil, localException);
	//	NS_ENDHANDLER
}	 


- (NSString *)exportTabDelimitedText  
{
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array = [[[self mainWindowController] peakController] arrangedObjects];
	int i;
	int count = [array count];
	
	[outStr appendString:NSLocalizedString(@"File\tID\tLabel\tScore\tIdentified\tConfirmed\tStart (scan)\tTop (scan)\tEnd (scan)\tHeight (normalized)\tSurface (normalized)\tHeight (abs.)\tSurface (abs.)\tBaseline Left\tBaseline Right\tName (Lib.)\tFormula (Lib.)\tCAS No. (Lib.)\tRetention Index (Lib.)\tComment (Lib.)\n",@"Top row of tab delimited text export.")];
	for (i=0; i < count; i++) {
		[outStr appendFormat:@"%@\t", [self displayName]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"peakID"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"label"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.score"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"identified"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"confirmed"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"start"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"top"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"end"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"startTime"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"topTime"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"endTime"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"normalizedHeight"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"normalizedSurface"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"height"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"width"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"surface"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"baselineLeft"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"baselineRight"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.libraryHit.name"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.libraryHit.formula"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.libraryHit.CASNumber"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.libraryHit.retentionIndex"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"identifiedSearchResult.libraryHit.comment"]];
		[outStr appendString:@"\n"];
	}

	[outStr autorelease];
	return outStr;
}

- (NSArray *)readJCAMPString:(NSString *)inString {
	int count,i;
	NSMutableArray *libraryEntries = [[NSMutableArray alloc] init];
	NSArray *array = [inString componentsSeparatedByString:@"##END="];
	NSCharacterSet *whiteCharacters = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		
//	int numPeaks; 
//    NSString *xyData; 
//	
//	NSString *scannedString;
//	float scannedFloat;
		
	count = [array count];
	
	// We ignore the last entry in the array, because it likely isn't complete 
	// NOTE: we now require at least a return after the last entry in the file or we won't read that entry
	for (i=0; i < count-1; i++) {
		// If we are dealing with an empty string, bail out
		if ([[[array objectAtIndex:i] stringByTrimmingCharactersInSet:whiteCharacters] isEqualToString:@""]) {
			continue;
		}
		
		JKLibraryEntry *libEntry = [[JKLibraryEntry alloc] initWithJCAMPString:[array objectAtIndex:i]];
				
		// Add data to Library
		[libraryEntries addObject:libEntry];
		[libEntry release];
	}
	
	// library Array should be returned
	// and the remaining string
	remainingString = [array objectAtIndex:count-1];
	
	JKLogDebug(@"Found %d entries", [libraryEntries count]);
	[libraryEntries autorelease];
    return libraryEntries;	
}

#pragma mark SORTING DOCUMENTS

// Used by the summary feature
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument  
{
	int metadataChoosen = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"columnSorting"] intValue];

	switch (metadataChoosen) {
	case 1: // samplecode
		return [[metadata valueForKey:@"sampleCode"] caseInsensitiveCompare:[[otherDocument metadata] valueForKey:@"sampleCode"]];
		break;
	case 2: // sampleDescription
		return [[metadata valueForKey:@"sampleDescription"] caseInsensitiveCompare:[[otherDocument metadata] valueForKey:@"sampleDescription"]];
		break;
	default:
		return [[metadata valueForKey:@"sampleCode"] caseInsensitiveCompare:[[otherDocument metadata] valueForKey:@"sampleCode"]];
		break;
	}
		
}

#pragma mark PRINTING
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo {
    return NO;
}
- (void)printShowingPrintPanel:(BOOL)showPanels  
{
    // Obtain a custom view that will be printed
    NSView *printView = [[self mainWindowController] chromatogramView];
//	[[self printInfo] setHorizontalPagination:NSFitPagination];
//	[[self printInfo] setVerticalPagination:NSFitPagination];
//	[[self printInfo] setOrientation:NSLandscapeOrientation];
    NSPrintInfo *pInfo = [self printInfo];
    _originalFrame = [[[self mainWindowController] chromatogramView] frame];
//    NSData *pdfData;
//    [[[self mainWindowController] chromatogramView] setFrame:[pInfo imageablePageBounds]];
//    [[[self mainWindowController] chromatogramView] showAll:self];
//    pdfData = [chromatogramView dataWithPDFInsideRect:NSMakeRect(-[pInfo imageablePageBounds].origin.x,-[pInfo imageablePageBounds].origin.y,[pInfo paperSize].width,[pInfo paperSize].height)];
    
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
							 printInfo:pInfo];
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
	//	[op setAccessoryView:[mainWindowController printAccessoryView]];
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
						delegate:nil
				  didRunSelector:@selector(documentDidRunModalPrintOperation:success:contextInfo:)
					 contextInfo:NULL];
}
- (void)documentDidRunModalPrintOperation:(NSDocument *)document  success:(BOOL)success  contextInfo:(void *)contextInfo {
//    [[[self mainWindowController] chromatogramView] setFrame:_originalFrame];
//    [[[self mainWindowController] chromatogramView] showAll:self];
    [[[self mainWindowController] chromatogramView] setNeedsDisplay:YES];    
}
#pragma mark NOTIFICATIONS

- (void) postNotification: (NSString *) notificationName
{
    NSNotificationCenter *center;
    center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName: notificationName
						  object: self];
	
}


- (void) windowDidBecomeMain: (NSNotification *) notification
{
    [self postNotification: 
		JKGCMSDocument_DocumentActivateNotification];
	
}


- (void) windowDidResignMain: (NSNotification *) notification
{
    [self postNotification: 
		JKGCMSDocument_DocumentDeactivateNotification];
	
}


- (void) windowWillClose: (NSNotification *) notification
{
    [self postNotification: 
		JKGCMSDocument_DocumentDeactivateNotification];
}

#pragma mark ACTIONS

- (ChromatogramGraphDataSerie *)obtainTICChromatogram  
{
	int i;
	
	ChromatogramGraphDataSerie *chromatogram = [[ChromatogramGraphDataSerie alloc] init];
    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
	for (i = 0; i < numberOfPoints; i++) {
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:time[i]/60.0f], @"Time",
			[NSNumber numberWithInt:i], @"Scan",
			[NSNumber numberWithFloat:totalIntensity[i]], @"Total Intensity", nil];
		[mutArray addObject:dict];      
		[dict release];
	}
	[chromatogram setDataArray:mutArray];
	[mutArray release];
	
	[chromatogram setKeyForXValue:@"Time"];
	[chromatogram setKeyForYValue:@"Total Intensity"];
	[chromatogram setSeriesTitle:NSLocalizedString(@"TIC Chromatogram",@"")];
	
	[chromatogram autorelease];
	
	return chromatogram;
}

- (void)obtainBaseline  
{
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
	// to minimize object calling
	float baselineWindowWidthF = [[self baselineWindowWidth] floatValue];
	float baselineDistanceThresholdF = [[self baselineDistanceThreshold] floatValue];
	float baselineSlopeThresholdF = [[self baselineSlopeThreshold] floatValue];
	float baselineDensityThresholdF = [[self baselineDensityThreshold] floatValue];

    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setBaseline:)
                                        object:[baseline mutableCopy]];
    [[self undoManager] setActionName:NSLocalizedString(@"Identify Baseline",@"")];
    
	[self willChangeValueForKey:@"baseline"];
	
    [baseline removeAllObjects];
	
	for (i = 0; i < count; i++) {
		minimumSoFar = intensity[i];
		for (j = i - baselineWindowWidthF/2; j < i + baselineWindowWidthF/2; j++) {
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
		for (j = i - baselineWindowWidthF/2; j < i + baselineWindowWidthF/2; j++) {
			distanceSquared = pow(fabs(intensity[j]-intensity[i]),2) + pow(fabs(time[j]-time[i]),2);
			if (distanceSquared != 0.0) densitySoFar = densitySoFar + 1/sqrt(distanceSquared);	
		}
		density[i] = densitySoFar;		
	}
	
	normalize(distance, count);
	normalize(slope, count);
	normalize(density, count);
	
	[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Scan", [NSNumber numberWithFloat:intensity[0]], @"Total Intensity", [NSNumber numberWithFloat:time[0]/60.0], @"Time",nil]];
	for (i = 0; i < count; i++) {
		if (distance[i] < baselineDistanceThresholdF && (slope[i] > -baselineSlopeThresholdF  && slope[i] < baselineSlopeThresholdF) && density[i] > baselineDensityThresholdF) { 
			[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"Scan", [NSNumber numberWithFloat:intensity[i]], @"Total Intensity", [NSNumber numberWithFloat:time[i]/60.0], @"Time",nil]];
		}
	}
	[baseline addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:count-1], @"Scan", [NSNumber numberWithFloat:intensity[count-1]], @"Total Intensity", [NSNumber numberWithFloat:time[count-1]/60.0], @"Time",nil]];
	[self didChangeValueForKey:@"baseline"];
}	

- (void)identifyPeaks  
{
	int i,j, peakCount, answer;
	int start, end, top;
	float a, b, height, surface, maximumSurface, maximumHeight;
	float startTime, topTime, endTime, widthTime;
	float time1, time2;
	float height1, height2;
	float retentionIndex;//, retentionIndexSlope, retentionIndexRemainder;
		JKSpectrum *spectrum;
		int npts;
		float *xpts, *ypts;
		
		NSMutableArray *array = [[NSMutableArray alloc] init];
		
		if ([peaks count] > 0) {
			answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Delete current peaks?",@""),NSLocalizedString(@"Peaks that are already identified could cause doublures. It's recommended to delete the current peaks.",@""),NSLocalizedString(@"Delete",@""),NSLocalizedString(@"Cancel",@""),NSLocalizedString(@"Keep",@""));
			if (answer == NSOKButton) {
				// Delete contents!
				[self willChangeValueForKey:@"peaks"];
				[peaks removeAllObjects];
				[self didChangeValueForKey:@"peaks"];			
			} else if (answer == NSCancelButton) {
				return;
			} else {
				// Continue by adding peaks
			}
		}
		
		// Baseline check
		if ([baseline count] <= 0) {
//			JKLogDebug([baseline description]);
//			JKLogWarning(@"No baseline set. Can't recognize peaks without one.");
            answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
			return;
		}
		
		// Some initial settings
		i = 0;
		peakCount = 1;	
		maximumSurface = 0.0;
		maximumHeight = 0.0;
		float peakIdentificationThresholdF = [[self peakIdentificationThreshold] floatValue];
		
		for (i = 0; i < numberOfPoints; i++) {
			if (totalIntensity[i]/[self baselineValueAtScan:i] > (1.0 + peakIdentificationThresholdF)){
				
				// determine: high, start, end
				// start
				for (j=i; totalIntensity[j] > totalIntensity[j-1]; j--) {				
				}
				start = j;
				if (start < 0) start = 0; // Don't go outside bounds!
				
				// top
				for (j=start; totalIntensity[j] < totalIntensity[j+1]; j++) {
				}
				top=j;
				if (top >= numberOfPoints) top = numberOfPoints-1; // Don't go outside bounds!
				
				// end
				for (j=top; totalIntensity[j] > totalIntensity[j+1]; j++) {				
				}
				end=j;
				if (end >= numberOfPoints-1) end = numberOfPoints-1; // Don't go outside bounds!
				
				// start time
				startTime = [self timeForScan:start];
				
				// top time
				topTime = [self timeForScan:top];
				
				// end time
				endTime = [self timeForScan:end];
				
				// width
				widthTime = endTime - startTime;
				
				// baseline left
				float baselineAtStart = [self baselineValueAtScan:start];
				if (baselineAtStart > totalIntensity[start]) {
					baselineAtStart = totalIntensity[start];
				}
				// baseline right
				float baselineAtEnd = [self baselineValueAtScan:end];
				if (baselineAtEnd > totalIntensity[end]) {
					baselineAtEnd = totalIntensity[end];
				}
				
				// Calculations needed for height and width
				a= baselineAtEnd-baselineAtStart;
				b= endTime-startTime;
				
				// height
				//height = intensities[top]-(intensities[start] + (a/b)*(topTime-startTime) );
				height = totalIntensity[top] - [self baselineValueAtScan:top];
				// Keep track of what the heighest peak is
				if (height > maximumHeight) maximumHeight = height;
				
				// surface  WARNING! This is an absolute, not a relative peak surface!
				surface = 0.0;
				for (j=start; j < end; j++) {
					time1 = [self timeForScan:j];
					time2 = [self timeForScan:j+1];
					
					height1 = totalIntensity[j]-(baselineAtStart + (a/b)*(time1-startTime) );
					height2 = totalIntensity[j+1]-(baselineAtStart + (a/b)*(time2-startTime) );
					
					if (height1 > height2) {
						surface = surface + (height2 * (time2-time1)) + ((height1-height2) * (time2-time1) * 0.5);
					} else {
						surface = surface + (height1 * (time2-time1)) + ((height2-height1) * (time2-time1) * 0.5);					
					}
				}
				// Keep track of what the largest peak is
				if (surface > maximumSurface) maximumSurface = surface;
				
				if (top != start && top != end && surface > 0.0) { // Sanity check
																   // Add peak
					JKPeakRecord *record = [[JKPeakRecord alloc] init];
					[record setDocument:self];
					[record setValue:[NSNumber numberWithInt:peakCount] forKey:@"peakID"];
					[record setValue:[NSNumber numberWithInt:start] forKey:@"start"];
					[record setValue:[NSNumber numberWithInt:top] forKey:@"top"];
					[record setValue:[NSNumber numberWithInt:end] forKey:@"end"];
					[record setValue:[NSNumber numberWithFloat:baselineAtStart] forKey:@"baselineLeft"];
					[record setValue:[NSNumber numberWithFloat:baselineAtEnd] forKey:@"baselineRight"];
					
					[record setValue:[NSNumber numberWithFloat:height] forKey:@"height"];
					[record setValue:[NSNumber numberWithFloat:surface] forKey:@"surface"];
	
					retentionIndex = topTime * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
					[record setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"retentionIndex"];
					
					spectrum = [[JKSpectrum alloc] init];
					npts = [self endValuesSpectrum:top] - [self startValuesSpectrum:top];
					xpts = [self massValuesForSpectrumAtScan:top];
					ypts = [self intensityValuesForSpectrumAtScan:top];
					[spectrum setMasses:xpts withCount:npts];
					[spectrum setIntensities:ypts withCount:npts];
					[spectrum setDocument:self];
					free(xpts);
					free(ypts);
					[spectrum setValue:[NSNumber numberWithFloat:[self retentionIndexForScan:top]] forKey:@"retentionIndex"];
					
					[record setSpectrum:spectrum];
					[spectrum release];
					
					
					[array addObject:record];
					peakCount++;
					
					[record release]; 
				}
				
				// Continue looking for peaks from end of this peak
				i = end;			
			}
		}
		
		// Walk through the found peaks to calculate a normalized surface area and normalized height
		peakCount = [array count];
		for (i = 0; i < peakCount; i++) {
			[[array objectAtIndex:i] setValue:[NSNumber numberWithFloat:[[[array objectAtIndex:i] valueForKey:@"height"] floatValue]*100/maximumHeight] forKey:@"normalizedHeight"];
			[[array objectAtIndex:i] setValue:[NSNumber numberWithFloat:[[[array objectAtIndex:i] valueForKey:@"surface"] floatValue]*100/maximumSurface] forKey:@"normalizedSurface"];
		}
		// warning This undo doesn't work correctly(?)
		
		[[self undoManager] registerUndoWithTarget:self
										  selector:@selector(setPeaks:)
											object:peaks];
		[[self undoManager] setActionName:NSLocalizedString(@"Identify Peaks",@"")];
		
		// Add peak to array
		[array addObjectsFromArray:peaks];
		[self setPeaks:array];
		
		[array release];
		return;	
}


-(void)identifyPeaksUsingIntensityWeightedVariance {
    // Identify Peaks using method described in Jarman2003
    
    float desiredSignificance = 0.95; // set by user?
    
    int windowWidth; // increasing from 11 to 200 increasing by 1.5 times per iteration (that is 7 steps)
    int stepSize; // = windowWidth/3;
    int step = 0;
    float iwv[7][numberOfPoints];
    
    int i,j,n,scan,count,countOfValues;
    float t,a,q,d,mean,variance,sum,sumDenominator,sumDevisor;
    float *massValues, *intensityValues;
    
    // Vary window width [3.4.0]
    for (windowWidth = 11; windowWidth < 200; windowWidth = windowWidth *1.5) {
        stepSize = windowWidth/3;
        step++;
        //intensityValues = ??;
        
        // Calculate mean
        sum = 0.0;
        for (j = i; j < windowWidth; j++) {
            sum = sum + intensityValues[j];
        }
        mean = sum/windowWidth;
        
        // Calculate variance
        sum = 0.0;
        for (j = i; j < windowWidth; j++) {
            sum = sum + pow((intensityValues[j]-mean),2);
        }
        variance = sqrt(sum/windowWidth);
        
        // Calculate threshold [3.4.1]
        // Solving -q/d*n*(1-t)/sqrt(n*((3*(3*n^2-7))/(5*(n^2-1))-2*t+t^2))=a for t results on
        // http://www.hostsrv.com/webmab/app1/MSP/quickmath/02/pageGenerate?site=mathcom&s1=equations&s2=solve&s3=basic in
        // t = (-5*pow(q,2)*pow(n,3)+5*pow(a,2)*pow(d,2)*pow(n,2)+5*pow(q,2)*n-5*pow(a,2)*pow(d,2)-2*sqrt(5) * sqrt(pow(a,2)*pow(d,2)*pow(q,2)*pow(n,5)-pow(a,4)*pow(d,4)*pow(n,4)-5*pow(a,2)*pow(d,2)*pow(q,2)*pow(n,3) + 5*pow(a,4)*pow(d,4)*pow(n,2)+4*pow(a,2)*pow(d,2)*pow(q,2)*n-4*pow(a,4)*pow(d,4))) / (5*(-pow(q,2)*pow(n,3)+pow(a,2)*pow(d,2)*pow(n,2)+pow(q,2)*n-pow(a,2)*pow(d,2)));
        // and in:
        n = windowWidth;
        a = desiredSignificance;
        q = mean;
        d = sqrt(variance);
        t = (-5*pow(q,2)*pow(n,3)+5*pow(a,2)*pow(d,2)*pow(n,2)+5*pow(q,2)*n-5*pow(a,2)*pow(d,2)+2*sqrt(5) * sqrt(pow(a,2)*pow(d,2)*pow(q,2)*pow(n,5)-pow(a,4)*pow(d,4)*pow(n,4)-5*pow(a,2)*pow(d,2)*pow(q,2)*pow(n,3) + 5*pow(a,4)*pow(d,4)*pow(n,2)+4*pow(a,2)*pow(d,2)*pow(q,2)*n-4*pow(a,4)*pow(d,4))) / (5*(-pow(q,2)*pow(n,3)+pow(a,2)*pow(d,2)*pow(n,2)+pow(q,2)*n-pow(a,2)*pow(d,2)));
        
        
        // Step through
        for (scan = 0; scan < numberOfPoints; scan = scan+stepSize) {
            // Calculate iwv [3.4.2]
            countOfValues = [self countOfValuesForSpectrumAtScan:scan];
            massValues = [self massValuesForSpectrumAtScan:scan];
            intensityValues = [self intensityValuesForSpectrumAtScan:scan];
            // Calculate mean massValues (m/z-values actually)
            sum = 0.0;
            for (j = 0; j < countOfValues; j++) {
                sum = sum + massValues[j];
            }
            mean = sum/countOfValues;
            sumDenominator= 0.0; sumDevisor = 0.0;
            for (j = 0; j < countOfValues; j++) {
                sumDenominator = sumDenominator + (intensityValues[j]*pow((massValues[j]-mean),2));
                sumDevisor = sumDevisor + intensityValues[j];
            }
            iwv[step][i] = sumDenominator/sumDevisor;
        }
        
    }
    
    // Find occurences below threshold [3.4.3]
    for (i = 0; i < numberOfPoints; i++) {
        count = 0;
        for (j = 0; j < 7; j++) {
            if (iwv[j][i] < t) {
                count++;
            }
        }
        if (count >= 2) {
            // A peak has been detected at scan i
        }
    }
    
    // Compile list, remove duplicates [3.4.4]
}

- (void)addChromatogramForMass:(NSString *)inString  
{
	ChromatogramGraphDataSerie *chromatogram = [self chromatogramForMass:inString];
	
	// Get colorlist
	NSColorList *peakColors;
	NSArray *peakColorsArray;
	
	peakColors = [NSColorList colorListNamed:@"Peacock Series"];
	if (peakColors == nil) {
		peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
	}
	peakColorsArray = [peakColors allKeys];
	int peakColorsArrayCount = [peakColorsArray count];
	
	[chromatogram setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatograms count]%peakColorsArrayCount]]];
    [chromatogram setKeyForXValue:[[[self mainWindowController] chromatogramView] keyForXValue]];
    [chromatogram setKeyForYValue:[[[self mainWindowController] chromatogramView] keyForYValue]];

	[self willChangeValueForKey:@"chromatograms"];
	[chromatograms addObject:chromatogram];
	[self didChangeValueForKey:@"chromatograms"];
}

- (void)resetRetentionIndexes  
{
	int i; 
	float calculatedRetentionIndex;
	int peakCount = [peaks count];
	for (i=0; i < peakCount; i++){
		calculatedRetentionIndex = [[[peaks objectAtIndex:i] valueForKey:@"topTime"] floatValue] * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
		[[peaks objectAtIndex:i] setValue:[NSNumber numberWithFloat:calculatedRetentionIndex] forKey:@"retentionIndex"];				
	}	
}

- (BOOL)searchLibraryForAllPeaks:(id)sender
{
	NSArray *libraryEntries;
	int j,k;
	int entriesCount, answer;
	int maximumIndex;
	float score, maximumScore;	
	float delta;
	[self setAbortAction:NO];

//	[[sender progressIndicator] setIndeterminate:YES];
//	[[sender progressIndicator] startAnimation:self];
//
    [self willChangeValueForKey:@"peaks"];
	// Determine spectra for peaks
	int peaksCount = [[self peaks] count];
	if (peaksCount == 0) {
		answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Peaks Identified",@""),NSLocalizedString(@"No peaks have yet been identified in the chromatogram. Use the 'Identify Peaks' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
		return NO;
	}
	
	// Read library 
	NSError *error = [[NSError alloc] init];
	if (![self libraryAlias]) {
		answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Library Selected",@""),NSLocalizedString(@"Select a Library to use for the identification of the peaks.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
		return NO;
	}
	JKLibrary *aLibrary = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[self libraryAlias] fullPath]] display:NO error:&error];
	if (!aLibrary) {
		answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Library Selected",@""),NSLocalizedString(@"Select a Library to use for the identification of the peaks.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
		return NO;
	}
	[error release];
	
//	[progressIndicator setIndeterminate:NO];
//	[progressIndicator setMaxValue:libraryEntries/1000.0];

	libraryEntries = [aLibrary libraryEntries];
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	// Loop through inPeaks(=combined spectra) and determine score
	entriesCount = [libraryEntries count];
//	JKLogDebug(@"entriesCount %d peaksCount %d",entriesCount, peaksCount);
	for (j = 0; j < entriesCount; j++) {
		maximumScore = 0.0;
		maximumIndex = -1;
		for (k = 0; k < peaksCount; k++) {
			score = [[[[self peaks] objectAtIndex:k] spectrum] scoreComparedToLibraryEntry:[libraryEntries objectAtIndex:j]];
			if (score >= maximumScore) {
				maximumScore = score;
				maximumIndex = k;
			}
		}
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if (maximumScore >= minimumScoreSearchResultsF) {
			NSMutableDictionary *searchResult = [[NSMutableDictionary alloc] init];
			[searchResult setValue:[NSNumber numberWithFloat:maximumScore] forKey:@"score"];
			[searchResult setValue:[libraryEntries objectAtIndex:j] forKey:@"libraryHit"];
			delta = [[[[self peaks] objectAtIndex:maximumIndex] retentionIndex] floatValue] - [[[libraryEntries objectAtIndex:j] retentionIndex] floatValue];
			[searchResult setValue:[NSNumber numberWithFloat:delta] forKey:@"deltaRetentionIndex"];
			[searchResult setValue:[[libraryAlias fullPath] lastPathComponent] forKey:@"library"];
			[[peaks objectAtIndex:maximumIndex] addSearchResult:searchResult];
			[searchResult release];
		}
		if(abortAction){
			JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
			return NO;
		}
	}
	
	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];
	
    [self didChangeValueForKey:@"peaks"];
	return YES;
}

- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak
{
	int k;
	int peaksCount;
	int maximumIndex;
	float score, maximumScore;	
	NSEnumerator *enumerator = [[originatingPeak searchResults] objectEnumerator];
	id searchResult;
	
	peaksCount = [[self peaks] count];
	
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	while ((searchResult = [enumerator nextObject])) {
		maximumScore = 0.0;
		maximumIndex = -1;
		for (k = 0; k < peaksCount; k++) {
			if ([[self peaks] objectAtIndex:k] != originatingPeak) {
				score = [[[[self peaks] objectAtIndex:k] spectrum] scoreComparedToLibraryEntry:[searchResult objectForKey:@"libraryHit"]];
				if (score >= maximumScore) {
					maximumScore = score;
					maximumIndex = k;
				}				
			}
		}
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if ((maximumScore >= minimumScoreSearchResultsF) & (maximumIndex > -1)) {
			[[peaks objectAtIndex:maximumIndex] addSearchResult:searchResult];
		}
		
	}
}

- (void)resetToDefaultValues
{
	id defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
	
	[self setBaselineWindowWidth:[defaultValues valueForKey:@"baselineWindowWidth"]];
	[self setBaselineDistanceThreshold:[defaultValues valueForKey:@"baselineDistanceThreshold"]];
	[self setBaselineSlopeThreshold:[defaultValues valueForKey:@"baselineSlopeThreshold"]];
	[self setBaselineDensityThreshold:[defaultValues valueForKey:@"baselineDensityThreshold"]];
	[self setPeakIdentificationThreshold:[defaultValues valueForKey:@"peakIdentificationThreshold"]];
	[self setRetentionIndexSlope:[defaultValues valueForKey:@"retentionIndexSlope"]];
	[self setRetentionIndexRemainder:[defaultValues valueForKey:@"retentionIndexRemainder"]];
	[self setLibraryAlias:[BDAlias aliasWithPath:[defaultValues valueForKey:@"libraryAlias"]]];
	[self setScoreBasis:[[defaultValues valueForKey:@"scoreBasis"] intValue]];
	[self setPenalizeForRetentionIndex:[[defaultValues valueForKey:@"penalizeForRetentionIndex"] boolValue]];
	[self setMarkAsIdentifiedThreshold:[defaultValues valueForKey:@"markAsIdentifiedThreshold"]];
	[self setMinimumScoreSearchResults:[defaultValues valueForKey:@"minimumScoreSearchResults"]];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Reset to Default Values",@"Reset to Default Values")];
}

- (IBAction)fix:(id)sender 
{
    NSRunAlertPanel(@"Fix old file-format",@"Do not switch to another window until done.",@"Fix",nil,nil);
    NSEnumerator *e = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;
    e = [[self peaks] objectEnumerator];
    while ((peak = [e nextObject])) {
        [peak updateForNewEncoding];
    }
    NSRunAlertPanel(@"Finished Fix",@"Save your file to save it in the new file format.",@"Done",nil,nil);
    [self saveDocumentAs:self];
}

#pragma mark HELPER ACTIONS

- (float)timeForScan:(int)scan  
{
    return time[scan]/60.0f;    
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    int dummy, varid_scanaqtime;
//    float   x;
//    
//    dummy = nc_inq_varid(ncid, "scan_acquisition_time", &varid_scanaqtime);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
//	
//    dummy = nc_get_var1_float(ncid, varid_scanaqtime, (void *) &scan, &x);
//    
////    NSLog(@"time[] %g - new fetch %g", time[scan], x);
//
//    return x;
}

- (int)scanForTime:(float)inTime {
//    NSLog(@"%g",inTime);
    int i;
    inTime = inTime * 60.0f;
    if (inTime <= time[0]) {
        return 0;
    } else if (inTime >= time[numberOfPoints-1]) {
        return numberOfPoints-1;
    }
    for (i=0; i<numberOfPoints; i++) {
        if (time[i]>inTime) {
            return i;
        }
    }
    return numberOfPoints-1;
}

- (float)retentionIndexForScan:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    float   x;
    
    x = [self timeForScan:scan];
    
    return (x/60) * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
}

- (float *)massValuesForSpectrumAtScan:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, start, end, varid_mass_value, varid_scan_index;
	//   float 	xx;
    float 	*x;
    int		num_pts;
	
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return 0;}
	
	
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
	//	dummy = nc_get_var_float(ncid, varid_mass_value, x);
	
	dummy = nc_get_vara_float(ncid, varid_mass_value, (const size_t *) &start, (const size_t *) &num_pts, x);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return x;}
	
	//    for(i = start; i < end; i++) {
	//        dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &i, &xx);
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

- (float *)intensityValuesForSpectrumAtScan:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, start, end, varid_intensity_value, varid_scan_index;
	//   float 	yy;
    float 	*y;
    int		num_pts;
	
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
	
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
	//	dummy = nc_get_var_float(ncid, varid_intensity_value, y);
	
	dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &start, (const size_t *) &num_pts, y);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return y;}
	
	//	//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;	
	//    for(i = start; i < end; i++) {
	//        dummy = nc_get_var1_float(ncid, varid_intensity_value, (void *) &i, &yy);
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

- (ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString  
{
	NSMutableArray *mzValues = [NSMutableArray array];
	NSArray *mzValuesPlus = [inString componentsSeparatedByString:@"+"];
	
	unsigned int i,j,k, mzValuesCount;
	
	for (i = 0; i < [mzValuesPlus count]; i++) {
		NSArray *mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j < (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
					[mzValues addObject:[NSNumber numberWithInt:j]];
				}
			} else {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j < (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j++) {
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
	
	
    int     dummy, scan, dimid, varid_intensity_value, varid_mass_value, varid_scan_index, varid_point_count, scanCount;
    float   mass, intensity;
    float	*times, *masses,	*intensities;
    unsigned int num_pts, num_scan;
    
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return nil;}

//    dummy = nc_inq_varid(ncid, "time_values", &varid_time_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting time_values variable failed. Report error #%d. Continuing...", dummy);}
    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting varid_scan_index variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "point_count", &varid_point_count);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_count variable failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_scan);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return nil;}
    
	masses = (float *) malloc((num_scan)*sizeof(float));
	times = (float *) malloc((num_scan)*sizeof(float));
	intensities = (float *) malloc((num_scan)*sizeof(float));

	for(i = 0; i < num_scan; i++) {
        masses[i] = 0.0f;
        times[i] = 0.0f;
        intensities[i] = 0.0f;
		dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &i, &scan); // is this the start or the end?
		dummy = nc_get_var1_int(ncid, varid_point_count, (void *) &i, &scanCount);
		for(j = scan; j < (unsigned)scan + (unsigned)scanCount; j++) {
            mass = 0.0f;
//            timeL = 0.0f;
            intensity = 0.0f;
			dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &j, &mass);
			for(k = 0; k < mzValuesCount; k++) {
				if (fabs(mass-[[mzValues objectAtIndex:k] intValue]) < 0.5) {
//					dummy = nc_get_var1_float(ncid, varid_time_value, (const size_t *) &j, &timeL);
					dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &j, &intensity);
					
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
        NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:time[i]/60.0f], @"Time",
			[NSNumber numberWithInt:i], @"Scan",
			[NSNumber numberWithFloat:intensities[i]], @"Total Intensity", nil];
		[mutArray addObject:dict];      
		[dict release];
    }

	[chromatogram setDataArray:mutArray];
	[mutArray release];

//	NSLog(@"max tot int: %f; max new int: %f", [self maximumTotalIntensity], jk_stats_float_max(intensities,num_scan));
//	[chromatogram setVerticalScale:[NSNumber numberWithFloat:[self maximumTotalIntensity]/jk_stats_float_max(intensities,num_scan)]];

	[chromatogram setVerticalScale:[NSNumber numberWithFloat:1.0]];
    
    unsigned int count;
    NSArray *presets = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"];
    count = [presets count];
    NSString *title;
    title = mzValuesString;
    for (i=0; i< count; i++) {
        if([[[presets objectAtIndex:i] valueForKey:@"massValue"] isEqualToString:mzValuesString]) {
            title = [NSString stringWithFormat:@"%@ (%@)", [[presets objectAtIndex:i] valueForKey:@"name"], mzValuesString];
        }
    }
	[chromatogram setSeriesTitle:title];
	[chromatogram setSeriesColor:[NSColor redColor]];
	
	[chromatogram setKeyForXValue:@"Scan"];
	[chromatogram setKeyForYValue:@"Total Intensity"];

	[chromatogram autorelease];
	
	return chromatogram;
}

- (SpectrumGraphDataSerie *)spectrumForScan:(int)scan {
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    SpectrumGraphDataSerie *spectrum;
	
    //create a spectrum object
    spectrum = [[SpectrumGraphDataSerie alloc] init];

    int npts;
    npts = [self endValuesSpectrum:scan] - [self startValuesSpectrum:scan];
    [spectrum setKeyForXValue:@"Mass"];
    [spectrum setKeyForYValue:@"Intensity"];
    
    [spectrum loadDataPoints:npts withXValues:[self massValuesForSpectrumAtScan:scan] andYValues:[self intensityValuesForSpectrumAtScan:scan]];
    
	[spectrum setSeriesTitle:[NSString localizedStringWithFormat:@"Scan %d", scan]];
    [spectrum setKeyForXValue:@"Mass"];
    [spectrum setKeyForYValue:@"Intensity"];
	    
	[spectrum autorelease];
	
	return spectrum;
}


- (float *)yValuesIonChromatogram:(float)mzValue  
{
    int         i, dummy, dimid, varid_intensity_value, varid_mass_value;
    float     	xx, yy;
    float 	*y;
    int		num_pts, scanCount;
    scanCount = 0;
    
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return 0;}
    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
    
    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return 0;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return 0;}
    
	
	//	dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &i, (const size_t *) &num_pts, &xx);
	//	nc_get_vara_float(int ncid, int varid,
	//					   const size_t *startp, const size_t *countp, float *ip);
    for(i = 0; i < num_pts; i++) {
        dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &i, &xx);
        if (fabs(xx-mzValue) < 0.5) {
            y = (float *) malloc((scanCount+1)*sizeof(float));
            dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &i, &yy);
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

- (int)startValuesSpectrum:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, start, varid_scan_index;
	
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
	
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
	
    return start;
}


- (int)endValuesSpectrum:(int)scan  
{
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, end, varid_scan_index;
	
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
	
    scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
	
    return end;
}

- (int)countOfValuesForSpectrumAtScan:(int)scan {
    return [self endValuesSpectrum:scan] - [self startValuesSpectrum:scan];
}

- (float)baselineValueAtScan:(int)inValue  
{
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
	int i = 0;
	int baselineCount = [baseline count];
	float lowestScan, lowestInten, highestScan, highestInten;
	
	while (inValue > [[[baseline objectAtIndex:i] valueForKey:@"Scan"] intValue] && i < baselineCount) {
		i++;
	} 
	
	if (i <= 0) {
		lowestScan = 0.0;
		lowestInten = 0.0;
		highestScan = [[[baseline objectAtIndex:i] valueForKey:@"Scan"] floatValue];
		highestInten = [[[baseline objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
	} else {
		lowestScan = [[[baseline objectAtIndex:i-1] valueForKey:@"Scan"] floatValue];
		lowestInten = [[[baseline objectAtIndex:i-1] valueForKey:@"Total Intensity"] floatValue];
		highestScan = [[[baseline objectAtIndex:i] valueForKey:@"Scan"] floatValue];
		highestInten = [[[baseline objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
	}
	
	return (highestInten-lowestInten) * ((inValue-lowestScan)/(highestScan-lowestScan)) + lowestInten; 
}

#pragma mark KEY VALUE CODING/OBSERVING

- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue
{
	[object setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
	
	[undo setActionName:@"Edit"];
}

#pragma mark ACCESSORS (MACROSTYLE)
//idUndoAccessor(peaks, setPeaks, @"Change Peaks");

idUndoAccessor(baselineWindowWidth, setBaselineWindowWidth, @"Change Baseline Window Width")
idUndoAccessor(baselineDistanceThreshold, setBaselineDistanceThreshold, @"Change Baseline Distance Threshold")
idUndoAccessor(baselineSlopeThreshold, setBaselineSlopeThreshold, @"Change Baseline Slope Threshold")
idUndoAccessor(baselineDensityThreshold, setBaselineDensityThreshold, @"Change Baseline Density Threshold")
idUndoAccessor(peakIdentificationThreshold, setPeakIdentificationThreshold, @"Change Peak Identification Threshold")
idUndoAccessor(retentionIndexSlope, setRetentionIndexSlope, @"Change Retention Index Slope")
idUndoAccessor(retentionIndexRemainder, setRetentionIndexRemainder, @"Change Retention Index Remainder")
idUndoAccessor(libraryAlias, setLibraryAlias, @"Change Library")
intUndoAccessor(scoreBasis, setScoreBasis, @"Change Score Basis")
boolUndoAccessor(penalizeForRetentionIndex, setPenalizeForRetentionIndex, @"Change Penalize for Offset Retention Index")
idUndoAccessor(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold, @"Change Identification Score")
idUndoAccessor(minimumScoreSearchResults, setMinimumScoreSearchResults, @"Change Minimum Score")

boolAccessor(abortAction, setAbortAction)

#pragma mark ACCESSORS

- (JKMainWindowController *)mainWindowController  
{
    if (!mainWindowController) {
		mainWindowController = [[JKMainWindowController alloc] init];
		[self makeWindowControllers];
	}
	return mainWindowController;
}

- (void)setNcid:(int)inValue  
{
    ncid = inValue;
}

- (int)ncid  
{
    return ncid;
}

- (int)numberOfPoints  
{
    return numberOfPoints;
}

- (void)setHasSpectra:(BOOL)inValue  
{
    hasSpectra = inValue;
}

- (BOOL)hasSpectra  
{
    return hasSpectra;
}

- (int)intensityCount  
{
    return intensityCount;
}
- (void)setIntensityCount:(int)inValue  
{
    intensityCount = inValue;
}

- (void)setTime:(float *)inArray withCount:(int)inValue  
{
    numberOfPoints = inValue;
    time = (float *) realloc(time, numberOfPoints*sizeof(float));
    memcpy(time, inArray, numberOfPoints*sizeof(float));
	//jk_stats_float_minmax(&minimumTime, &maximumTime, time, 1, numberOfPoints);
	minimumTime = jk_stats_float_min(time, numberOfPoints);
	maximumTime = jk_stats_float_max(time, numberOfPoints);
}

- (float *)time  
{
    return time;
}

- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue  
{
    numberOfPoints = inValue;
    totalIntensity = (float *) realloc(totalIntensity, numberOfPoints*sizeof(float));
    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(float));
	minimumTotalIntensity = jk_stats_float_min(totalIntensity, numberOfPoints);
	maximumTotalIntensity = jk_stats_float_max(totalIntensity, numberOfPoints);
	
}

- (float *)totalIntensity  
{
    return totalIntensity;
}

- (float)maximumTime  
{
    return maximumTime;
}

- (float)minimumTime  
{
    return minimumTime;
}

- (float)maximumTotalIntensity  
{
    return maximumTotalIntensity;
}

- (float)minimumTotalIntensity  
{
    return minimumTotalIntensity;
}

- (NSMutableDictionary *)metadata  
{
	return metadata;
}

- (void)setBaseline:(NSMutableArray *)inValue  
{
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setBaseline:)
                                        object:baseline];
    [[self undoManager] setActionName:NSLocalizedString(@"Change Baseline",@"")];

    [inValue retain];
	[baseline autorelease];
	baseline = inValue;
}

- (NSMutableArray *)baseline  
{
	return baseline;
}

- (NSMutableArray *)chromatograms  
{
	return chromatograms;
}

- (NSMutableArray *)peaks
{
	return peaks;
}

- (void)setPeaks:(NSMutableArray *)array
{
	if (array == peaks)
		return;

	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setPeaks:peaks];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Set Peaks",@"")];
	}
	
	NSEnumerator *e = [peaks objectEnumerator];
	JKPeakRecord *peak;
//	while ((peak = [e nextObject])) {
//		[self stopObservingPeak:peak];
//	}
	
	[peaks release];
	[array retain];
	peaks = array;

	e = [peaks objectEnumerator];
	while ((peak = [e nextObject])) {
        [peak setDocument:self];
	//	[self startObservingPeak:peak];
	}
}

- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index
{
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Peak",@"")];
	}
	
	// Add the peak to the array
    [peak setDocument:self];
//	[self startObservingPeak:peak];
	[peaks insertObject:peak atIndex:index];
}

- (void)removeObjectFromPeaksAtIndex:(int)index
{
	JKPeakRecord *peak = [peaks objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:peak inPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Peak",@"")];
	}
	
	// Remove the peak from the array
//	[self stopObservingPeak:peak];
	[peaks removeObjectAtIndex:index];
}

@end



