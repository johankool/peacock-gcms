//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKGCMSDocument.h"

#import "BDAlias.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKChromatogram.h"
#import "JKDataModelProxy.h"
#import "JKLibrary.h"
#import "JKLibraryEntry.h"
#import "JKMainWindowController.h"
#import "JKPanelController.h"
#import "JKPeakRecord.h"
#import "JKGCMSPrintView.h"
#import "JKSpectrum.h"
#import "jk_statistics.h"
#import "netcdf.h"
#import "JKSearchResult.h"

NSString *const JKGCMSDocument_DocumentDeactivateNotification = @"JKGCMSDocument_DocumentDeactivateNotification";
NSString *const JKGCMSDocument_DocumentActivateNotification   = @"JKGCMSDocument_DocumentActivateNotification";
NSString *const JKGCMSDocument_DocumentLoadedNotification     = @"JKGCMSDocument_DocumentLoadedNotification";
int const JKGCMSDocument_Version = 7;
//static void *DocumentObservationContext = (void *)1100;

@implementation JKGCMSDocument

#pragma mark Initialization & deallocation
- (id)init
{
	self = [super init];
    if (self != nil) {
		metadata = [[NSMutableDictionary alloc] init];
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
		libraryAlias = [[BDAlias aliasWithPath:[defaultValues valueForKey:@"libraryAlias"]] retain];
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
        
        [[self undoManager] disableUndoRegistration];
        _documentProxy = [[NSDictionary alloc] initWithObjectsAndKeys:@"_documentProxy", @"_documentProxy",nil];
        [self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
        [[self printInfo] setOrientation:NSLandscapeOrientation];
        printView = [[JKGCMSPrintView alloc] initWithDocument:self];
        [[self undoManager] enableUndoRegistration];
        _lastReturnedIndex = -1;
	}
    return self;
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
	[libraryAlias release];
    [libraryConfiguration release];
    [searchTemplate release];
	[markAsIdentifiedThreshold release];
	[minimumScoreSearchResults release];
    [maximumRetentionIndexDifference release];
	[printView release];
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
//    JKLogEnteringMethod();
//    [self postNotification:JKGCMSDocument_DocumentLoadedNotification];
    if (!mainWindowController) {
        mainWindowController = [[JKMainWindowController alloc] init];
    }
	[self addWindowController:mainWindowController];
//    JKLogExitingMethod();
}
//- (void)showWindows
//{
//    if (!mainWindowController) {
//        mainWindowController = [[JKMainWindowController alloc] init];
//        [self addWindowController:mainWindowController];
//    }
//    [super showWindows];
//}
#pragma mark -

#pragma mark File Access Management

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType {
	if ([aType isEqualToString:@"Peacock File"]) {
		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setDelegate:self];
		[archiver encodeInt:JKGCMSDocument_Version forKey:@"version"];
 		[archiver encodeObject:[self chromatograms] forKey:@"chromatograms"];
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    BOOL result;
	if ([typeName isEqualToString:@"NetCDF/ANDI File"]) {
        [self setAbsolutePathToNetCDF:[absoluteURL path]];
        result = [self readNetCDFFile:[absoluteURL path] error:outError];
        [[self undoManager] disableUndoRegistration];
        [self insertObject:[self ticChromatogram] inChromatogramsAtIndex:0];
        [[self undoManager] enableUndoRegistration];
        return result;
	} else if ([typeName isEqualToString:@"Peacock File"]) {		
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
        [[self undoManager] disableUndoRegistration];
        
        result = [self readNetCDFFile:[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"] error:outError];
		if (result) {
			peacockFileWrapper = wrapper;
		}
        
        NSData *data = nil;
		NSKeyedUnarchiver *unarchiver = nil;
		data = [[[wrapper fileWrappers] valueForKey:@"peacock-data"] regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
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
#warning [BUG] I am retaining to go by a bug, but this is not right!!
        [self retain];
        [self setMetadata:[unarchiver decodeObjectForKey:@"metadata"]];
        [self setBaselineWindowWidth:[unarchiver decodeObjectForKey:@"baselineWindowWidth"]];
        [self setBaselineDistanceThreshold:[unarchiver decodeObjectForKey:@"baselineDistanceThreshold"]];
        [self setBaselineSlopeThreshold:[unarchiver decodeObjectForKey:@"baselineSlopeThreshold"]];
        [self setBaselineDensityThreshold:[unarchiver decodeObjectForKey:@"baselineDensityThreshold"]];
        [self setPeakIdentificationThreshold:[unarchiver decodeObjectForKey:@"peakIdentificationThreshold"]];
        [self setRetentionIndexSlope:[unarchiver decodeObjectForKey:@"retentionIndexSlope"]];
        [self setRetentionIndexRemainder:[unarchiver decodeObjectForKey:@"retentionIndexRemainder"]];	
        // because we normally expand aliases and open them we need to wrap this back into a BDAlias
        [self setLibraryAlias:[unarchiver decodeObjectForKey:@"libraryAlias"]];//[BDAlias aliasWithPath:[[unarchiver decodeObjectForKey:@"libraryAlias"] fileName]]];
        [self setScoreBasis:[unarchiver decodeIntForKey:@"scoreBasis"]];
        [self setSearchDirection:[unarchiver decodeIntForKey:@"searchDirection"]];
        [self setSpectrumToUse:[unarchiver decodeIntForKey:@"spectrumToUse"]];
        [self setPenalizeForRetentionIndex:[unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"]];
        [self setMarkAsIdentifiedThreshold:[unarchiver decodeObjectForKey:@"markAsIdentifiedThreshold"]];		
        [self setMinimumScoreSearchResults:[unarchiver decodeObjectForKey:@"minimumScoreSearchResults"]];		            
        
		[unarchiver finishDecoding];
		[unarchiver release];
      
//        JKLogExitingMethod();

        [[self undoManager] enableUndoRegistration];
        
        // Ensure the TIC chromatogram is still there
        // This should be saved, so is done after reenabling undo
        JKChromatogram *ticChromatogram = [self ticChromatogram];
        if (![[self chromatograms] containsObject:ticChromatogram]) {
            [self insertObject:ticChromatogram inChromatogramsAtIndex:0];
        }
        
        NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
        JKChromatogram *chromatogram = nil;
        
        while ((chromatogram = [chromEnum nextObject]) != nil) {
            if (![[chromatogram model] isEqualToString:@"TIC"] && [chromatogram countOfPeaks] == 0) {
                [self removeObjectFromChromatogramsAtIndex:[[self chromatograms] indexOfObject:chromatogram]];
            }
        }
        
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
    } else if ([object isKindOfClass:[JKLibrary class]]) {
        return [BDAlias aliasWithPath:[object fileName]];
    }
    return object;
}

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([[object valueForKey:@"_documentProxy"] isEqualToString:@"_documentProxy"]) {
            JKLogDebug(@"retaincount = %d",[self retainCount]);
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
	
	return YES;
	//	NS_HANDLER
	//		NSRunAlertPanel([NSString stringWithFormat:@"Error: %@",[localException name]], @"%@", @"OK", nil, nil, localException);
	//	NS_ENDHANDLER
}	 


- (NSString *)exportTabDelimitedText {
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
	_remainingString = [array objectAtIndex:count-1];
	
	JKLogDebug(@"Found %d entries", [libraryEntries count]);
	[libraryEntries autorelease];
    return libraryEntries;	
}
#pragma mark -

#pragma mark IBActions
- (IBAction)openNext:(id)sender {
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
#pragma mark -

#pragma mark Sorting Documents
// Used by the summary feature
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument {
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
#pragma mark -

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

#pragma mark Model
- (JKChromatogram *)ticChromatogram {
    // Check if such a chromatogram is already available
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram = nil;
    
    while ((chromatogram = [chromEnum nextObject]) != nil) {
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
        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
        
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
	
    chromatogram = [[JKChromatogram alloc] initWithModel:@"TIC"];
    int i;
    for (i=0; i<numberOfPoints; i++) {
        time[i] = time[i]/60.0f;
    }
    [chromatogram setTime:time withCount:numberOfPoints];
    [chromatogram setTotalIntensity:totalIntensity withCount:numberOfPoints];
    
	[chromatogram autorelease];
	return chromatogram;
}

- (JKChromatogram *)chromatogramForModel:(NSString *)model {
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
    JKChromatogram *chromatogram = nil;

    while ((chromatogram = [chromEnum nextObject]) != nil) {
        if ([self modelString:[chromatogram model] isEqualToString:mzValuesString]) {
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
    chromatogram = [[JKChromatogram alloc] initWithModel:mzValuesString];
    [chromatogram setContainer:self];
    [chromatogram setTime:times withCount:num_scan];
    [chromatogram setTotalIntensity:intensities withCount:num_scan];
    
    free(massValues);
	[chromatogram autorelease];	
	return chromatogram;    
}

int intSort(id num1, id num2, void *context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (void)addChromatogramForModel:(NSString *)modelString {
    JKChromatogram *chromatogram = [self chromatogramForModel:modelString];
    if (!chromatogram) {
        return;
    }
    if (![[self chromatograms] containsObject:chromatogram]) {
        [self insertObject:chromatogram inChromatogramsAtIndex:[[self chromatograms] count]];        
    }
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

- (BOOL)performLibrarySearchForChromatograms:(NSArray *)someChromatograms {
    NSAssert([someChromatograms count] > 0, @"No chromatograms were selected to be searched.");

    switch (searchDirection) {
    case JKForwardSearchDirection:
        return [self performForwardSearchForChromatograms:someChromatograms];
        break;
    case JKBackwardSearchDirection:
        return [self performBackwardSearchForChromatograms:someChromatograms];
        break;
    default:
        [NSException raise:@"Search Direction Unknown" format:@"The search direction was not set."];
        break;
    }
    
    return NO;
}

- (BOOL)performForwardSearchForChromatograms:(NSArray *)someChromatograms {
    _isBusy = YES;
	NSArray *libraryEntries = nil;
    JKLibraryEntry *libraryEntry = nil;
    JKPeakRecord *peak = nil;
    JKChromatogram *chromatogramToSearch = nil;
	int j,k,l;
	int entriesCount, chromatogramCount, peaksCount;
	float score;
    float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
    BOOL refetchNeeded = YES;
    
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
    
    JKLibrary *aLibrary = [[NSApp delegate] library];
    refetchNeeded = [aLibrary requiresObjectForPredicateForSearchTemplate:[self searchTemplate]];
    if (!refetchNeeded) {
        NSString *selectedSearchTemplate = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"selectedSearchTemplate"];
        libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:nil]];        
        entriesCount = [libraryEntries count];
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
            if (refetchNeeded) {
                libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:peak]];
                entriesCount = [libraryEntries count];                
            }
            for (j = 0; j < entriesCount; j++) {
                libraryEntry = [libraryEntries objectAtIndex:j];
//                libraryEntryModel = [libraryEntry modelChr];
//                if ([libraryEntryModel isEqualToString:[chromatogramToSearch model]]) {
//                    chromatogramToSearch = [someChromatograms objectAtIndex:l];
//                } else if ([libraryEntryModel isEqualToString:@""] && [[chromatogramToSearch model] isEqualToString:@"TIC"]) {
//                    // Search through TIC by default
//
//                } else {
//                    continue;
//                }
                if (spectrumToUse == JKSpectrumSearchSpectrum) {
                    score = [[peak spectrum] scoreComparedTo:libraryEntry];                    
                } else if (spectrumToUse == JKCombinedSpectrumSearchSpectrum) {
                    score = [[peak combinedSpectrum] scoreComparedTo:libraryEntry];
                } else {
                    JKLogError(@"spectrumToUse has unexpected value.");
                }
                if (score >= minimumScoreSearchResultsF) {
                    JKSearchResult *searchResult = [[JKSearchResult alloc] init];
                    [searchResult setScore:[NSNumber numberWithFloat:score]];
                    [searchResult setLibraryHit:[JKLibraryEntry libraryEntryWithJCAMPString:[[libraryEntries objectAtIndex:j] jcampString]]];
                    [searchResult setPeak:peak];
                    [peak addSearchResult:searchResult];
                    [searchResult release];
                }
            }
            [progressIndicator incrementBy:(k*1.0/peaksCount)/chromatogramCount];

        }
        if(abortAction){
			JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
            _isBusy = NO;
			break;
		}       
        [progressIndicator setDoubleValue:1.0*chromatogramCount];
    }
    
	
	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];
	
    _isBusy = NO;
	return YES;
}

- (BOOL)performForwardSearchLibraryForPeak:(JKPeakRecord *)aPeak
{
//    _isBusy = YES;
	NSArray *libraryEntries = nil;
    JKLibraryEntry *libraryEntry = nil;
	int j;
	int entriesCount;
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

    JKLibrary *aLibrary = [[NSApp delegate] library];
    libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:aPeak]];

    if (!libraryEntries) {
        return NO;
    }
    entriesCount = [libraryEntries count];
	
    [progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:entriesCount*1.0];
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Comparing Library Entries",@"") waitUntilDone:NO];

    for (j = 0; j < entriesCount; j++) {
        libraryEntry = [libraryEntries objectAtIndex:j];
        if (spectrumToUse == JKSpectrumSearchSpectrum) {
            score = [[aPeak spectrum] scoreComparedTo:libraryEntry];                    
        } else if (spectrumToUse == JKCombinedSpectrumSearchSpectrum) {
            score = [[aPeak combinedSpectrum] scoreComparedTo:libraryEntry];
        } else {
            JKLogError(@"spectrumToUse has unexpected value.");
        }
        if (score >= minimumScoreSearchResultsF) {
            JKSearchResult *searchResult = [[JKSearchResult alloc] init];
            [searchResult setScore:[NSNumber numberWithFloat:score]];
            [searchResult setLibraryHit:[JKLibraryEntry libraryEntryWithJCAMPString:[[libraryEntries objectAtIndex:j] jcampString]]];
            [searchResult setPeak:aPeak];
            [aPeak addSearchResult:searchResult];
            [searchResult release];
        }
        [progressIndicator incrementBy:1.0];
    }

//    _isBusy = NO;
	return YES;
}

- (BOOL)performBackwardSearchForChromatograms:(NSArray *)someChromatograms {
 	int answer;
    
    NSProgressIndicator *progressIndicator = nil;
    NSTextField *progressText = nil;
    
	if (mainWindowController) {
        progressIndicator = [mainWindowController progressIndicator];
        progressText = [mainWindowController progressText];
    }
    
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
    	
    JKLibrary *aLibrary = [[NSApp delegate] library];
    BOOL requiresObject = [aLibrary requiresObjectForPredicateForSearchTemplate:[self searchTemplate]];
    if (requiresObject) {
        JKLogWarning(@"Backward search is not possible with search template depending on peak.");
        return NO;
    }
    
    NSArray *libraryEntries = [aLibrary libraryEntriesWithPredicate:[aLibrary predicateForSearchTemplate:[self searchTemplate] andObject:nil]];
    return [self performBackwardSearchForChromatograms:someChromatograms withLibraryEntries:libraryEntries maximumRetentionIndexDifference:[[self maximumRetentionIndexDifference] floatValue]];
    
}
- (BOOL)performBackwardSearchForChromatograms:(NSArray *)someChromatograms withLibraryEntries:(NSArray *)libraryEntries maximumRetentionIndexDifference:(float)aMaximumRetentionIndexDifference {
    _isBusy = YES;
    JKLibraryEntry *libraryEntry = nil;
    JKChromatogram *chromatogramToSearch = nil;
    
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
    }
    
	[progressIndicator setDoubleValue:0.0];
	[progressIndicator setIndeterminate:YES];
	[progressIndicator startAnimation:self];
    	
    NSMutableArray *searchChromatograms = [someChromatograms mutableCopy];
    NSMutableArray *newChromatograms = [NSMutableArray array];
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	// Loop through inPeaks(=combined spectra) and determine score
	entriesCount = [libraryEntries count];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:entriesCount*1.0];
 //   JKLogDebug(@"entriesCount %d peaksCount %d",entriesCount, peaksCount);

    [self willChangeValueForKey:@"peaks"];
	
    for (j = 0; j < entriesCount; j++) {
		maximumScore = 0.0f;
		maximumIndex = -1;
        libraryEntry = [libraryEntries objectAtIndex:j]; // can also be a spectrum!!
        if ([libraryEntry isKindOfClass:[JKLibraryEntry class]]) {
            [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];            
            libraryEntryModel = [self cleanupModelString:[libraryEntry modelChr]];
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
                //JKLogWarning(@"Adding chromatogram for model '%@'.", libraryEntryModel); 
                chromatogramToSearch = [self chromatogramForModel:libraryEntryModel];
                if (!chromatogramToSearch) {
                    JKLogWarning(@"Chromatogram with model '%@' could not be obtained.", libraryEntryModel); 
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
                if ([libraryEntry isKindOfClass:[JKLibraryEntry class]]) {
                    JKLogWarning(@"Using TIC chromatogram for library entry '%@'.", [libraryEntry name]); 
                }
                chromatogramToSearch = [[self chromatograms] objectAtIndex:0];
            } else {
                continue;
            }
        }
        if ([chromatogramToSearch baselinePointsCount] == 0) {              
            [newChromatograms addObject:chromatogramToSearch];
            [chromatogramToSearch obtainBaseline];                          
        }
        if ([[chromatogramToSearch peaks] count] == 0) {
            [chromatogramToSearch identifyPeaks];                          
        }
        if ([[chromatogramToSearch peaks] count] == 0) {
            JKLogError(@"No peaks found for chromatogram with model '%@'. bls: %d", [chromatogramToSearch model],[chromatogramToSearch baselinePointsCount]);                        
        }
        if ([libraryEntry isKindOfClass:[JKLibraryEntry class]]) {
            [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];
        }
        peaksCount = [[chromatogramToSearch peaks] count];
		for (k = 0; k < peaksCount; k++) {
            if (fabsf([[[[chromatogramToSearch peaks] objectAtIndex:k] retentionIndex] floatValue] - [[libraryEntry retentionIndex] floatValue]) < aMaximumRetentionIndexDifference) {
                score = [[[[chromatogramToSearch peaks] objectAtIndex:k] spectrum] scoreComparedTo:libraryEntry];
                if (score >= maximumScore) {
                    maximumScore = score;
                    maximumIndex = k;
                }                
            }
		}
        
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if ((maximumScore >= minimumScoreSearchResultsF) && (maximumIndex > -1)) {
			JKSearchResult *searchResult = [[JKSearchResult alloc] init];
			[searchResult setScore:[NSNumber numberWithFloat:maximumScore]];
            [searchResult setLibraryHit:[JKLibraryEntry libraryEntryWithJCAMPString:[libraryEntry jcampString]]];
//            [searchResult setLibrary:[self libraryAlias]];
            [searchResult setPeak:[[chromatogramToSearch peaks] objectAtIndex:maximumIndex]];
			[[[chromatogramToSearch peaks] objectAtIndex:maximumIndex] addSearchResult:searchResult];
			[searchResult release];
		} 
        
		if(abortAction){
			JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
            _isBusy = NO;
			return NO;
		}
        [progressIndicator incrementBy:1.0];
	}
    
    // remove peaks that have no search results
	[progressIndicator setIndeterminate:YES];
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Cleaning Up",@"") waitUntilDone:NO];
	NSEnumerator *newEnum = [newChromatograms objectEnumerator];
	JKChromatogram *chrom;

	while ((chrom = [newEnum nextObject]) != nil) {
		NSEnumerator *peakEnum = [[chrom peaks] objectEnumerator];
		JKPeakRecord *peak;

		while ((peak = [peakEnum nextObject]) != nil) {
			if (([peak countOfSearchResults] == 0) && ([peak identified] == NO) && ([peak confirmed] == NO)) {
                [[chrom peaks] removeObject:peak];
            }
		}    

        if ((![[self chromatograms] containsObject:chrom]) && ([[chrom peaks] count] > 0)){
            [self insertObject:chrom inChromatogramsAtIndex:[self countOfChromatograms]];
        }            
        
	}
    [self renumberPeaks];
    [self didChangeValueForKey:@"peaks"];
    [[self undoManager] setActionName:NSLocalizedString(@"Perform Backward Library Search",@"")];

	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];

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
	[self setLibraryAlias:[BDAlias aliasWithPath:[defaultValues valueForKey:@"libraryAlias"]]];
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
    NSArray *renumberedPeaks = [self peaks];
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
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chrom;

    while ((chrom = [chromEnum nextObject]) != nil) {
    	[chrom removeUnidentifiedPeaks];
    }
    [[self undoManager] setActionName:NSLocalizedString(@"Remove Unidentified Peaks",@"")];
}

- (NSString *)cleanupModelString:(NSString *)model {
    int i,j,mzValuesCount;
    if ([model isEqualToString:@""]) {
        return @"";
    }
    if ([model isEqualToString:@"TIC"]) {
        return @"TIC";
    }
    
    NSMutableArray *mzValues = [NSMutableArray array];
    [model stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
    if ([model isEqualToString:@""]) {
        return @"";
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
//    JKLogDebug(@"%@ %@",mzValuesString,[mzValues description]);
    return mzValuesString;
}

- (BOOL)modelString:(NSString *)stringA isEqualToString:(NSString *)stringB
{
    NSString *stringACleaned = [self cleanupModelString:stringA];
    NSString *stringBCleaned = [self cleanupModelString:stringB];
    return [stringACleaned isEqualToString:stringBCleaned];
}

- (BOOL)isBusy {
    return _isBusy;
}
#pragma mark -
#pragma mark Doublures management
- (BOOL)hasPeakConfirmedAs:(JKLibraryEntry *)libraryHit notBeing:(JKPeakRecord *)originatingPeak 
{
    NSEnumerator *peakEnum = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;
    
    while ((peak = [peakEnum nextObject]) != nil) {
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
- (BOOL)hasPeakAtTopScan:(int)topScan notBeing:(JKPeakRecord *)originatingPeak
{
    NSEnumerator *peakEnum = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;
    
    while ((peak = [peakEnum nextObject]) != nil) {
        if (peak != originatingPeak) {
            if ([peak top] == topScan) {
                return YES;
            }                
        }
    }
    return NO;
}
- (void)unconfirmPeaksConfirmedAs:(JKLibraryEntry *)libraryHit notBeing:(JKPeakRecord *)originatingPeak
{
    NSEnumerator *peakEnum = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;
    
    while ((peak = [peakEnum nextObject]) != nil) {
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
- (void)removePeaksAtTopScan:(int)topScan notBeing:(JKPeakRecord *)originatingPeak
{
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;

    while ((chromatogram = [chromEnum nextObject]) != nil) {
        NSEnumerator *peakEnum = [[chromatogram peaks] objectEnumerator];
        JKPeakRecord *peak;
        int index;
        
        while ((peak = [peakEnum nextObject]) != nil) {
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
- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak{
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

- (int)nextPeakID 
{
    NSArray *peaks = [self peaks];
    int i, j, count = [peaks count];
    BOOL found;
    
    for (j=1; j < count+1; j++) {
        found = NO;
        for (i=0; i<count; i++) {
            if ([[peaks objectAtIndex:i] peakID] == j) {
                found = YES;
            }
        }
        if (!found) {
            if (_lastReturnedIndex != j) {
                _lastReturnedIndex = j;
               return j; 
            }

        }
    }
    j = count+1;
    if (_lastReturnedIndex == j) {
        j = _lastReturnedIndex+1;
    }
    _lastReturnedIndex = j;
    return j;
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

#pragma mark Accessors 
#pragma mark (macrostyle)
idUndoAccessor(baselineWindowWidth, setBaselineWindowWidth, @"Change Baseline Window Width")
idUndoAccessor(baselineDistanceThreshold, setBaselineDistanceThreshold, @"Change Baseline Distance Threshold")
idUndoAccessor(baselineSlopeThreshold, setBaselineSlopeThreshold, @"Change Baseline Slope Threshold")
idUndoAccessor(baselineDensityThreshold, setBaselineDensityThreshold, @"Change Baseline Density Threshold")
idUndoAccessor(peakIdentificationThreshold, setPeakIdentificationThreshold, @"Change Peak Identification Threshold")
idUndoAccessor(retentionIndexSlope, setRetentionIndexSlope, @"Change Retention Index Slope")
idUndoAccessor(retentionIndexRemainder, setRetentionIndexRemainder, @"Change Retention Index Remainder")
idUndoAccessor(libraryAlias, setLibraryAlias, @"Change Library")
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
- (JKMainWindowController *)mainWindowController 
{
    if (!mainWindowController) {
		mainWindowController = [[JKMainWindowController alloc] init];
		[self makeWindowControllers];
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
    NSEnumerator *chromEnumerator = [chromatograms objectEnumerator];
    JKChromatogram *chromatogram;
    
    while ((chromatogram = [chromEnumerator nextObject]) != nil) {
    	[chromatogram setContainer:nil];
    }

    [inValue retain];
    [chromatograms release];
    chromatograms = inValue;
    
    chromEnumerator = [chromatograms objectEnumerator];

    while ((chromatogram = [chromEnumerator nextObject]) != nil) {
    	[chromatogram setContainer:self];
    }
}

- (int)countOfChromatograms {
    return [[self chromatograms] count];
}

- (JKChromatogram *)objectInChromatogramsAtIndex:(int)index {
    return [[self chromatograms] objectAtIndex:index];
}

- (void)getChromatogram:(JKChromatogram **)someChromatograms range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [chromatograms getObjects:someChromatograms range:inRange];
}

- (void)insertObject:(JKChromatogram *)aChromatogram inChromatogramsAtIndex:(int)index {
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
	JKChromatogram *aChromatogram = [chromatograms objectAtIndex:index];
	
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

- (void)replaceObjectInChromatogramsAtIndex:(int)index withObject:(JKChromatogram *)aChromatogram{
	JKChromatogram *replacedChromatogram = [chromatograms objectAtIndex:index];
	
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

- (BOOL)validateChromatogram:(JKChromatogram **)aChromatogram error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end chromatograms

// Peaks
// Not stored in JKGCMSDocument, but in their JKChromatogram
// but because we often need all peaks in the document context too
// these method was constructed.
- (NSMutableArray *)peaks{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;

    while ((chromatogram = [chromEnum nextObject]) != nil) {
    	[array addObjectsFromArray:[chromatogram peaks]];
    }
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
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;
    
    while ((chromatogram = [chromEnum nextObject]) != nil) {
        [chromatogram setPeaks:nil];
    }
    
	NSEnumerator *e = [array objectEnumerator];
	JKPeakRecord *peak;
	while ((peak = [e nextObject])) {
        // Add the peak to the array
        chromEnum = [[self chromatograms] objectEnumerator];
         
        while ((chromatogram = [chromEnum nextObject]) != nil) {
            if (chromatogram == [peak chromatogram]) {
                if (![[chromatogram peaks] containsObject:peak]) {
                    [chromatogram insertObject:peak inPeaksAtIndex:[[chromatogram peaks] count]];
                }
                break;
            }
        }
	}

}

- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index{	
	// Add the peak to the array
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;
    
    while ((chromatogram = [chromEnum nextObject]) != nil) {
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
	JKPeakRecord *peak = [[self peaks] objectAtIndex:index];
	
	// Remove the peak from the array
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;
    
    while ((chromatogram = [chromEnum nextObject]) != nil) {
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
//    JKLogDebug(@"addObserver:    %@ %@", anObserver, keyPath);
//    [super addObserver:anObserver forKeyPath:keyPath options:options context:context];
//}
//- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
//    JKLogDebug(@"removeObserver: %@ %@", anObserver, keyPath);
//    [super removeObserver:anObserver forKeyPath:keyPath];
//}

@end



