//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGCMSDocument.h"

#import "NSString+ModelCompare.h"
#import "PKAppDelegate.h"
#import "PKArrayEncodingObject.h"
#import "PKChromatogram.h"
#import "PKChromatogramDataSeries.h"
#import "PKDataModelProxy.h"
#import "PKGCMSPrintView.h"
#import "PKLibrary.h"
#import "PKLibraryEntry.h"
#import "PKMainWindowController.h"
#import "PKManagedLibraryEntry.h"
#import "PKPanelController.h"
#import "PKPeakRecord.h"
#import "PKPluginProtocol.h"
#import "PKSearchResult.h"
#import "PKSpectrum.h"
#import "NSManagedObject+DatapointAccessors.h"
#import "netcdf.h"
#import "pk_statistics.h"

NSString *const JKGCMSDocument_DocumentDeactivateNotification = @"JKGCMSDocument_DocumentDeactivateNotification";
NSString *const JKGCMSDocument_DocumentActivateNotification   = @"JKGCMSDocument_DocumentActivateNotification";
NSString *const JKGCMSDocument_DocumentLoadedNotification     = @"JKGCMSDocument_DocumentLoadedNotification";
NSString *const JKGCMSDocument_DocumentUnloadedNotification     = @"JKGCMSDocument_DocumentUnloadedNotification";
int const JKGCMSDocument_Version = 7;
int const kBatchSize = 5000;
//static void *DocumentObservationContext = (void *)1100;

@implementation PKGCMSDocument

#pragma mark Initialization & deallocation
- (id)init
{
	self = [super init];
    if (self != nil) {
		metadata = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"", @"sampleCode", @"", @"sampleDescription", nil];
		chromatograms = [[NSMutableArray alloc] init];
		
		_remainingString = [@"" retain];
		
		id defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
        absolutePathToNetCDF = [@"" retain];
		baselineWindowWidth = [[defaultValues valueForKey:@"baselineWindowWidth"] retain];
		baselineDistanceThreshold = [[defaultValues valueForKey:@"baselineDistanceThreshold"] retain];
		baselineSlopeThreshold = [[defaultValues valueForKey:@"baselineSlopeThreshold"] retain];
		baselineDensityThreshold = [[defaultValues valueForKey:@"baselineDensityThreshold"] retain];
		peakIdentificationThreshold = [[defaultValues valueForKey:@"peakIdentificationThreshold"] retain];
		retentionIndexSlope = [[defaultValues valueForKey:@"retentionIndexSlope"] retain];
		retentionIndexRemainder = [[defaultValues valueForKey:@"retentionIndexRemainder"] retain];
        libraryConfiguration = [[defaultValues valueForKey:@"libraryConfiguration"] retain];
        searchTemplate = [[defaultValues valueForKey:@"searchTemplate"] retain];
        
		scoreBasis = [[defaultValues valueForKey:@"scoreBasis"] intValue];
		searchDirection = [[defaultValues valueForKey:@"searchDirection"] intValue];
		spectrumToUse = [[defaultValues valueForKey:@"spectrumToUse"] intValue];
		penalizeForRetentionIndex = [[defaultValues valueForKey:@"penalizeForRetentionIndex"] boolValue];
		markAsIdentifiedThreshold = [[defaultValues valueForKey:@"markAsIdentifiedThreshold"] retain];
		minimumScoreSearchResults = [[defaultValues valueForKey:@"minimumScoreSearchResults"] retain];
		minimumScannedMassRange = [[defaultValues valueForKey:@"minimumScannedMassRange"] retain];
		maximumScannedMassRange = [[defaultValues valueForKey:@"maximumScannedMassRange"] retain];
        maximumRetentionIndexDifference = [[defaultValues valueForKey:@"maximumRetentionIndexDifference"] retain];
        
        uuid = [@"uuid" retain];
        uuid = [GetUUID() retain];
        
        baselineDetectionMethod = [@"Default Baseline Detection Method" retain];
        peakDetectionMethod = [@"Default Peak Detection Method" retain];
        spectraMatchingMethod = [@"Abundance" retain];
        
        [[self undoManager] disableUndoRegistration];
        _documentProxy = [[NSDictionary alloc] initWithObjectsAndKeys:@"_documentProxy", @"_documentProxy",nil];
        [self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
        [[self printInfo] setOrientation:NSLandscapeOrientation];
        printView = [[PKGCMSPrintView alloc] initWithDocument:self];
        [[self undoManager] enableUndoRegistration];
        _lastReturnedIndex = -1;
	}
    return self;
}

- (void)close
{
    [[NSNotificationCenter defaultCenter] postNotificationName:JKGCMSDocument_DocumentUnloadedNotification object:self];
    [super close];
}

- (void)dealloc {
    [_documentProxy release];
    [_remainingString release];
    [absolutePathToNetCDF release];
	[metadata release];
	[chromatograms release];
	[baselineWindowWidth release];
	[baselineDistanceThreshold release];
	[baselineSlopeThreshold release];
	[baselineDensityThreshold release];
	[peakIdentificationThreshold release];
	[retentionIndexSlope release];
	[retentionIndexRemainder release];
    [libraryConfiguration release];
    [searchTemplate release];
	[markAsIdentifiedThreshold release];
	[minimumScoreSearchResults release];
    [maximumRetentionIndexDifference release];
	[printView release];
    [baselineDetectionMethod release];
    [peakDetectionMethod release];
    [spectraMatchingMethod release]; 
    
	int dummy;
	dummy = nc_close(ncid);
//	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"File closing error",@"File closing error") format:NSLocalizedString(@"Closing NetCDF file caused problem.\nNetCDF error: %d",@""), dummy];
    if (mainWindowController) {
        [mainWindowController release];
    }
    [super dealloc];
}
#pragma mark -

#pragma mark Window Management

- (void)makeWindowControllers {
    if (!mainWindowController) {
        mainWindowController = [[PKMainWindowController alloc] init];
     }
    [self addWindowController:mainWindowController];
    [[NSNotificationCenter defaultCenter] postNotificationName:JKGCMSDocument_DocumentLoadedNotification object:self];
}

#pragma mark -

#pragma mark File Access Management

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType {
	if ([aType isEqualToString:@"Peacock File"] || [aType isEqualToString:@"nl.johankool.peacock.data"]) {
//        NSDate *date = [NSDate date];
		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setDelegate:self];
//        PKLogDebug(@"Saving time 1: %g", [date timeIntervalSinceNow]);
		[archiver encodeInt:JKGCMSDocument_Version forKey:@"version"];
 		[archiver encodeObject:[self chromatograms] forKey:@"chromatograms"];
//        PKLogDebug(@"Saving time 2: %g", [date timeIntervalSinceNow]);
//		[archiver encodeObject:[self peaks] forKey:@"peaks"];
		[archiver encodeObject:[self metadata] forKey:@"metadata"];		
		[archiver encodeObject:baselineWindowWidth forKey:@"baselineWindowWidth"];
		[archiver encodeObject:baselineDistanceThreshold forKey:@"baselineDistanceThreshold"];
		[archiver encodeObject:baselineSlopeThreshold forKey:@"baselineSlopeThreshold"];
		[archiver encodeObject:baselineDensityThreshold forKey:@"baselineDensityThreshold"];
		[archiver encodeObject:peakIdentificationThreshold forKey:@"peakIdentificationThreshold"];
		[archiver encodeObject:[self retentionIndexSlope] forKey:@"retentionIndexSlope"];
		[archiver encodeObject:[self retentionIndexRemainder] forKey:@"retentionIndexRemainder"];
//		[archiver encodeObject:libraryAlias forKey:@"libraryAlias"];
		[archiver encodeObject:libraryConfiguration forKey:@"libraryConfiguration"];
		[archiver encodeObject:searchTemplate forKey:@"searchTemplate"];
		[archiver encodeInt:scoreBasis forKey:@"scoreBasis"];
		[archiver encodeInt:searchDirection forKey:@"searchDirection"];
		[archiver encodeInt:spectrumToUse forKey:@"spectrumToUse"];
		[archiver encodeBool:penalizeForRetentionIndex forKey:@"penalizeForRetentionIndex"];
		[archiver encodeObject:[self markAsIdentifiedThreshold] forKey:@"markAsIdentifiedThreshold"];
		[archiver encodeObject:[self minimumScoreSearchResults] forKey:@"minimumScoreSearchResults"];
		[archiver encodeObject:[self minimumScannedMassRange] forKey:@"minimumScannedMassRange"];
		[archiver encodeObject:[self maximumScannedMassRange] forKey:@"maximumScannedMassRange"];
//        PKLogDebug(@"Saving time 3: %g", [date timeIntervalSinceNow]);

		[archiver finishEncoding];
//        PKLogDebug(@"Saving time 4: %g", [date timeIntervalSinceNow]);
		[archiver release];
		
		if (peacockFileWrapper) {
			// This is when we save back to a peacock file
//            PKLogDebug(@"Saving time 5b: %g", [date timeIntervalSinceNow]);

			[peacockFileWrapper removeFileWrapper:[[peacockFileWrapper fileWrappers] valueForKey:@"peacock-data"]];
			NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:data];
			[fileWrapperForData setPreferredFilename:@"peacock-data"];
			[peacockFileWrapper addFileWrapper:fileWrapperForData];
//            PKLogDebug(@"Saving time 6b: %g", [date timeIntervalSinceNow]);

			// NetCDF file should not have changed!
			
		} else {
			// First time save to a peacock file
//            PKLogDebug(@"Saving time 5a: %g", [date timeIntervalSinceNow]);

			NSMutableDictionary *fileWrappers = [[NSMutableDictionary alloc] init];
				
			NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:data];
			NSAssert(data != nil, @"data = nil!");
			NSAssert(fileWrapperForData != nil, @"fileWrapperForData = nil!");
			[fileWrapperForData setPreferredFilename:@"peacock-data"];
			[fileWrappers setObject:fileWrapperForData forKey:@"peacock-data"];	
//            PKLogDebug(@"Saving time 6a: %g", [date timeIntervalSinceNow]);

			NSFileWrapper *fileWrapperForNetCDF = [[NSFileWrapper alloc] initWithPath:absolutePathToNetCDF];
            NSAssert(fileWrapperForNetCDF != nil, @"fileWrapperForNetCDF = nil!");
			[fileWrapperForNetCDF setPreferredFilename:@"netcdf"];
			[fileWrappers setObject:fileWrapperForNetCDF forKey:@"netcdf"];		
 //           PKLogDebug(@"Saving time 7a: %g", [date timeIntervalSinceNow]);

			peacockFileWrapper = [[NSFileWrapper alloc] initDirectoryWithFileWrappers:fileWrappers];			
		}
//        PKLogDebug(@"Saving time 8: %g", [date timeIntervalSinceNow]);

		return peacockFileWrapper;	
		
	} else if ([aType isEqualToString:@"Tab Delimited Text File"] || [aType isEqualToString:@"public.plain-text"]) {
		NSFileWrapper *fileWrapperForData = [[NSFileWrapper alloc] initRegularFileWithContents:[[self exportTabDelimitedText] dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES]];
		[fileWrapperForData autorelease];
		return fileWrapperForData;
	} else {
		return nil;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	BOOL result;
	if ([typeName isEqualToString:@"NetCDF/ANDI File"] || [typeName isEqualToString:@"edu.ucar.unidata.netcdf.andi"]) {
        [self setAbsolutePathToNetCDF:[absoluteURL path]];
        result = [self readNetCDFFile:[absoluteURL path] error:outError];
        [[self undoManager] disableUndoRegistration];
        [self insertObject:[self ticChromatogram] inChromatogramsAtIndex:0];
        [[self undoManager] enableUndoRegistration];
        return result;
	} else if ([typeName isEqualToString:@"Peacock File"] || [typeName isEqualToString:@"nl.johankool.peacock.data"]) {		
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
        [[self undoManager] disableUndoRegistration];
        
        result = [self readNetCDFFile:[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"] error:outError];
		if (result) {
			peacockFileWrapper = wrapper;
		} else {
            PKLogError(@"No NetCDF file found at '%@'.",[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"]);
            return NO;
        }
        
        NSData *data = nil;
		NSKeyedUnarchiver *unarchiver = nil;
		data = [[[wrapper fileWrappers] valueForKey:@"peacock-data"] regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        // Since some classes got renamed, but are encoded, we need to tell the unarchiver the new names
        [unarchiver setClass:[PKChromatogram class] forClassName:@"JKChromatogram"];
        [unarchiver setClass:[PKSpectrum class] forClassName:@"JKSpectrum"];
        [unarchiver setClass:[PKPeakRecord class] forClassName:@"JKPeakRecord"];
        [unarchiver setClass:[PKSearchResult class] forClassName:@"JKSearchResult"];
        [unarchiver setClass:[PKManagedLibraryEntry class] forClassName:@"JKManagedLibraryEntry"];
        [unarchiver setClass:[PKLibraryEntry class] forClassName:@"JKLibraryEntry"];
        [unarchiver setClass:[PKArrayEncodingObject class] forClassName:@"ArrayEncodingObject"];
        
        [unarchiver setDelegate:self];
		int version = [unarchiver decodeIntForKey:@"version"];
        switch (version) {
        case 0:
        case 1:
        case 2:
        case 3:
        case 4:
            [chromatograms removeAllObjects];
            [chromatograms addObject:[self ticChromatogram]];
            [[chromatograms objectAtIndex:0] setPeaks:[unarchiver decodeObjectForKey:@"peaks"]];
            break;
        case 5:
            [self setChromatograms:[unarchiver decodeObjectForKey:@"chromatograms"]];
            break;
        case 6:
            [self setChromatograms:[unarchiver decodeObjectForKey:@"chromatograms"]];
            [self setMinimumScannedMassRange:[unarchiver decodeObjectForKey:@"minimumScannedMassRange"]];
            [self setMaximumScannedMassRange:[unarchiver decodeObjectForKey:@"maximumScannedMassRange"]];
            break;
        default:
        case 7:
            [self setLibraryConfiguration:[unarchiver decodeObjectForKey:@"libraryConfiguration"]];
            [self setSearchTemplate:[unarchiver decodeObjectForKey:@"searchTemplate"]];
            [self setChromatograms:[unarchiver decodeObjectForKey:@"chromatograms"]];
            [self setMinimumScannedMassRange:[unarchiver decodeObjectForKey:@"minimumScannedMassRange"]];
            [self setMaximumScannedMassRange:[unarchiver decodeObjectForKey:@"maximumScannedMassRange"]];
            break;
        }
        [self setMetadata:[unarchiver decodeObjectForKey:@"metadata"]];
        [self setBaselineWindowWidth:[unarchiver decodeObjectForKey:@"baselineWindowWidth"]];
        [self setBaselineDistanceThreshold:[unarchiver decodeObjectForKey:@"baselineDistanceThreshold"]];
        [self setBaselineSlopeThreshold:[unarchiver decodeObjectForKey:@"baselineSlopeThreshold"]];
        [self setBaselineDensityThreshold:[unarchiver decodeObjectForKey:@"baselineDensityThreshold"]];
        [self setPeakIdentificationThreshold:[unarchiver decodeObjectForKey:@"peakIdentificationThreshold"]];
        [self setRetentionIndexSlope:[unarchiver decodeObjectForKey:@"retentionIndexSlope"]];
        [self setRetentionIndexRemainder:[unarchiver decodeObjectForKey:@"retentionIndexRemainder"]];	
        [self setScoreBasis:[unarchiver decodeIntForKey:@"scoreBasis"]];
        [self setSearchDirection:[unarchiver decodeIntForKey:@"searchDirection"]];
        [self setSpectrumToUse:[unarchiver decodeIntForKey:@"spectrumToUse"]];
        [self setPenalizeForRetentionIndex:[unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"]];
        if ([[unarchiver decodeObjectForKey:@"markAsIdentifiedThreshold"] isKindOfClass:[NSNumber class]])
            [self setMarkAsIdentifiedThreshold:[unarchiver decodeObjectForKey:@"markAsIdentifiedThreshold"]];		
        [self setMinimumScoreSearchResults:[unarchiver decodeObjectForKey:@"minimumScoreSearchResults"]];		            
        
		[unarchiver finishDecoding];
		[unarchiver release];
        [[self undoManager] enableUndoRegistration];
        
        // Ensure the TIC chromatogram is still there
        // This should be saved, so is done after reenabling undo
        PKChromatogram *ticChromatogram = [self ticChromatogram];
        if (![[self chromatograms] containsObject:ticChromatogram]) {
            [self insertObject:ticChromatogram inChromatogramsAtIndex:0];
        }

// [BUG] This code cause a *** Collection <NSCFArray: 0x647370> was mutated while being enumerated.-exception.
//        for (PKChromatogram *chromatogram in [self chromatograms]) {
//            if (![[chromatogram model] isEqualToString:@"TIC"] && [chromatogram countOfPeaks] == 0) {
//                [self removeObjectFromChromatogramsAtIndex:[[self chromatograms] indexOfObject:chromatogram]];
//            }
//        }
        
        
        [chromatograms sortUsingSelector:@selector(sortOrderComparedTo:)];
  		return result;	
    } else {
        if (outError != NULL)
			*outError = [[[NSError alloc] initWithDomain:NSCocoaErrorDomain
												   code:NSFileReadUnknownError userInfo:nil] autorelease];
		return NO;
	}	
}

- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object {
    if (object == self) {
        return _documentProxy;
    }
    return object;
}

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([[object valueForKey:@"_documentProxy"] isEqualToString:@"_documentProxy"]) {
            PKLogDebug(@"retaincount = %d",[self retainCount]);
            return self;
        }
    }
   
    return object;
}

- (NSString *)autosavingFileType {
    return @"Peacock File";
}
#pragma mark -

#pragma mark Import/Export Actions
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError {
	int errCode;
    int dimid;
    BOOL	hasVarid_scanaqtime;

	// Get the file's name and pull the id. Test to make sure that this all worked.
	errCode = nc_open([fileName cStringUsingEncoding:NSASCIIStringEncoding], NC_NOWRITE, &ncid);
	if (errCode != NC_NOERR) {
		if (anError != NULL)
			*anError = [[[NSError alloc] initWithDomain:@"JKNetCDFDomain" 
												   code:errCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unreadable file", NSLocalizedDescriptionKey, @"The file was not readable as a NetCDF file.", NSLocalizedFailureReasonErrorKey, @"Try exporting from the originating application again selecting NetCDF as the export file format.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
		return NO;
	}
	
	[self setNcid:ncid];
	[self setAbsolutePathToNetCDF:fileName];
	
	//    NS_DURING
	
//	if ([self ncid] == nil) {
//		[NSException raise:NSLocalizedString(@"NetCDF data absent",@"NetCDF data absent") format:NSLocalizedString(@"No id for the NetCDF file could be obtained, which is critical for accessing the data.",@"")];
//		return NO;
//	}
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
	
	return YES;
	//	NS_HANDLER
	//		NSRunAlertPanel([NSString stringWithFormat:@"Error: %@",[localException name]], @"%@", @"OK", nil, nil, localException);
	//	NS_ENDHANDLER
}	 


- (NSString *)exportTabDelimitedText {
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array = [[[self mainWindowController] peakController] arrangedObjects];
	
	[outStr appendString:NSLocalizedString(@"File\tID\tLabel\tScore\tIdentified\tConfirmed\tStart (scan)\tTop (scan)\tEnd (scan)\tHeight (normalized)\tSurface (normalized)\tHeight (abs.)\tSurface (abs.)\tBaseline Left\tBaseline Right\tName (Lib.)\tFormula (Lib.)\tCAS No. (Lib.)\tRetention Index (Lib.)\tComment (Lib.)\n",@"Top row of tab delimited text export.")];
	for (id loopItem in array) {
		[outStr appendFormat:@"%@\t", [self displayName]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"peakID"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"label"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.score"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"identified"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"confirmed"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"start"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"top"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"end"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"startTime"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"topTime"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"endTime"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"normalizedHeight"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"normalizedSurface"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"height"]];
//		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"width"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"surface"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"baselineLeft"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKey:@"baselineRight"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.libraryHit.name"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.libraryHit.formula"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.libraryHit.CASNumber"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.libraryHit.retentionIndex"]];
		[outStr appendFormat:@"%@\t", [loopItem valueForKeyPath:@"identifiedSearchResult.libraryHit.comment"]];
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
		
		PKLibraryEntry *libEntry = [[PKLibraryEntry alloc] initWithJCAMPString:[array objectAtIndex:i]];
				
		// Add data to Library
		[libraryEntries addObject:libEntry];
		[libEntry release];
	}
	
	// library Array should be returned
	// and the remaining string
	_remainingString = [array objectAtIndex:count-1];
	
	PKLogDebug(@"Found %d entries", [libraryEntries count]);
	[libraryEntries autorelease];
    return libraryEntries;	
}
#pragma mark -

#pragma mark IBActions
- (IBAction)openNext:(id)sender {
	NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:[[self fileName] stringByDeletingLastPathComponent]];
	NSError *error = nil;
	BOOL openNext = NO;
	for (id loopItem in content) {
		if (openNext) {
			[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[[self fileName] stringByDeletingLastPathComponent] stringByAppendingPathComponent:loopItem]] display:YES error:&error];
			break;
		}
		if ([loopItem isEqualToString:[[self fileName] lastPathComponent]]) {
			openNext = YES;
		}
	}
	[error release];
}
//- (IBAction)updateLibraryHits:(id)sender {
//    [self updateLibraryHits];
//}
#pragma mark -

#pragma mark Sorting Documents
// Used by the summary feature
- (NSComparisonResult)metadataCompare:(PKGCMSDocument *)otherDocument {
	int metadataChoosen = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"columnSorting"] intValue];

	switch (metadataChoosen) {
	case 1: // samplecode
		return [[self sampleCode] caseInsensitiveCompare:[otherDocument sampleCode]];
		break;
	case 2: // sampleDescription
		return [[self sampleDescription] caseInsensitiveCompare:[otherDocument sampleDescription]];
		break;
	default:
		return [[self sampleCode] caseInsensitiveCompare:[otherDocument sampleCode]];
		break;
	}
		
}
#pragma mark -

- (NSString *)sampleCode {
    return [metadata valueForKey:@"sampleCode"];
}

- (NSString *)sampleDescription {
    return [metadata valueForKey:@"sampleDescription"];
}

#pragma mark Printing
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo {
    [self setPrintInfo:newPrintInfo];
    return YES;
}
- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Prepare the custom view that will be printed
    [printView preparePDFRepresentations];
    
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
							 printInfo:[self printInfo]];
    
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
		[op setAccessoryView:[mainWindowController printAccessoryView]];
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
						delegate:nil
				  didRunSelector:@selector(documentDidRunModalPrintOperation:success:contextInfo:)
					 contextInfo:NULL];
}
- (void)documentDidRunModalPrintOperation:(NSDocument *)document  success:(BOOL)success  contextInfo:(void *)contextInfo {
//    [printView release];
}
#pragma mark -

#pragma mark PlugIn Support
- (NSString *)baselineDetectionMethod {
    return baselineDetectionMethod;
}
- (void)setBaselineDetectionMethod:(NSString *)methodName {
    if (![methodName isEqualToString:baselineDetectionMethod]) {  
 		[[self undoManager] registerUndoWithTarget:self
									      selector:@selector(setBaselineDetectionMethod:)
											object:baselineDetectionMethod];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Baseline Detection Method", @"Undo for Change Baseline Detection Method")];
        }
        
        [methodName copy];
        [baselineDetectionMethod autorelease];
        baselineDetectionMethod = methodName;   
	}
}
- (BOOL)validateBaselineDetectionMethod:(id *)ioValue error:(NSError **)outError {
    BOOL valid = NO;
    // The method name should be one registered with the app from one of its plugins
    for (NSString *methodName in [[NSApp delegate] baselineDetectionMethodNames]) {
        if ([*ioValue isEqualToString:methodName]) {
            valid = YES;
        } 
    }
    
    if (!valid) {
        NSString *errorString = NSLocalizedString(@"Unknown Baseline Detection Method", @"Unknown Baseline Detection Method error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:802
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    
    return YES;    
}
- (void)setBaselineDetectionSettings:(NSDictionary *)settings forMethod:(NSString *)methodName {
    [baselineDetectionSettings setObject:settings forKey:methodName];
}
- (NSDictionary *)baselineDetectionSettingsForMethod:(NSString *)methodName {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self baselineDensityThreshold], @"baselineDensityThreshold", [self baselineDistanceThreshold], @"baselineDistanceThreshold", [self baselineSlopeThreshold], @"baselineSlopeThreshold", [self baselineWindowWidth], @"baselineWindowWidth", nil];
//    return [baselineDetectionSettings objectForKey:methodName];
}

- (NSString *)peakDetectionMethod {
    return peakDetectionMethod;
}
- (void)setPeakDetectionMethod:(NSString *)methodName {
    if (![methodName isEqualToString:peakDetectionMethod]) {  
 		[[self undoManager] registerUndoWithTarget:self
									      selector:@selector(setPeakDetectionMethod:)
											object:peakDetectionMethod];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Detection Method", @"Undo for Change Peak Detection Method")];
        }
        
        [methodName copy];
        [peakDetectionMethod autorelease];
        peakDetectionMethod = methodName;   
	}
}
- (BOOL)validatePeakDetectionMethod:(id *)ioValue error:(NSError **)outError {
    BOOL valid = NO;
    // The method name should be one registered with the app from one of its plugins
    for (NSString *methodName in [[NSApp delegate] peakDetectionMethodNames]) {
        if ([*ioValue isEqualToString:methodName]) {
            valid = YES;
        } 
    }
    
    if (!valid) {
        NSString *errorString = NSLocalizedString(@"Unknown Peak Detection Method", @"Unknown Peak Detection Method error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:803
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    
    return YES;    
}
- (void)setPeakDetectionSettings:(NSDictionary *)settings forMethod:(NSString *)methodName {
    [peakDetectionSettings setObject:settings forKey:methodName];
}
- (NSDictionary *)peakDetectionSettingsForMethod:(NSString *)methodName {
    return [NSDictionary dictionaryWithObjectsAndKeys:[self peakIdentificationThreshold], @"peakIdentificationThreshold", nil];
//    return [peakDetectionSettings objectForKey:methodName];
}

- (NSString *)spectraMatchingMethod {
    return spectraMatchingMethod;
}
- (void)setSpectraMatchingMethod:(NSString *)methodName {
    if (![methodName isEqualToString:spectraMatchingMethod]) {  
 		[[self undoManager] registerUndoWithTarget:self
									      selector:@selector(setSpectraMatchingMethod:)
											object:spectraMatchingMethod];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Spectra Matching Method", @"Undo for Change Spectra Matching Method")];
        }
        
        [methodName copy];
        [spectraMatchingMethod autorelease];
        spectraMatchingMethod = methodName;   
	}
}
- (BOOL)validateSpectraMatchingMethod:(id *)ioValue error:(NSError **)outError {
    BOOL valid = NO;
    // The method name should be one registered with the app from one of its plugins
    for (NSString *methodName in [[NSApp delegate] spectraMatchingMethodNames]) {
        if ([*ioValue isEqualToString:methodName]) {
            valid = YES;
        } 
    }
    
    if (!valid) {
        NSString *errorString = NSLocalizedString(@"Unknown Spectra Matching Method", @"Unknown Spectra Matching Method error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:804
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    
    return YES;    
}
- (void)setSpectraMatchingSettings:(NSDictionary *)settings forMethod:(NSString *)methodName {
    [spectraMatchingSettings setObject:settings forKey:methodName];
}
- (NSDictionary *)spectraMatchingSettingsForMethod:(NSString *)methodName {
    return [spectraMatchingSettings objectForKey:methodName];
}
#pragma mark -


#pragma mark Model
- (PKChromatogram *)ticChromatogram {
    // Check if such a chromatogram is already available
    for (PKChromatogram *chromatogram in [self chromatograms]) {
        if ([[chromatogram model] isEqualToString:@"TIC"]) {
            return chromatogram;
        }
    }
    
    float *time;
    float *totalIntensity;
    int dummy, dimid, numberOfPoints, varid_scanaqtime, varid_totintens;
    BOOL hasVarid_scanaqtime;
    
    if ([self hasSpectra]) {
        // GCMS file
        dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_dimlen(ncid, dimid, (void *) &numberOfPoints);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid(ncid, "scan_acquisition_time", &varid_scanaqtime);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scan_acquisition_time variable failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_varid(ncid, "total_intensity", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting total_intensity dimension failed.\nNetCDF error: %d",@""), dummy];
        
    } else {
        // GC file
        dummy = nc_inq_dimid(ncid, "point_number", &dimid);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension failed.\nNetCDF error: %d",@""), dummy];
		
        dummy = nc_inq_dimlen(ncid, dimid, (void *) &numberOfPoints);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting point_number dimension length failed.\nNetCDF error: %d",@""), dummy];
        
        dummy = nc_inq_varid(ncid, "raw_data_retention", &varid_scanaqtime);
		//		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting raw_data_retention variable failed.\nNetCDF error: %d",@""), dummy];
        if(dummy != NC_NOERR) { NSBeep(); PKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
        
        dummy = nc_inq_varid(ncid, "ordinate_values", &varid_totintens);
		if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting ordinate_values variable failed.\nNetCDF error: %d",@""), dummy];
    }
	
    // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
    time = (float *) malloc(numberOfPoints*sizeof(float));
    totalIntensity = (float *) malloc(numberOfPoints*sizeof(float));
	
	dummy = nc_get_var_float(ncid, varid_scanaqtime, time);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting scanaqtime variables failed.\nNetCDF error: %d",@""), dummy];
	
	dummy = nc_get_var_float(ncid, varid_totintens, totalIntensity);
	if(dummy != NC_NOERR) [NSException raise:NSLocalizedString(@"Expected data absent",@"Expected data absent") format:NSLocalizedString(@"Getting totintens variables failed.\nNetCDF error: %d",@""), dummy];
	
    PKChromatogram *chromatogram = [[PKChromatogram alloc] initWithModel:@"TIC"];
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
    PKLogDebug(@"model %@", model);
    int     dummy, scan, dimid, varid_intensity_value, varid_mass_value, varid_scan_index, varid_point_count, scanCount; //varid_time_value
    float   mass, intensity;
    float	*times,	*intensities;
    unsigned int numberOfPoints, num_scan;
    int i,j,k,start,end,mzValuesCount,mzValuesCountPlus;
    
    model = [model cleanupModelString];
    
    // Check if such a chromatogram is already available
    for (PKChromatogram *chromatogram in [self chromatograms]) {
        if ([[chromatogram model] isEqualToModelString:model]) {
            return chromatogram;
        }
    }
    
    if ([model isEqualToString:@""]) {
        return nil;
    }
    if ([model isEqualToString:@"TIC"]) {
        return [self ticChromatogram];
    }
    
    [model stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
    if ([model isEqualToString:@""]) {
        return nil;
    }
    
    // Find out how many values are covered
	NSArray *mzValuesPlus = [model componentsSeparatedByString:@"+"];
    NSArray *mzValuesMin = nil;
    mzValuesCount = [mzValuesPlus count];
    mzValuesCountPlus = mzValuesCount;
	for (i = 0; i < mzValuesCountPlus; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
            start = [[mzValuesMin objectAtIndex:0] intValue];
            end = [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue];
            mzValuesCount += abs(end-start);
		} 
	}
    // Return empty string if zero (e.g. when string was "-+-+")
    if (mzValuesCount < 1) {
        return nil;
    } 
    
    // Collect the values
    int mzValues[mzValuesCount];
    k = 0;
    for (i = 0; i < mzValuesCountPlus; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
            start = [[mzValuesMin objectAtIndex:0] intValue];
            end = [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue];
			if (start < end) {
				for (j = start; j <= end; j++) {
                    mzValues[k] = j;     
                    k++;
				}
			} else {
				for (j = end; j <= start; j++) {
                    mzValues[k] = j;     
                    k++;
				}
			}
		} else {
            mzValues[k] = [[mzValuesMin objectAtIndex:0] intValue];
            k++;
		}
	}
    
	// Sort mzValues
    insertionSort(mzValues, mzValuesCount);
        

    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { PKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return nil;}
    
//    dummy = nc_inq_varid(ncid, "time_values", &varid_time_value);
//    if(dummy != NC_NOERR) { PKLogError(@"Getting time_values variable failed. Report error #%d. Continuing...", dummy);}
    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { PKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { PKLogError(@"Getting varid_scan_index variable failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_varid(ncid, "point_count", &varid_point_count);
    if(dummy != NC_NOERR) { PKLogError(@"Getting point_count variable failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
    if(dummy != NC_NOERR) { PKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &numberOfPoints);
    if(dummy != NC_NOERR) { PKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
	
    dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
    if(dummy != NC_NOERR) { PKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return nil;}
    
    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_scan);
    if(dummy != NC_NOERR) { PKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return nil;}
    
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
        if(dummy != NC_NOERR) { PKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return nil;}
        
        
        for(j = 0; j < (unsigned)scanCount; j++) {
            mass = massValues[j];
            intensity = 0.0f;
			//dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &j, &mass);
            // find out wether the mass encountered is on the masses we are interested in
			for(k = 0; k < mzValuesCount; k++) {
				if (fabsf(mass-mzValues[k]*1.0f) < 0.5f) {
                    intScan = j+ scan;
					dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &intScan, &intensity);					
					intensities[i] = intensities[i] + intensity;
				}
			}
		}
	}
	
    // Create a chromatogram object
    PKChromatogram *chromatogram = [[PKChromatogram alloc] initWithModel:model];
    [chromatogram setContainer:self];
    [chromatogram setTime:times withCount:num_scan];
    [chromatogram setTotalIntensity:intensities withCount:num_scan];
    
//    // Obtain the baseline
//    [chromatogram detectBaselineAndReturnError:nil];
    
    // Clean up
    free(massValues);

	return [chromatogram autorelease];    
}

 
- (BOOL)addChromatogramForModel:(NSString *)modelString {
    PKChromatogram *chromatogram = [self chromatogramForModel:modelString];
    if (!chromatogram) {
        return NO;
    }
    if (![[self chromatograms] containsObject:chromatogram]) {
        [self insertObject:chromatogram inChromatogramsAtIndex:[[self chromatograms] count]];  
        return YES;
    }
    return NO;
}

- (PKSpectrum *)spectrumForScan:(int)scan {
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    int dummy, start, end, varid_mass_value, varid_intensity_value, varid_scan_index;
    int numberOfPoints;
    float 	*massValues;
    float 	*intensities;
    
    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
    if(dummy != NC_NOERR) { PKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return 0;}
    
    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
    if(dummy != NC_NOERR) { PKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
    
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
    if(dummy != NC_NOERR) { PKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
    
    scan++;
    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
    if(dummy != NC_NOERR) { PKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
    
    numberOfPoints = end - start;
    
    massValues = (float *) malloc(numberOfPoints*sizeof(float));
    
    dummy = nc_get_vara_float(ncid, varid_mass_value, (const size_t *) &start, (const size_t *) &numberOfPoints, massValues);
    if(dummy != NC_NOERR) { PKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return nil;}

    
    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
    if(dummy != NC_NOERR) { PKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
        
    intensities = (float *) malloc((numberOfPoints)*sizeof(float));
    
    dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &start, (const size_t *) &numberOfPoints, intensities);
    if(dummy != NC_NOERR) { PKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return nil;}
    
    PKSpectrum *spectrum = [[PKSpectrum alloc] initWithModel:[NSString stringWithFormat:@"scan %d",scan-1]];
  
    [spectrum setMasses:massValues withCount:numberOfPoints];
    [spectrum setIntensities:intensities withCount:numberOfPoints];

    free(massValues);
    free(intensities);
    
	[spectrum autorelease];
	return spectrum;
}

- (id)objectForSpectraMatching:(NSError **)error {
//       NSString *spectraMatchingMethod = [[self document] spectraMatchingMethod];
    if (!spectraMatchingMethod || [spectraMatchingMethod isEqualToString:@""]) {
        // Error 807
        // Spectra Matching Method not set
        NSString *errorString = NSLocalizedString(@"Spectra Matching Method not set", @"Spectra Matching Method not set error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:807
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;    
        PKLogError(errorString);
        return nil;
    }
    
    NSObject <PKPluginProtocol> *plugIn = [[[NSApp delegate] spectraMatchingMethods] valueForKey:spectraMatchingMethod];
    if (plugIn) {
        NSObject <PKSpectraMatchingMethodProtocol> *object = [plugIn sharedObjectForMethod:spectraMatchingMethod];
        if (object) {
            //PKLogInfo(@"spectraMatchingObject is %@", object);
            return object;
        } else {
            // Error 801
            // Invalid Plugin
            NSString *errorString = NSLocalizedString(@"PlugIn does not implement method as claimed", @"PlugIn does not implement method as claimed error");
            NSDictionary *userInfoDict =
            [NSDictionary dictionaryWithObject:errorString
                                        forKey:NSLocalizedDescriptionKey];
            NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                           code:801
                                                       userInfo:userInfoDict] autorelease];
            *error = anError;             
            PKLogError(errorString);
            return nil;
        }
    } else {
        // Error 800
        // Plugin failed to initialize
        NSString *errorString = NSLocalizedString(@"PlugIn Unloaded/Method not currently available", @"PlugIn Unloaded/Method not currently available error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:800
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;          
        PKLogError(errorString);
        return nil;
    }
}

- (BOOL)performLibrarySearchForChromatograms:(NSArray *)someChromatograms error:(NSError **)error {
    switch (searchDirection) {
    case JKForwardSearchDirection:
        NSAssert([someChromatograms count] > 0, @"No chromatograms were selected to be searched.");
            return [self performForwardSearchForChromatograms:someChromatograms error:error];
        break;
    case JKBackwardSearchDirection:
            return [self performBackwardSearchAndReturnError:error];
        break;
    default:
        break;
    }
    // Error 302
    // Search direction not set
    NSString *errorString = NSLocalizedString(@"Search direction not set", @"error 302: Search direction not set");
    NSString *recoverySuggestionString = NSLocalizedString(@"Set the search direction in the processing pane of the inspector.", @"error 302: Search direction not set recovery suggestion");
    NSDictionary *userInfoDict =
    [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
    NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                   code:302
                                               userInfo:userInfoDict] autorelease];
    *error = anError;
    return NO;
}

- (BOOL)performForwardSearchForChromatograms:(NSArray *)someChromatograms error:(NSError **)error {
    _isBusy = YES;
    PKPeakRecord *peak = nil;
    PKChromatogram *chromatogramToSearch = nil;
	int j,k,l;
	int entriesCount, chromatogramCount, peaksCount;

    
    
	[self setAbortAction:NO];
    NSProgressIndicator *progressIndicator = nil;
    NSTextField *progressText = nil;
    
	if (mainWindowController) {
        progressIndicator = [mainWindowController progressIndicator];
        progressText = [mainWindowController progressText];
    }

	// Loop through inPeaks(=combined spectra) and determine score
    chromatogramCount = [someChromatograms count];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:chromatogramCount*1.0];
    
    for (l = 0; l < chromatogramCount; l++) {  
        chromatogramToSearch = [someChromatograms objectAtIndex:l];
        [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Searching for Chromatogram '%@'",@""),[chromatogramToSearch model]] waitUntilDone:NO];

        peaksCount = [[chromatogramToSearch peaks] count];
        for (k = 0; k < peaksCount; k++) {
            peak = [[chromatogramToSearch peaks] objectAtIndex:k];
            
            abortAction = ![self performForwardSearchLibraryForPeak:peak error:error];
            
            [progressIndicator incrementBy:(k*1.0/peaksCount)/chromatogramCount];
            
            if(abortAction){
                PKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
                _isBusy = NO;
                break;
            } 
        }
      
        [progressIndicator setDoubleValue:1.0*chromatogramCount];
    }
 	
	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];
	
    _isBusy = NO;
	return YES;
}

- (BOOL)performForwardSearchLibraryForPeak:(PKPeakRecord *)aPeak error:(NSError **)error {
//    _isBusy = YES;
	NSArray *libraryEntries = nil;
    PKManagedLibraryEntry *libraryEntry = nil;
//	int entriesCount;
	float score;	
    float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];

	[self setAbortAction:NO];
    NSProgressIndicator *progressIndicator = nil;
    NSTextField *progressText = nil;
    
	if (mainWindowController) {
        progressIndicator = [mainWindowController progressIndicator];
        progressText = [mainWindowController progressText];
    }
    [progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
    	
	// Get library entries
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Fetching Library Entries",@"") waitUntilDone:NO];

    PKLibrary *aLibrary = [[NSApp delegate] libraryForConfiguration:[self libraryConfiguration]];
    libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:aPeak]];

    if (!libraryEntries) {
        // Error 303
        // No Library Entries
        NSString *errorString = NSLocalizedString(@"No Library Entries", @"error 303: No Library Entries");
        NSString *recoverySuggestionString = NSLocalizedString(@"Ensure that the used library configuration and template will yield library entries.", @"error 303: No Library Entries recovery suggestion");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:303
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;
        return NO;
    }
 
    // Get Spectra Matching Object from Plugin
    NSObject <PKSpectraMatchingMethodProtocol> *spectraMatchingObject = [self objectForSpectraMatching:error];
    if (!spectraMatchingObject) {
        return NO;
    }
    // Restore method settings
    [spectraMatchingObject setSettings:[self spectraMatchingSettingsForMethod:spectraMatchingMethod]];
    [spectraMatchingObject prepareForAction];

    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Comparing Library Entries",@"") waitUntilDone:NO];
	PKSpectrum *peakSpectrum = nil;
    if (spectrumToUse == PKSpectrumSearchSpectrum) {
        peakSpectrum = [aPeak spectrum];
    } else if (spectrumToUse == JKCombinedSpectrumSearchSpectrum) {
        peakSpectrum = [aPeak combinedSpectrum];
    } else {
        PKLogError(@"spectrumToUse has unexpected value.");
    }
    [progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:[libraryEntries count]*1.0];

    int i, batchSize, count = [libraryEntries count];

    // Preparation for a batch fetch request
    NSManagedObjectContext *moc = [aLibrary managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"JKManagedLibraryEntry" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    [request setReturnsObjectsAsFaults:NO];
//    [request setRelationshipKeyPathsForPrefetching:[NSArray arrayWithObject:@"datapoints"]];
    
    NSAutoreleasePool *loopPool;
    NSArray *unfaultedEntries;
    NSMutableArray *searchResults = [NSMutableArray array];
    loopPool = [[NSAutoreleasePool alloc] init];
    // Loop over the library entries
    for (i = 0; i < count; i++) {
        
        if (i % kBatchSize == 0) {
           
            
            batchSize = kBatchSize;
            if (count - (i+batchSize) < 0) {
                batchSize = count-i;
            }
            
            // Batch fault next 1000 (kBatchSize) (or what remains)
            unfaultedEntries = [libraryEntries subarrayWithRange:NSMakeRange(i, batchSize)];
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self IN %@", unfaultedEntries];
            [request setPredicate:predicate];
            
            unfaultedEntries = [moc executeFetchRequest:request error:error];
        }
        
        libraryEntry = [libraryEntries objectAtIndex:i];
 
        score = [spectraMatchingObject matchingScoreForSpectrum:peakSpectrum comparedToLibraryEntry:libraryEntry error:nil]; 
                    
        if (score >= minimumScoreSearchResultsF) {
            PKSearchResult *searchResult = [[PKSearchResult alloc] init];
            [searchResult setScore:[NSNumber numberWithFloat:score]];
            [searchResult setLibraryHit:libraryEntry];
            [searchResult setPeak:aPeak];
//            [searchResult setType:spectrumToUse];
            [aPeak addSearchResult:searchResult];
            [searchResults addObject:libraryEntry];
            [searchResult release];
        }

        if (i % batchSize == batchSize-1) {
            //PKLogDebug(@"i %d; faulting", i);

            // This makes faults out of the entries we don't need anymore
            // We need to do this to clear up some memory
            for (PKManagedLibraryEntry *entry in unfaultedEntries) {
                if (![searchResults containsObject:entry]) {
                    // Oddly, it seems like our datapoints stick around unfaulted when faulting the lib entry, so we do it "by hand"
                    for (NSManagedObject *datapoint in entry.datapoints) {
                         [moc refreshObject:datapoint mergeChanges:NO];
                    }
                    [moc refreshObject:entry mergeChanges:NO];                    
                }
            }
            
            [loopPool drain];
            [progressIndicator setDoubleValue:1.0*i];
            
            if(abortAction) { 
                // Restore default library (otherwise dragging from libpanel doesn't work)
               // [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultConfiguration"]];
                
                // Error 400
                // Spectra Matching Method could not be loaded
                NSString *errorString = NSLocalizedString(@"User Aborted Action", @"error 400: User aborted action");
                NSString *recoverySuggestionString = NSLocalizedString(@"You clicked the 'Stop' button to abort the running operation.", @"error 400: User aborted action recovery suggestion");
                NSDictionary *userInfoDict =
                [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
                NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                               code:400
                                                           userInfo:userInfoDict] autorelease];
                *error = anError;
                return NO;
            }

        }
    }
    [loopPool release];
    // Notify the Spectra Matching Object that we are done
    [spectraMatchingObject cleanUpAfterAction];
    
    // Restore default library (otherwise dragging from libpanel doesn't work)
//    [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:@""];
//    [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultConfiguration"]];
//    _isBusy = NO;
	return YES;
}

- (BOOL)performBackwardSearchAndReturnError:(NSError **)error{
    NSProgressIndicator *progressIndicator = nil;
    NSTextField *progressText = nil;
    
	if (mainWindowController) {
        progressIndicator = [mainWindowController progressIndicator];
        progressText = [mainWindowController progressText];
    }
    
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
    	
    PKLibrary *aLibrary = [[NSApp delegate] libraryForConfiguration:[self libraryConfiguration]];
    BOOL requiresObject = [aLibrary requiresObjectForPredicateForSearchTemplate:[self searchTemplate]];
    if (requiresObject) {
        // Error 304
        // Backward Search not possible
        NSString *errorString = NSLocalizedString(@"Backward Search not possible", @"error 304: Backward Search not possible");
        NSString *recoverySuggestionString = NSLocalizedString(@"Backward search is not possible with search template depending on peak.", @"error 304: Backward Search not possible recovery suggestion");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:304
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;
        return NO;
    }
    
    NSArray *libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:nil]];
    if (!libraryEntries) {
        // Error 303
        // No Library Entries
        NSString *errorString = NSLocalizedString(@"No Library Entries", @"error 303: No Library Entries");
        NSString *recoverySuggestionString = NSLocalizedString(@"Ensure that the used library configuration and template will yield library entries.", @"error 303: No Library Entries recovery suggestion");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:303
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;
        return NO;
    }
    
    return [self performBackwardSearchWithLibraryEntries:libraryEntries maximumRetentionIndexDifference:[[self maximumRetentionIndexDifference] floatValue] error:error];
    
}
- (BOOL)performBackwardSearchWithLibraryEntries:(NSArray *)libraryEntries maximumRetentionIndexDifference:(float)aMaximumRetentionIndexDifference  error:(NSError **)error {
    _isBusy = YES;
    PKManagedLibraryEntry *libraryEntry = nil;
    PKChromatogram *chromatogramToSearch = nil;
    
	int j,k,l;
	int entriesCount, chromatogramCount, peaksCount;
	int maximumIndex;
	float score, maximumScore;	
    NSString *libraryEntryModel = @"";

	[self setAbortAction:NO];
    NSProgressIndicator *progressIndicator = nil;
    NSTextField *progressText = nil;
    
	if (mainWindowController) {
        progressIndicator = [mainWindowController progressIndicator];
        progressText = [mainWindowController progressText];
        [[mainWindowController chromatogramsController] setSelectedObjects:nil];
        [mainWindowController setupChromatogramDataSeries];
    }
    
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
    	
    NSMutableArray *searchChromatograms = [[self chromatograms] mutableCopy];
    NSMutableArray *newChromatograms = [NSMutableArray array];
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	// Loop through inPeaks(=combined spectra) and determine score
	entriesCount = [libraryEntries count];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:entriesCount*1.0];
 //   PKLogDebug(@"entriesCount %d peaksCount %d",entriesCount, peaksCount);

    // Get Spectra Matching Object from Plugin
    NSObject <PKSpectraMatchingMethodProtocol> *spectraMatchingObject = [self objectForSpectraMatching:nil];
    // Restore method settings
 //   [spectraMatchingObject setSettings:[self spectraMatchingSettingsForMethod:spectraMatchingMethod]];
    [spectraMatchingObject prepareForAction];

    [self willChangeValueForKey:@"peaks"];
	
    for (j = 0; j < entriesCount; j++) {
		maximumScore = 0.0f;
		maximumIndex = -1;
        libraryEntry = [libraryEntries objectAtIndex:j]; // can also be a spectrum!!
        if ([libraryEntry isKindOfClass:[PKManagedLibraryEntry class]]) {
            [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];            
            [libraryEntry willAccessValueForKey:nil];
            libraryEntryModel = [[libraryEntry model] cleanupModelString];
        } else {
            [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Spectrum  '%@'",@""),[libraryEntry model]] waitUntilDone:NO];                        
            libraryEntryModel = [libraryEntry model];
        }
        // Search through TIC by default
        chromatogramToSearch = nil;
        if (libraryEntryModel) {
            chromatogramCount = [searchChromatograms count];
            for (l = 0; l < chromatogramCount; l++) {
                if ([libraryEntryModel isEqualToString:[[searchChromatograms objectAtIndex:l] model]]) {
                    chromatogramToSearch = [searchChromatograms objectAtIndex:l];
                }
            }
            if (!chromatogramToSearch) {
                // Add chromatogram
                [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Fetching Chromatogram for Model '%@'",@""),libraryEntryModel] waitUntilDone:NO];
                //PKLogWarning(@"Adding chromatogram for model '%@'.", libraryEntryModel); 
                chromatogramToSearch = [self chromatogramForModel:libraryEntryModel];
                if (!chromatogramToSearch) {
                    PKLogWarning(@"Chromatogram with model '%@' could not be obtained.", libraryEntryModel); 
                    continue;
                }
                if (![searchChromatograms containsObject:chromatogramToSearch]) {                    
                    [searchChromatograms addObject:chromatogramToSearch];
                }
                if (![newChromatograms containsObject:chromatogramToSearch]) {                    
                    [newChromatograms addObject:chromatogramToSearch];
                }
             }
        } else {
            if ([searchChromatograms containsObject:[[self chromatograms] objectAtIndex:0]]) {
                if ([libraryEntry isKindOfClass:[PKLibraryEntry class]]) {
                    PKLogWarning(@"Using TIC chromatogram for library entry '%@'.", [libraryEntry name]); 
                }
                chromatogramToSearch = [[self chromatograms] objectAtIndex:0];
            } else {
                continue;
            }
        }
        if ([chromatogramToSearch countOfBaselinePoints] == 0) {              
            [newChromatograms addObject:chromatogramToSearch];
            if (![chromatogramToSearch detectBaselineAndReturnError:error]){
                return NO;
            }                         
        }

        if (![chromatogramToSearch detectPeaksAndReturnError:error]) {
            return NO;
        }                         
        if ([[chromatogramToSearch peaks] count] == 0) {
            PKLogError(@"No peaks found for chromatogram with model '%@'. bls: %d", [chromatogramToSearch model],[chromatogramToSearch countOfBaselinePoints]);                        
        }
        if ([libraryEntry isKindOfClass:[PKLibraryEntry class]]) {
            [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];
        }
        peaksCount = [[chromatogramToSearch peaks] count];
        
        [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Comparing Peaks against Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];            

		for (k = 0; k < peaksCount; k++) {
 //           if (fabsf([[[[chromatogramToSearch peaks] objectAtIndex:k] retentionIndex] floatValue] - [[libraryEntry retentionIndex] floatValue]) < aMaximumRetentionIndexDifference) {
                score = [spectraMatchingObject matchingScoreForSpectrum:[[[chromatogramToSearch peaks] objectAtIndex:k] spectrum] comparedToLibraryEntry:libraryEntry error:error];

                if (score >= maximumScore) {
                    maximumScore = score;
                    maximumIndex = k;
                }                
//            }
		}
        
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if ((maximumScore >= minimumScoreSearchResultsF) && (maximumIndex > -1)) {
            PKLogDebug(@"Found match for %@",[libraryEntry name]);
			PKSearchResult *searchResult = [[PKSearchResult alloc] init];
			[searchResult setScore:[NSNumber numberWithFloat:maximumScore]];
            [searchResult setLibraryHit:libraryEntry];
            [searchResult setPeak:[[chromatogramToSearch peaks] objectAtIndex:maximumIndex]];
//            [searchResult setType:PKSpectrumSearchSpectrum];
			[[[chromatogramToSearch peaks] objectAtIndex:maximumIndex] addSearchResult:searchResult];
			[searchResult release];
		} 
        
		if(abortAction){
			PKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
            _isBusy = NO;
            // Error 400
            // Spectra Matching Method could not be loaded
            NSString *errorString = NSLocalizedString(@"User Aborted Action", @"error 400: User aborted action");
            NSString *recoverySuggestionString = NSLocalizedString(@"You clicked the 'Stop' button to abort the running operation.", @"error 400: User aborted action recovery suggestion");
            NSDictionary *userInfoDict =
            [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
            NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                           code:400
                                                       userInfo:userInfoDict] autorelease];
            *error = anError;
            
			return NO;
		}
        [progressIndicator incrementBy:1.0];
	}
    
    // Notify the Spectra Matching Object that we are done
    [spectraMatchingObject cleanUpAfterAction];

    // remove peaks that have no search results
	[progressIndicator setIndeterminate:YES];
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Cleaning Up",@"") waitUntilDone:NO];
	PKChromatogram *chrom;

    NSMutableArray *chromsToInsert = [NSMutableArray array];
	for (chrom in newChromatograms) {
        NSMutableIndexSet *peaksToRemove = [NSMutableIndexSet indexSet];
		for (PKPeakRecord *peak in [chrom peaks]) {
			if (([peak countOfSearchResults] == 0) && ([peak identified] == NO) && ([peak confirmed] == NO)) {
                [peaksToRemove addIndex:[[chrom peaks] indexOfObject:peak]];
            }
		}    
        
        // Only change the array after we've iterated over it
        [[chrom peaks] removeObjectsAtIndexes:peaksToRemove];
                
        if ((![[self chromatograms] containsObject:chrom]) && ([[chrom peaks] count] > 0)) {
            [chromsToInsert addObject:chrom];
        }            
	}

    // Only change the array after we've iterated over it
    for (chrom in chromsToInsert) {
        [self insertObject:chrom inChromatogramsAtIndex:[self countOfChromatograms]];
    }
    
    // Sort chromatograms
    [chromatograms sortUsingSelector:@selector(sortOrderComparedTo:)];
    
    [self renumberPeaks];
    [self didChangeValueForKey:@"peaks"];
    [[self undoManager] setActionName:NSLocalizedString(@"Perform Backward Library Search",@"")];

	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];

    // Restore default library (otherwise dragging from libpanel doesn't work)
    [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultConfiguration"]];
    
    if (mainWindowController)
        [[mainWindowController chromatogramsController] setSelectedObjects:[NSArray arrayWithObject:[self ticChromatogram]]];

    _isBusy = NO;
	return YES;
}

- (void)resetToDefaultValues{
	id defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
	
	[self setBaselineWindowWidth:[defaultValues valueForKey:@"baselineWindowWidth"]];
	[self setBaselineDistanceThreshold:[defaultValues valueForKey:@"baselineDistanceThreshold"]];
	[self setBaselineSlopeThreshold:[defaultValues valueForKey:@"baselineSlopeThreshold"]];
	[self setBaselineDensityThreshold:[defaultValues valueForKey:@"baselineDensityThreshold"]];
	[self setPeakIdentificationThreshold:[defaultValues valueForKey:@"peakIdentificationThreshold"]];
	[self setRetentionIndexSlope:[defaultValues valueForKey:@"retentionIndexSlope"]];
	[self setRetentionIndexRemainder:[defaultValues valueForKey:@"retentionIndexRemainder"]];
	[self setScoreBasis:[[defaultValues valueForKey:@"scoreBasis"] intValue]];
	[self setSearchDirection:[[defaultValues valueForKey:@"searchDirection"] intValue]];
	[self setSpectrumToUse:[[defaultValues valueForKey:@"spectrumToUse"] intValue]];
	[self setPenalizeForRetentionIndex:[[defaultValues valueForKey:@"penalizeForRetentionIndex"] boolValue]];
	[self setMarkAsIdentifiedThreshold:[defaultValues valueForKey:@"markAsIdentifiedThreshold"]];
	[self setMinimumScoreSearchResults:[defaultValues valueForKey:@"minimumScoreSearchResults"]];
	[self setMinimumScannedMassRange:[defaultValues valueForKey:@"minimumScannedMassRange"]];
	[self setMaximumScannedMassRange:[defaultValues valueForKey:@"maximumScannedMassRange"]];
	
	[[self undoManager] setActionName:NSLocalizedString(@"Reset to Default Values",@"Reset to Default Values")];
}

- (void)renumberPeaks 
{
    NSArray *renumberedPeaks = [[self peaks] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"retentionIndex" ascending:YES] autorelease]]];
	int i;
	int peakCount = [renumberedPeaks count];

	for (i = 0; i < peakCount; i++) {	
		id peak = [renumberedPeaks objectAtIndex:i];
        // The real thing
		[peak setValue:[NSNumber numberWithInt:i+1] forKey:@"peakID"];
	}	

	[[self undoManager] setActionName:NSLocalizedString(@"Renumber Peaks",@"")];
}

- (void)removeUnidentifiedPeaks {
    for (PKChromatogram *chromatogram in [self chromatograms]) {
    	[chromatogram removeUnidentifiedPeaks];
    }
    [[self undoManager] setActionName:NSLocalizedString(@"Remove Unidentified Peaks",@"")];
}


- (BOOL)isBusy {
    return _isBusy;
}
#pragma mark -
#pragma mark Doublures management
- (BOOL)hasPeakConfirmedAs:(PKLibraryEntry *)libraryHit notBeing:(PKPeakRecord *)originatingPeak 
{
	for (PKPeakRecord *peak in [self peaks]) {
        if ([peak confirmed]) {
            if (peak != originatingPeak) {
                if ([peak libraryHit]) {
                    if ([[[peak libraryHit] jcampString] isEqualToString:[libraryHit jcampString]]) {
                        return YES;
                    }
                }                
            }
        }
    }
    return NO;
}
- (BOOL)hasPeakAtTopScan:(int)topScan notBeing:(PKPeakRecord *)originatingPeak
{
	for (PKPeakRecord *peak in [self peaks]) {
        if (peak != originatingPeak) {
            if ([peak top] == topScan) {
                return YES;
            }                
        }
    }
    return NO;
}
- (void)unconfirmPeaksConfirmedAs:(PKLibraryEntry *)libraryHit notBeing:(PKPeakRecord *)originatingPeak
{
	for (PKPeakRecord *peak in [self peaks]) {
        if ([peak confirmed]|[peak identified]) {
            if (peak != originatingPeak) {
                if ([peak libraryHit]) {
                    if ([[[peak libraryHit] jcampString] isEqualToString:[libraryHit jcampString]]) {
                        [peak discard];
                        //[[peak chromatogram] removeObjectFromPeaksAtIndex:[[[peak chromatogram] peaks] indexOfObject:peak]];
                   }
                }                
            }
        }
    }    
}
- (void)removePeaksAtTopScan:(int)topScan notBeing:(PKPeakRecord *)originatingPeak
{
    for (PKChromatogram *chromatogram in [self chromatograms]) {
        int index;
        
        for (PKPeakRecord *peak in [chromatogram peaks]) {
            if (peak != originatingPeak) {
                if ([peak top] == topScan) {
                    index = [[chromatogram peaks] indexOfObject:peak];
                    [chromatogram removeObjectFromPeaksAtIndex:index];
                }                
            }
        }    
    }
}
#pragma mark -

#pragma mark Notifications
- (void)postNotification:(NSString *)notificationName
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName:notificationName object:self];
}

- (void)windowDidBecomeMain:(NSNotification *)notification
{
    [self postNotification:JKGCMSDocument_DocumentActivateNotification];
}

- (void) windowDidResignMain: (NSNotification *) notification
{
    [self postNotification:JKGCMSDocument_DocumentDeactivateNotification];
}

- (void) windowWillClose: (NSNotification *) notification
{
    [self postNotification:JKGCMSDocument_DocumentDeactivateNotification];
}
#pragma mark -

#pragma mark Actions (OBSOLETE)
- (void)redistributedSearchResults:(PKPeakRecord *)originatingPeak {
    PKLogWarning(@"DEPRECATED METHOD IS USED");
	int k;
	int peaksCount;
	int maximumIndex;
	float score, maximumScore;	
	peaksCount = [[self peaks] count];
	
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	for (PKSearchResult *searchResult in [originatingPeak searchResults]) {
		maximumScore = 0.0;
		maximumIndex = -1;
		for (k = 0; k < peaksCount; k++) {
			if (([[self peaks] objectAtIndex:k] != originatingPeak) && (![[[self peaks] objectAtIndex:k] confirmed])) {
				score = [[[[self peaks] objectAtIndex:k] spectrum] scoreComparedTo:[searchResult libraryHit]];
				if (score >= maximumScore) {
					maximumScore = score;
					maximumIndex = k;
				}				
			}
		}
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if ((maximumScore >= minimumScoreSearchResultsF) & (maximumIndex > -1)) {
            [searchResult setScore:[NSNumber numberWithFloat:maximumScore]];
			[[[self peaks] objectAtIndex:maximumIndex] addSearchResult:searchResult];
		}
		
	}
}
#pragma mark -

#pragma mark Helper Actions
//- (void)updateLibraryHits {
//    BOOL flaggedPeak =  NO;
//    BOOL peakConfirmed =  NO;
//
//    JKLibraryEntry *anEntry = nil;
//
//    for (PKPeakRecord *peak in [self peaks]) {
//    	if ([peak confirmed] || [peak identified]) {
//            peakConfirmed = [peak confirmed];
//            // Check if libraryHit present
//            if (![peak libraryHit]) {
//                // If not, try to find libraryHit for peak label
//                anEntry = [[NSApp delegate] libraryEntryForName:[peak label]];
//                // Assign if found
//                if (anEntry) {
//                    [peak identifyAsLibraryEntry:anEntry];
//                }
//            } else {
//                // Check if peak label is equal to libraryHit name
//                if (![[peak libraryHit] isCompound:[peak label]]) {
//                    // If not, flag peak
//                    [peak setFlagged:YES];
//                    flaggedPeak = YES;
//                } else {
//                    anEntry = [[NSApp delegate] libraryEntryForName:[peak label]];
//                    // Assign if found
//                    if (anEntry) {
//                        [peak identifyAsLibraryEntry:anEntry];
//                    }                    
//                }
//            }            
//            if (peakConfirmed) {
//                [peak confirm];
//            }
//        } else {
//              for (JKSearchResult *searchResult in [peak searchResults]) {
//                 anEntry = [[NSApp delegate] libraryEntryForName:[[searchResult libraryHit] name]];
//                 // Assign if found
//                 if (anEntry) {
//                     [searchResult setLibraryHit:anEntry];
//                 }
//             }
//        }
//
//    }
//    if (flaggedPeak) {
//        NSRunAlertPanel(NSLocalizedString(@"Manual Check Required", @""), NSLocalizedString(@"One or more peaks were encountered with differing labels for the peak and the library entry. These peaks have been flagged. Please check manually which identification you expected.", @""), NSLocalizedString(@"OK", @""), nil, nil);
//    }
//    if (![[self undoManager] isUndoing]) {
//        [[self undoManager] setActionName:NSLocalizedString(@"Update Library Hits",@"Update Library Hits")];
//    }        
//    
//}

- (void)resetSymbols {
    for (PKPeakRecord *peak in [self peaks]) {
    	[peak setSymbol:@""];
    }
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

- (int)nextPeakID {
    _lastReturnedIndex++;
    return _lastReturnedIndex;
}

- (float)confirmedPeaksSurface {
    float totalPeakSurface = 0.0f;
    
    for (PKPeakRecord *peak in [self peaks]) {
    	if ([peak confirmed]) {
            totalPeakSurface += [[peak surface] floatValue];
        }
    }
    
    return totalPeakSurface;
}
#pragma mark -

#pragma mark Key Value Observing
- (void)changeKeyPath:(NSString *)keyPath 
             ofObject:(id)object 
              toValue:(id)newValue
{
	[object setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath 
                      ofObject:(id)object 
                        change:(NSDictionary *)change 
                       context:(void *)context
{
	NSUndoManager *undo = [self undoManager];
	id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	[[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:object toValue:oldValue];
	
	[undo setActionName:@"Edit"];
}
#pragma mark -

#pragma mark InfoTable Datasource Protocol
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    int dummy, count;
    dummy =  nc_inq_natts([self ncid], &count);
    if (dummy == NC_NOERR) return count + 2;//[[self metadata] count];
    return 2;//[[self metadata] count];			
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    int dummy;
    NSMutableString *nameString, *keyString;
    // [[self metadata] count] replaced with 2
    if (row < 2) {
        if ([[self metadata] count] < 2) {
            [[self metadata] setObject:@"" forKey:@"sampleCode"];
            [[self metadata] setObject:@"" forKey:@"sampleDescription"];
        }
        nameString = [[[[[self metadata] allKeys] objectAtIndex:row] mutableCopy] autorelease];
        keyString = [[[[self metadata] valueForKey:nameString] mutableCopy] autorelease];

    } else {
        row = row - 2;

        char name[256];
        char value[256];
        
        dummy =  nc_inq_attname ([self ncid],NC_GLOBAL, row, (void *) &name);
        dummy =  nc_get_att_text([self ncid],NC_GLOBAL, name, (void *) &value);
        
        nameString = [NSMutableString stringWithCString:name];
        keyString = [NSMutableString stringWithCString:value];
    }
    
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        // We need to replace "_" with " "
        dummy = [nameString replaceOccurrencesOfString:@"_" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [nameString length])];
        
        return [nameString capitalizedString];
    } else if ([[tableColumn identifier] isEqualToString:@"value"]) {
        /*
         NSCalendarDate *date;
         if ([nameString rangeOfString:@"time_stamp"].location > 0) {
             PKLogDebug(@"date");
             date = [NSCalendarDate dateWithString:keyString calendarFormat:@"%Y%m%d%H%M%S%z"];
             keyString = "2323";
             return keyString;
         }
         */
        return keyString;
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Exception raised in PKPanelController -tableView:objectValueForTableColumn:row: - tableColumn identifier not known"];
        return nil;
    }        
}
- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"name"]) {
        return;
    } else if ([[aTableColumn identifier] isEqualToString:@"value"]) {
        if (rowIndex < 2) {
            NSString *nameString = [[[self metadata] allKeys] objectAtIndex:rowIndex];
            [[self metadata] setValue:anObject forKey:nameString];
        }
        return;
    } else {
        [NSException raise:NSInvalidArgumentException format:@"Exception raised in PKPanelController -tableView:setObjectValue:forTableColumn:row: - tableColumn identifier not known"];
        return;
    }
}
#pragma mark -

#pragma mark Accessors 
#pragma mark (macrostyle)
idUndoAccessor(baselineWindowWidth, setBaselineWindowWidth, @"Change Baseline Window Width")
idUndoAccessor(baselineDistanceThreshold, setBaselineDistanceThreshold, @"Change Baseline Distance Threshold")
idUndoAccessor(baselineSlopeThreshold, setBaselineSlopeThreshold, @"Change Baseline Slope Threshold")
idUndoAccessor(baselineDensityThreshold, setBaselineDensityThreshold, @"Change Baseline Density Threshold")
idUndoAccessor(peakIdentificationThreshold, setPeakIdentificationThreshold, @"Change Peak Identification Threshold")
idUndoAccessor(retentionIndexSlope, setRetentionIndexSlope, @"Change Retention Index Slope")
idUndoAccessor(retentionIndexRemainder, setRetentionIndexRemainder, @"Change Retention Index Remainder")
idUndoAccessor(libraryConfiguration, setLibraryConfiguration, @"Change Library Configuration")
idUndoAccessor(searchTemplate, setSearchTemplate, @"Change Search Template")
intUndoAccessor(scoreBasis, setScoreBasis, @"Change Score Basis")
intUndoAccessor(searchDirection, setSearchDirection, @"Change Search Direction")
intUndoAccessor(spectrumToUse, setSpectrumToUse,@"Change Spectrum")
boolUndoAccessor(penalizeForRetentionIndex, setPenalizeForRetentionIndex, @"Change Penalize for Offset Retention Index")
idUndoAccessor(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold, @"Change Identification Score")
idUndoAccessor(minimumScoreSearchResults, setMinimumScoreSearchResults, @"Change Minimum Score")
idUndoAccessor(minimumScannedMassRange, setMinimumScannedMassRange, @"Change Minimum Scanned Mass Range")
idUndoAccessor(maximumScannedMassRange, setMaximumScannedMassRange, @"Change Maximum Scanned Mass Range")
idUndoAccessor(maximumRetentionIndexDifference, setMaximumRetentionIndexDifference, @"Change Maximum Retention Index Difference")


boolAccessor(abortAction, setAbortAction)

#pragma mark (weakly referenced)
- (PKMainWindowController *)mainWindowController 
{
    if (!mainWindowController) {
		mainWindowController = [[PKMainWindowController alloc] init];
//		[self makeWindowControllers];
	}
	return mainWindowController;
}

#pragma mark (parameters)
- (int)ncid
{
    return ncid;
}
- (void)setNcid:(int)inValue
{
    ncid = inValue;
}

- (NSString *)uuid
{
    return uuid;
}

- (BOOL)hasSpectra 
{
    return hasSpectra;
}
- (void)setHasSpectra:(BOOL)inValue 
{
    hasSpectra = inValue;
}

- (NSString *)absolutePathToNetCDF 
{
	return absolutePathToNetCDF;
}
- (void)setAbsolutePathToNetCDF:(NSString *)aAbsolutePathToNetCDF 
{
    if (aAbsolutePathToNetCDF != absolutePathToNetCDF) {
        [absolutePathToNetCDF autorelease];
        absolutePathToNetCDF = [aAbsolutePathToNetCDF copy];
    }
}

#pragma mark (to many relationships)
- (NSMutableDictionary *)metadata {
	return metadata;
}

- (void)setMetadata:(NSMutableDictionary *)inValue {
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setMetadata:)
                                        object:metadata];
    [[self undoManager] setActionName:NSLocalizedString(@"Set Metadata",@"")];

    [inValue retain];
	[metadata autorelease];
	metadata = inValue;    
}

// Mutable To-Many relationship chromatograms
- (NSMutableArray *)chromatograms {
	return chromatograms;
}

- (void)setChromatograms:(NSMutableArray *)inValue {
    for (PKChromatogram *chromatogram in [self chromatograms]) {
    	[chromatogram setContainer:nil];
    }

    [inValue retain];
    [chromatograms release];
    chromatograms = inValue;
    

    for (PKChromatogram *chromatogram in [self chromatograms]) {
    	[chromatogram setContainer:self];
    }
 }

- (int)countOfChromatograms {
    return [[self chromatograms] count];
}

- (PKChromatogram *)objectInChromatogramsAtIndex:(int)index {
    return [[self chromatograms] objectAtIndex:index];
}

- (void)getChromatogram:(PKChromatogram **)someChromatograms range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [chromatograms getObjects:someChromatograms range:inRange];
}

- (void)insertObject:(PKChromatogram *)aChromatogram inChromatogramsAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromChromatogramsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Chromatogram",@"")];
	}
	
	// Add aChromatogram to the array chromatograms
	[chromatograms insertObject:aChromatogram atIndex:index];
    [aChromatogram setContainer:self];
}

- (void)removeObjectFromChromatogramsAtIndex:(int)index{
	PKChromatogram *aChromatogram = [chromatograms objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aChromatogram inChromatogramsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Chromatogram",@"")];
	}
	
	// Remove the peak from the array
	[chromatograms removeObjectAtIndex:index];
    [aChromatogram setContainer:nil];
}

- (void)replaceObjectInChromatogramsAtIndex:(int)index withObject:(PKChromatogram *)aChromatogram{
	PKChromatogram *replacedChromatogram = [chromatograms objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedChromatogram];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Chromatogram",@"")];
	}
	
	// Replace the peak from the array
	[chromatograms replaceObjectAtIndex:index withObject:aChromatogram];
    [replacedChromatogram setContainer:nil];
    [aChromatogram setContainer:self];
}

- (BOOL)validateChromatogram:(PKChromatogram **)aChromatogram error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end chromatograms

// Peaks
// Not stored in JKGCMSDocument, but in their PKChromatogram
// but because we often need all peaks in the document context too
// these method was constructed.
- (NSMutableArray *)peaks{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:256];
    for (PKChromatogram *chromatogram in [self chromatograms]) {
//        if (![[chromatogram model] isEqualToString:@"TIC"])
            [array addObjectsFromArray:[chromatogram peaks]];
    }
    _lastReturnedIndex = [array count];
	return array;
}

- (void)setPeaks:(NSMutableArray *)array {
	if (array == [self peaks])
		return;

	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] setPeaks:[self peaks]];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Set Peaks",@"")];
	}

    for (PKChromatogram *chromatogram in [self chromatograms]) {
        [chromatogram setPeaks:nil];
    }
    
	PKPeakRecord *peak;
	for (peak in array) {
        // Add the peak to the array
        for (PKChromatogram *chromatogram in [self chromatograms]) {
            if (chromatogram == [peak chromatogram]) {
                if (![[chromatogram peaks] containsObject:peak]) {
                    [chromatogram insertObject:peak inPeaksAtIndex:[[chromatogram peaks] count]];
                }
                break;
            }
        }
	}

}

- (void)insertObject:(PKPeakRecord *)peak inPeaksAtIndex:(int)index{	
	// Add the peak to the array
    for (PKChromatogram *chromatogram in [self chromatograms]) {
        if (chromatogram == [peak chromatogram]) {
            // Add the inverse action to the undo stack
            NSUndoManager *undo = [self undoManager];
            [[undo prepareWithInvocationTarget:chromatogram] removeObjectFromPeaksAtIndex:[[chromatogram peaks] count]];
          
            if (![undo isUndoing]) {
                [undo setActionName:NSLocalizedString(@"Insert Peak",@"")];
            }
            
            if (![[chromatogram peaks] containsObject:peak]) {
                [chromatogram insertObject:peak inPeaksAtIndex:[[chromatogram peaks] count]];
            }
            break;
        }
    }
}

- (void)removeObjectFromPeaksAtIndex:(int)index{
	PKPeakRecord *peak = [[self peaks] objectAtIndex:index];
	
	// Remove the peak from the array
    for (PKChromatogram *chromatogram in [self chromatograms]) {
        if ([[chromatogram peaks] containsObject:peak]) {
            // Add the inverse action to the undo stack
            NSUndoManager *undo = [self undoManager];
            [[undo prepareWithInvocationTarget:chromatogram] insertObject:peak inPeaksAtIndex:[[chromatogram peaks] indexOfObject:peak]];
            
            if (![undo isUndoing]) {
                [undo setActionName:NSLocalizedString(@"Delete Peak",@"")];
            }
            
//            [[chromatogram peaks] removeObject:peak];
            [chromatogram removeObjectFromPeaksAtIndex:[[chromatogram peaks] indexOfObject:peak]];
            break;
        }
    }
}

#pragma mark -

#pragma mark Debug
// Great debug snippet!
//- (void)addObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
//    PKLogDebug(@"addObserver:    %@ %@", anObserver, keyPath);
//    [super addObserver:anObserver forKeyPath:keyPath options:options context:context];
//}
//- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
//    PKLogDebug(@"removeObserver: %@ %@", anObserver, keyPath);
//    [super removeObserver:anObserver forKeyPath:keyPath];
//}

@synthesize _documentProxy;
@synthesize _remainingString;
@synthesize _isBusy;
@synthesize peacockFileWrapper;
@synthesize printView;
@synthesize uuid;
@synthesize _lastReturnedIndex;
@end



