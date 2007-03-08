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
#import "JKSpectrum.h"
#import "jk_statistics.h"
#import "netcdf.h"
#import "JKSearchResult.h"

NSString *const JKGCMSDocument_DocumentDeactivateNotification = @"JKGCMSDocument_DocumentDeactivateNotification";
NSString *const JKGCMSDocument_DocumentActivateNotification   = @"JKGCMSDocument_DocumentActivateNotification";
NSString *const JKGCMSDocument_DocumentLoadedNotification     = @"JKGCMSDocument_DocumentLoadedNotification";
int const JKGCMSDocument_Version = 6;
static void *DocumentObservationContext = (void *)1100;

@implementation JKGCMSDocument

#pragma mark INITIALIZATION

- (id)init {
	self = [super init];
    if (self != nil) {
        mainWindowController = [[[JKMainWindowController alloc] init] autorelease];
		metadata = [[NSMutableDictionary alloc] init];
		chromatograms = [[NSMutableArray alloc] init];
		
		_remainingString = [NSString stringWithString:@""];
		
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
		searchDirection = [[defaultValues valueForKey:@"searchDirection"] intValue];
		spectrumToUse = [[defaultValues valueForKey:@"spectrumToUse"] intValue];
		penalizeForRetentionIndex = [[defaultValues valueForKey:@"penalizeForRetentionIndex"] boolValue];
		markAsIdentifiedThreshold = [[defaultValues valueForKey:@"markAsIdentifiedThreshold"] retain];
		minimumScoreSearchResults = [[defaultValues valueForKey:@"minimumScoreSearchResults"] retain];
		minimumScannedMassRange = [[defaultValues valueForKey:@"minimumScannedMassRange"] retain];
		maximumScannedMassRange = [[defaultValues valueForKey:@"maximumScannedMassRange"] retain];
        
        peakIDCounter = 0;
        _documentProxy = [[NSDictionary alloc] initWithObjectsAndKeys:@"_documentProxy", @"_documentProxy",nil];
//        [self setPrintInfo:[NSPrintInfo sharedPrintInfo]];
//        JKLogDebug(@"%d", [[NSPrintInfo sharedPrintInfo] orientation]);
//        JKLogDebug(@"%d", [[self printInfo] orientation]);
	}
    return self;
}

- (void)addWindowController:(NSWindowController *)windowController {
    if (windowController == mainWindowController) {
        [self addObserver:mainWindowController forKeyPath:@"metadata.sampleCode" options:nil context:DocumentObservationContext];
        [self addObserver:mainWindowController forKeyPath:@"metadata.sampleDescription" options:nil context:DocumentObservationContext];
    }
    
    [super addWindowController:windowController];
}

- (void)removeWindowController:(NSWindowController *)windowController {
    if (windowController == mainWindowController) {
        [self removeObserver:mainWindowController forKeyPath:@"metadata.sampleCode"];
        [self removeObserver:mainWindowController forKeyPath:@"metadata.sampleDescription"];        
    }
        
    [super removeWindowController:windowController];
}

- (void)dealloc {
    [_documentProxy release];
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
//    JKLogDebug(@"addObserver:    %@ %@", anObserver, keyPath);
//    [super addObserver:anObserver forKeyPath:keyPath options:options context:context];
//}
//- (void)removeObserver:(NSObject *)anObserver forKeyPath:(NSString *)keyPath {
//    JKLogDebug(@"removeObserver: %@ %@", anObserver, keyPath);
//    [super removeObserver:anObserver forKeyPath:keyPath];
//}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers {
	[[NSNotificationCenter defaultCenter] postNotificationName:JKGCMSDocument_DocumentLoadedNotification object:self];
	NSAssert(mainWindowController != nil, @"mainWindowController is nil");
	[self addWindowController:mainWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

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
		[archiver encodeObject:libraryAlias forKey:@"libraryAlias"];
		[archiver encodeInt:scoreBasis forKey:@"scoreBasis"];
		[archiver encodeInt:searchDirection forKey:@"searchDirection"];
		[archiver encodeInt:spectrumToUse forKey:@"spectrumToUse"];
		[archiver encodeInt:peakIDCounter forKey:@"peakIDCounter"];
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
        absolutePathToNetCDF = [absoluteURL path];
        result = [self readNetCDFFile:[absoluteURL path] error:outError];
        [[self undoManager] disableUndoRegistration];
        [self insertObject:[self ticChromatogram] inChromatogramsAtIndex:0];
        [[self undoManager] enableUndoRegistration];
        return result;
	} else if ([typeName isEqualToString:@"Peacock File"]) {		
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];

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
//            if (outError != NULL)
//                *outError = [[[NSError alloc] initWithDomain:@"JKDomain" 
//                                                        code:4 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Obsolete file format", NSLocalizedDescriptionKey, @"Its file format has become obsolete.", NSLocalizedFailureReasonErrorKey, @"The file package still contains the original NetCDF file. Use 'Show Package Contents' in the Finder.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
//            [unarchiver finishDecoding];
//            [unarchiver release];
//            return NO;
//            break;            
        case 1:
        case 2:
        case 3:
        case 4:
            [chromatograms removeAllObjects];
            [chromatograms addObject:[self ticChromatogram]];
//            [[chromatograms objectAtIndex:0] setBaselinePoints:[[unarchiver decodeObjectForKey:@"baseline"] mutableCopy]];
            [[chromatograms objectAtIndex:0] setPeaks:[unarchiver decodeObjectForKey:@"peaks"]];
            break;
        case 5:
            chromatograms = [[unarchiver decodeObjectForKey:@"chromatograms"] retain];
            break;
        case 6:
        default:
            chromatograms = [[unarchiver decodeObjectForKey:@"chromatograms"] retain];
            minimumScannedMassRange = [[unarchiver decodeObjectForKey:@"minimumScannedMassRange"] retain];
            maximumScannedMassRange = [[unarchiver decodeObjectForKey:@"maximumScannedMassRange"] retain];
            peakIDCounter = [unarchiver decodeIntForKey:@"peakIDCounter"];
            break;
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
        searchDirection = [unarchiver decodeIntForKey:@"searchDirection"];
        spectrumToUse = [unarchiver decodeIntForKey:@"spectrumToUse"];
        penalizeForRetentionIndex = [unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"];
        markAsIdentifiedThreshold = [[unarchiver decodeObjectForKey:@"markAsIdentifiedThreshold"] retain];		
        minimumScoreSearchResults = [[unarchiver decodeObjectForKey:@"minimumScoreSearchResults"] retain];		            
        
		[unarchiver finishDecoding];
		[unarchiver release];
		        
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
            return self;
        }
    }
    return object;
}

- (NSString *)autosavingFileType {
    return @"Peacock File";
}

#pragma mark IBACTIONS

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

#pragma mark IMPORT/EXPORT ACTIONS

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
	
	absolutePathToNetCDF = fileName;

	
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

#pragma mark SORTING DOCUMENTS

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

#pragma mark PRINTING
- (BOOL)shouldChangePrintInfo:(NSPrintInfo *)newPrintInfo {
    return NO;
}
- (void)printShowingPrintPanel:(BOOL)showPanels {
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

#pragma mark -
#pragma mark MODEL

- (JKChromatogram *)ticChromatogram {
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
	
    JKChromatogram *chromatogram = [[JKChromatogram alloc] initWithDocument:self forModel:@"TIC"];
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
    mzValues = [mzValues sortedArrayUsingFunction:intSort context:NULL];
    
#warning [BUG] Constructed string expands "-"-series (from-to).
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
    	if ([[chromatogram model] isEqualToString:mzValuesString]) {
            //JKLogDebug(@"found chrom for model %@",mzValuesString);
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
    chromatogram = [[JKChromatogram alloc] initWithDocument:self forModel:mzValuesString];

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
    
    JKSpectrum *spectrum = [[JKSpectrum alloc] initWithDocument:self forModel:[NSString stringWithFormat:@"scan %d",scan-1]];
  
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
	int entriesCount, answer, chromatogramCount;
	float score;	
//    NSString *libraryEntryModel = @"";
    
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
    [progressText setStringValue:NSLocalizedString(@"Opening Library",@"")];
        
	// Determine spectra for peaks
	int peaksCount = [[self peaks] count];
	if (peaksCount == 0) {
		answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Peaks Identified",@""),NSLocalizedString(@"No peaks have yet been identified in the chromatogram. Use the 'Identify Peaks' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
		return NO;
	}
	
	// Read library 
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Reading Library",@"") waitUntilDone:NO];
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
    
	libraryEntries = [aLibrary libraryEntries];
	float minimumScoreSearchResultsF = [minimumScoreSearchResults floatValue];
	// Loop through inPeaks(=combined spectra) and determine score
    chromatogramCount = [someChromatograms count];
	entriesCount = [libraryEntries count];
	[progressIndicator setIndeterminate:NO];
	[progressIndicator setMaxValue:chromatogramCount*1.0];
//    JKLogDebug(@"entriesCount %d peaksCount %d",entriesCount, peaksCount);
    
    for (l = 0; l < chromatogramCount; l++) {  
        chromatogramToSearch = [someChromatograms objectAtIndex:l];
        [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Searching for Chromatogram '%@'",@""),[chromatogramToSearch model]] waitUntilDone:NO];

        peaksCount = [[chromatogramToSearch peaks] count];
        for (k = 0; k < peaksCount; k++) {
            peak = [[chromatogramToSearch peaks] objectAtIndex:k];
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
                    score = [[peak spectrum] scoreComparedToLibraryEntry:libraryEntry];                    
                } else if (spectrumToUse == JKCombinedSpectrumSearchSpectrum) {
                    score = [[peak combinedSpectrum] scoreComparedToLibraryEntry:libraryEntry];
                } else {
                    JKLogError(@"spectrumToUse has unexpected value.");
                }
                if (score >= minimumScoreSearchResultsF) {
                    JKSearchResult *searchResult = [[JKSearchResult alloc] init];
                    [searchResult setScore:[NSNumber numberWithFloat:score]];
                    [searchResult setLibraryHit:[libraryEntries objectAtIndex:j]];
                    [searchResult setLibrary:[self libraryAlias]];
                    [searchResult setPeak:peak];
                    [peak addSearchResult:searchResult];
                    [searchResult release];
                }
            }
            [progressIndicator incrementBy:(k*1.0/peaksCount)/chromatogramCount];

        }
        if(abortAction){
			JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
			break;
		}       
        [progressIndicator incrementBy:chromatogramCount];
    }
    
	
	if (mainWindowController)
		[[mainWindowController chromatogramView] setNeedsDisplay:YES];
	
    _isBusy = NO;
	return YES;
}

- (BOOL)performBackwardSearchForChromatograms:(NSArray *)someChromatograms {
    _isBusy = YES;
	NSArray *libraryEntries = nil;
    JKLibraryEntry *libraryEntry = nil;
    JKChromatogram *chromatogramToSearch = nil;
    
	int j,k,l;
	int entriesCount, answer, chromatogramCount, peaksCount;
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
    
//	// Determine spectra for peaks
//	int peaksCount = [[self peaks] count];
//	if (peaksCount == 0) {
//		answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Peaks Identified",@""),NSLocalizedString(@"No peaks have yet been identified in the chromatogram. Use the 'Identify Peaks' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
//		return NO;
//	}
	
	// Read library
    [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:NSLocalizedString(@"Reading Library",@"") waitUntilDone:NO];

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
    
	libraryEntries = [aLibrary libraryEntries];
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
        libraryEntry = [libraryEntries objectAtIndex:j];
        [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];
        // Search through TIC by default
        chromatogramToSearch = nil;
        libraryEntryModel = [self cleanupModelString:[libraryEntry modelChr]];
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
                JKLogWarning(@"Using TIC chromatogram for library entry '%@'.", [libraryEntry name]); 
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
            [newChromatograms addObject:chromatogramToSearch];
            [chromatogramToSearch identifyPeaks];                          
        }
        [progressText performSelectorOnMainThread:@selector(setStringValue:) withObject:[NSString stringWithFormat:NSLocalizedString(@"Matching Library Entry '%@'",@""),[libraryEntry name]] waitUntilDone:NO];
        peaksCount = [[chromatogramToSearch peaks] count];
		for (k = 0; k < peaksCount; k++) {
			score = [[[[chromatogramToSearch peaks] objectAtIndex:k] spectrum] scoreComparedToLibraryEntry:libraryEntry];
			if (score >= maximumScore) {
				maximumScore = score;
				maximumIndex = k;
			}
		}
        
		// Add libentry as result to highest scoring peak if it is within range of acceptance
		if (maximumScore >= minimumScoreSearchResultsF) {
			JKSearchResult *searchResult = [[JKSearchResult alloc] init];
			[searchResult setScore:[NSNumber numberWithFloat:maximumScore]];
			[searchResult setLibraryHit:[libraryEntries objectAtIndex:j]];
            [searchResult setLibrary:[self libraryAlias]];
            [searchResult setPeak:[[chromatogramToSearch peaks] objectAtIndex:maximumIndex]];
			[[[chromatogramToSearch peaks] objectAtIndex:maximumIndex] addSearchResult:searchResult];
			[searchResult release];
		} 
        
		if(abortAction){
			JKLogInfo(@"Identifying Compounds Search Aborted by User at entry %d/%d peak %d/%d.",j,entriesCount, k, peaksCount);
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

- (void)renumberPeaks {
    NSArray *renumberedPeaks = [self peaks];
	int i;
	int peakCount = [renumberedPeaks count];

	for (i = 0; i < peakCount; i++) {	
		id peak = [renumberedPeaks objectAtIndex:i];
        // The real thing
		[peak setValue:[NSNumber numberWithInt:i+1] forKey:@"peakID"];
	}	

    peakIDCounter = peakCount;
	[[self undoManager] setActionName:NSLocalizedString(@"Renumber Peaks",@"")];
}

- (NSString *)cleanupModelString:(NSString *)model {
    int i,j,mzValuesCount;
    
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
    mzValues = [mzValues sortedArrayUsingFunction:intSort context:NULL];
    
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

- (BOOL)isBusy {
    return _isBusy;
}

#pragma mark NOTIFICATIONS

- (void) postNotification: (NSString *) notificationName{
    NSNotificationCenter *center;
    center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName: notificationName
						  object: self];
	
}


- (void) windowDidBecomeMain: (NSNotification *) notification{
    [self postNotification: 
		JKGCMSDocument_DocumentActivateNotification];
	
}


- (void) windowDidResignMain: (NSNotification *) notification{
    [self postNotification: 
		JKGCMSDocument_DocumentDeactivateNotification];
	
}


- (void) windowWillClose: (NSNotification *) notification{
    [self postNotification: 
		JKGCMSDocument_DocumentDeactivateNotification];
}


#pragma mark OBSOLETE -- OBSOLETE -- OBSOLETE
#pragma mark ACTIONS

//- (ChromatogramGraphDataSerie *)obtainTICChromatogram  
//{
//	int i;
//	
//	ChromatogramGraphDataSerie *chromatogram = [[ChromatogramGraphDataSerie alloc] init];
//    NSMutableArray *mutArray = [[NSMutableArray alloc] init];
//	for (i = 0; i < numberOfPoints; i++) {
//		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:time[i]/60.0f], @"Time",
//			[NSNumber numberWithInt:i], @"Scan", [NSNumber numberWithFloat:[self retentionIndexForScan:i]], @"Retention Index",
//			[NSNumber numberWithFloat:totalIntensity[i]], @"Total Intensity", nil];
//		[mutArray addObject:dict];      
//		[dict release];
//	}
//	[chromatogram setDataArray:mutArray];
//	[mutArray release];
//	
//	[chromatogram setKeyForXValue:@"Time"];
//	[chromatogram setKeyForYValue:@"Total Intensity"];
//	[chromatogram setSeriesTitle:NSLocalizedString(@"TIC Chromatogram",@"")];
//	
//	[chromatogram autorelease];
//	
//	return chromatogram;
//}



//-(void)identifyPeaksOff { //UsingIntensityWeightedVariance {
//    // Identify Peaks using method described in Jarman2003
//    
//    float desiredSignificance = 0.95; // set by user?
//    
//    int windowWidth; // increasing from 11 to 200 increasing by 1.5 times per iteration (that is 8 steps) {11, 17, 26, 39, 59, 89, 134, 200}
//    int stepSize; // = windowWidth/3;
//    int step = 0;
//    float iwv[8][numberOfPoints];
//    
//    int i,j,n,scan,count,countOfValues;
//    float t,a,q,d,mean,variance,sum,sumDenominator,sumDevisor;
//    float *massValues, *intensityValues;
//    massValues = [self massValues];
//    intensityValues = [self intensityValues];
//    
//    
//    // Vary window width [3.4.0]
//    windowWidth = 7; // *1.5 is 11
//    for (step = 0; step < 8; step++) {
//        windowWidth = lroundf(windowWidth *1.5f);
//        stepSize = windowWidth/3;
//
//        // Calculate mean
//        sum = 0.0;
//        for (j = 0; j < windowWidth; j++) {
//            JKLogDebug(@"intensityValues[%d]: %f", j, intensityValues[j]);
//            sum = sum + intensityValues[j];
//        }
//        mean = sum/windowWidth;
//
//        // Calculate variance
//        sum = 0.0;
//        for (j = 0; j < windowWidth; j++) {
//            sum = sum + pow((intensityValues[j]-mean),2);
//        }
//        variance = sqrt(sum/windowWidth);
//
//        
//        // Calculate threshold [3.4.1]
//        // Solving -q/d*n*(1-t)/sqrt(n*((3*(3*n^2-7))/(5*(n^2-1))-2*t+t^2))=a for t results on
//        // http://www.hostsrv.com/webmab/app1/MSP/quickmath/02/pageGenerate?site=mathcom&s1=equations&s2=solve&s3=basic in
//        // t = (-5*pow(q,2)*pow(n,3)+5*pow(a,2)*pow(d,2)*pow(n,2)+5*pow(q,2)*n-5*pow(a,2)*pow(d,2)-2*sqrt(5) * sqrt(pow(a,2)*pow(d,2)*pow(q,2)*pow(n,5)-pow(a,4)*pow(d,4)*pow(n,4)-5*pow(a,2)*pow(d,2)*pow(q,2)*pow(n,3) + 5*pow(a,4)*pow(d,4)*pow(n,2)+4*pow(a,2)*pow(d,2)*pow(q,2)*n-4*pow(a,4)*pow(d,4))) / (5*(-pow(q,2)*pow(n,3)+pow(a,2)*pow(d,2)*pow(n,2)+pow(q,2)*n-pow(a,2)*pow(d,2)));
//        // and in:
//        n = windowWidth;
//        a = desiredSignificance;
//        q = mean;
//        d = variance;
//        JKLogDebug(@"windowWidth: %d | desiredSignificance: %g | mean: %g |d: %g", n,a,q,d);
//        t = (-5*pow(q,2)*pow(n,3)+5*pow(a,2)*pow(d,2)*pow(n,2)+5*pow(q,2)*n-5*pow(a,2)*pow(d,2)+2*sqrt(5) * sqrt(pow(a,2)*pow(d,2)*pow(q,2)*pow(n,5)-pow(a,4)*pow(d,4)*pow(n,4)-5*pow(a,2)*pow(d,2)*pow(q,2)*pow(n,3) + 5*pow(a,4)*pow(d,4)*pow(n,2)+4*pow(a,2)*pow(d,2)*pow(q,2)*n-4*pow(a,4)*pow(d,4))) / (5*(-pow(q,2)*pow(n,3)+pow(a,2)*pow(d,2)*pow(n,2)+pow(q,2)*n-pow(a,2)*pow(d,2)));
//        JKLogDebug(@"threshold: %g",t);
//        
//        // Step through
//        for (scan = 0; scan < numberOfPoints-1; scan = scan+stepSize) {
//            // Calculate iwv [3.4.2]
//            countOfValues = [self countOfValuesForSpectrumAtScan:scan];
//            massValues = [self massValuesForSpectrumAtScan:scan];
//            intensityValues = [self intensityValuesForSpectrumAtScan:scan];
//            // Calculate mean massValues (m/z-values actually)
//            sum = 0.0;
//            for (j = 0; j < countOfValues; j++) {
//                sum = sum + massValues[j];
//            }
//            mean = sum/countOfValues;
//            sumDenominator= 0.0; sumDevisor = 0.0;
//            for (j = 0; j < countOfValues; j++) {
//                sumDenominator = sumDenominator + (intensityValues[j]*pow((massValues[j]-mean),2));
//                sumDevisor = sumDevisor + intensityValues[j];
//            }
//            //JKLogDebug(@"iwv[%d][%d]: %g",step, scan, (sumDenominator/sumDevisor));
//
//            iwv[step][scan] = (sumDenominator/sumDevisor);
//        }
//        
//    }
//    
//    // Find occurences below threshold [3.4.3]
//    for (i = 0; i < numberOfPoints; i++) {
//        count = 0;
//        for (j = 0; j < 7; j++) {
//            if (iwv[j][i] < t) {
//                count++;
//            }
//        }
//        if (count >= 2) {
//            // A peak has been detected at scan i
//           // JKLogDebug(@"peak at scan %d",i);
//        }
//    }
//    
//    // Compile list, remove duplicates [3.4.4]
//}

//- (void)addChromatogramForMass:(NSString *)inString  
//{
//	ChromatogramGraphDataSerie *chromatogram = [[self chromatogramForModel:inString] chromatogramDataSerie];
//	
//	// Get colorlist
//	NSColorList *peakColors;
//	NSArray *peakColorsArray;
//	
//	peakColors = [NSColorList colorListNamed:@"Peacock Series"];
//	if (peakColors == nil) {
//		peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
//	}
//	peakColorsArray = [peakColors allKeys];
//	int peakColorsArrayCount = [peakColorsArray count];
//	
//	[chromatogram setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatograms count]%peakColorsArrayCount]]];
//    [chromatogram setKeyForXValue:[[[self mainWindowController] chromatogramView] keyForXValue]];
//    [chromatogram setKeyForYValue:[[[self mainWindowController] chromatogramView] keyForYValue]];
//
//	[self willChangeValueForKey:@"chromatograms"];
//    [[[JKPanelController sharedController] inspectedGraphView] willChangeValueForKey:@"dataSeries"];
//	[chromatograms addObject:chromatogram];
//	[self didChangeValueForKey:@"chromatograms"];
//    [[[JKPanelController sharedController] inspectedGraphView] didChangeValueForKey:@"dataSeries"];
//}

//- (void)resetRetentionIndexes  
//{
//	int i; 
//	float calculatedRetentionIndex;
//	int peakCount = [peaks count];
//	for (i=0; i < peakCount; i++){
//		calculatedRetentionIndex = [[[peaks objectAtIndex:i] valueForKey:@"topTime"] floatValue] * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
//		[[peaks objectAtIndex:i] setValue:[NSNumber numberWithFloat:calculatedRetentionIndex] forKey:@"retentionIndex"];				
//	}	
//}


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
				score = [[[[self peaks] objectAtIndex:k] spectrum] scoreComparedToLibraryEntry:[searchResult libraryHit]];
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


//- (IBAction)fix:(id)sender {
//    NSRunAlertPanel(@"Fix old file-format",@"Do not switch to another window until done.",@"Fix",nil,nil);
//    NSEnumerator *e = [[self peaks] objectEnumerator];
//    JKPeakRecord *peak;
//    e = [[self peaks] objectEnumerator];
//    while ((peak = [e nextObject])) {
//        [peak updateForNewEncoding];
//    }
//    NSRunAlertPanel(@"Finished Fix",@"Save your file to save it in the new file format.",@"Done",nil,nil);
//    [self saveDocumentAs:self];
//}

#pragma mark HELPER ACTIONS
- (float)timeForScan:(int)scan {
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    NSAssert([[self chromatograms] count] >= 0, @"[[self chromatograms] count] must be equal or larger than zero");
    float *time = [[[self chromatograms] objectAtIndex:0] time];
    return time[scan];    
}

- (int)scanForTime:(float)time {
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
    peakIDCounter++;    
    return peakIDCounter;
}


//- (float *)massValuesForSpectrumAtScan:(int)scan  
//{
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    int dummy, start, end, varid_mass_value, varid_scan_index;
//	//   float 	xx;
//    float 	*x;
//    int		num_pts;
//	
//    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return 0;}
//	
//	
//	dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//	
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//	scan++;
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//	//    start = [self startValuesSpectrum:scan];
//	//    end = [self endValuesSpectrum:scan];
//    num_pts = end - start;
//    
//	//	JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
//	//   x = (float *) malloc((num_pts+1)*sizeof(float));
//	
//	x = (float *) malloc(num_pts*sizeof(float));
//	//	dummy = nc_get_var_float(ncid, varid_mass_value, x);
//	
//	dummy = nc_get_vara_float(ncid, varid_mass_value, (const size_t *) &start, (const size_t *) &num_pts, x);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values failed. Report error #%d.", dummy); return x;}
//	
//	//    for(i = start; i < end; i++) {
//	//        dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &i, &xx);
//	//        *(x + (i-start)) = xx;
//	//        if(maxXValuesSpectrum < xx) {
//	//            maxXValuesSpectrum = xx;
//	//        }
//	//        if(minXValuesSpectrum > xx || i == start) {
//	//            minXValuesSpectrum = xx;
//	//        }
//	
//	//    }
//	
//    return x;    
//}
//
//- (float *)intensityValuesForSpectrumAtScan:(int)scan  
//{
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    int dummy, start, end, varid_intensity_value, varid_scan_index;
//	//   float 	yy;
//    float 	*y;
//    int		num_pts;
//	
//    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
//	
//	dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//	
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//	scan++;
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//	//    start = [self startValuesSpectrum:scan];
//	//    end = [self endValuesSpectrum:scan];
//    num_pts = end - start;
//	
//	y = (float *) malloc((num_pts)*sizeof(float));
//	//	dummy = nc_get_var_float(ncid, varid_intensity_value, y);
//	
//	dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &start, (const size_t *) &num_pts, y);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_values failed. Report error #%d.", dummy); return y;}
//	
//	//	//    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;	
//	//    for(i = start; i < end; i++) {
//	//        dummy = nc_get_var1_float(ncid, varid_intensity_value, (void *) &i, &yy);
//	//        *(y + (i-start)) = yy;
//	//		//        if(maxXValuesSpectrum < yy) {
//	//		//            maxXValuesSpectrum = yy;
//	//		//        }
//	//		//        if(minXValuesSpectrum > yy || i == start) {
//	//		//            minXValuesSpectrum = yy;
//	//		//        }
//	//		
//	//    }
//	
//    return y;
//}

//- (ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString  
//{
//	NSMutableArray *mzValues = [NSMutableArray array];
//	NSArray *mzValuesPlus = [inString componentsSeparatedByString:@"+"];
//	
//	unsigned int i,j,k, mzValuesCount;
//	
//	for (i = 0; i < [mzValuesPlus count]; i++) {
//		NSArray *mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
//		if ([mzValuesMin count] > 1) {
//			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
//				for (j = (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j < (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
//					[mzValues addObject:[NSNumber numberWithInt:j]];
//				}
//			} else {
//				for (j = (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j < (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j++) {
//					[mzValues addObject:[NSNumber numberWithInt:j]];
//				}
//			}
//		} else {
//			[mzValues addObject:[NSNumber numberWithInt:[[mzValuesMin objectAtIndex:0] intValue]]];
//		}
//	}
//	
//	NSString *mzValuesString = [NSString stringWithFormat:@"%d",[[mzValues objectAtIndex:0] intValue]];
//	mzValuesCount = [mzValues count];
//	for (i = 1; i < mzValuesCount; i++) {
//		mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];
//	}
//	// JKLogDebug(mzValuesString);
//	
//	
//    int     dummy, scan, dimid, varid_intensity_value, varid_mass_value, varid_scan_index, varid_point_count, scanCount;
//    float   mass, intensity;
//    float	*times, *masses,	*intensities;
//    unsigned int num_pts, num_scan;
//    
//    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return nil;}
//
////    dummy = nc_inq_varid(ncid, "time_values", &varid_time_value);
////    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting time_values variable failed. Report error #%d. Continuing...", dummy);}
//    
//    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return nil;}
//	
//    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting varid_scan_index variable failed. Report error #%d.", dummy); return nil;}
//	
//    dummy = nc_inq_varid(ncid, "point_count", &varid_point_count);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_count variable failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
//	
//    dummy = nc_inq_dimid(ncid, "scan_number", &dimid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_scan);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return nil;}
//    
//	masses = (float *) malloc((num_scan)*sizeof(float));
//	times = (float *) malloc((num_scan)*sizeof(float));
//	intensities = (float *) malloc((num_scan)*sizeof(float));
//
//	for(i = 0; i < num_scan; i++) {
//        masses[i] = 0.0f;
//        times[i] = 0.0f;
//        intensities[i] = 0.0f;
//		dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &i, &scan); // is this the start or the end?
//		dummy = nc_get_var1_int(ncid, varid_point_count, (void *) &i, &scanCount);
//		for(j = scan; j < (unsigned)scan + (unsigned)scanCount; j++) {
//            mass = 0.0f;
////            timeL = 0.0f;
//            intensity = 0.0f;
//			dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &j, &mass);
//			for(k = 0; k < mzValuesCount; k++) {
//				if (fabs(mass-[[mzValues objectAtIndex:k] intValue]) < 0.5) {
////					dummy = nc_get_var1_float(ncid, varid_time_value, (const size_t *) &j, &timeL);
//					dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &j, &intensity);
//					
//					masses[i] = mass;
//					times[i] = [self timeForScan:i];
//					intensities[i] = intensities[i] + intensity;
//				}
//			}
//		}
//	}
//	ChromatogramGraphDataSerie *chromatogram;
//	
//    //create a chromatogram object
//    chromatogram = [[ChromatogramGraphDataSerie alloc] init];
//	NSMutableArray *mutArray = [[NSMutableArray alloc] init];
//	
//    for(i=0;i<num_scan;i++){
//        NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:time[i]/60.0f], @"Time",
//			[NSNumber numberWithInt:i], @"Scan",
//			[NSNumber numberWithFloat:intensities[i]], @"Total Intensity", nil];
//		[mutArray addObject:dict];      
//		[dict release];
//    }
//
//	[chromatogram setDataArray:mutArray];
//	[mutArray release];
//
////	JKLogDebug(@"max tot int: %f; max new int: %f", [self maximumTotalIntensity], jk_stats_float_max(intensities,num_scan));
////	[chromatogram setVerticalScale:[NSNumber numberWithFloat:[self maximumTotalIntensity]/jk_stats_float_max(intensities,num_scan)]];
//
//	[chromatogram setVerticalScale:[NSNumber numberWithFloat:1.0]];
//    
//    unsigned int count;
//    NSArray *presets = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"];
//    count = [presets count];
//    NSString *title;
//    title = mzValuesString;
//    for (i=0; i< count; i++) {
//        if([[[presets objectAtIndex:i] valueForKey:@"massValue"] isEqualToString:mzValuesString]) {
//            title = [NSString stringWithFormat:@"%@ (%@)", [[presets objectAtIndex:i] valueForKey:@"name"], mzValuesString];
//        }
//    }
//	[chromatogram setSeriesTitle:title];
//	[chromatogram setSeriesColor:[NSColor redColor]];
//	
//	[chromatogram setKeyForXValue:[[mainWindowController chromatogramView] keyForXValue]];
//	[chromatogram setKeyForYValue:@"Total Intensity"];
//
//	[chromatogram autorelease];
//	
//	return chromatogram;
//}

//- (SpectrumGraphDataSerie *)spectrumForScan:(int)scan {
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    SpectrumGraphDataSerie *spectrum;
//	
//    //create a spectrum object
//    spectrum = [[SpectrumGraphDataSerie alloc] init];
//
//    int npts;
//    npts = [self endValuesSpectrum:scan] - [self startValuesSpectrum:scan];
//    [spectrum setKeyForXValue:@"Mass"];
//    [spectrum setKeyForYValue:@"Intensity"];
//    
//    [spectrum loadDataPoints:npts withXValues:[self massValuesForSpectrumAtScan:scan] andYValues:[self intensityValuesForSpectrumAtScan:scan]];
//    
//	[spectrum setSeriesTitle:[NSString localizedStringWithFormat:@"Scan %d", scan]];
//    [spectrum setKeyForXValue:@"Mass"];
//    [spectrum setKeyForYValue:@"Intensity"];
//	    
//	[spectrum autorelease];
//	
//	return spectrum;
//}
//

//- (float *)yValuesIonChromatogram:(float)mzValue  
//{
//    int         i, dummy, dimid, varid_intensity_value, varid_mass_value;
//    float     	xx, yy;
//    float 	*y;
//    int		num_pts, scanCount;
//    scanCount = 0;
//    
//    dummy = nc_inq_varid(ncid, "mass_values", &varid_mass_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return 0;}
//    
//    dummy = nc_inq_varid(ncid, "intensity_values", &varid_intensity_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return 0;}
//    
//    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return 0;}
//    
//    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return 0;}
//    
//	
//	//	dummy = nc_get_vara_float(ncid, varid_intensity_value, (const size_t *) &i, (const size_t *) &num_pts, &xx);
//	//	nc_get_vara_float(int ncid, int varid,
//	//					   const size_t *startp, const size_t *countp, float *ip);
//    for(i = 0; i < num_pts; i++) {
//        dummy = nc_get_var1_float(ncid, varid_mass_value, (void *) &i, &xx);
//        if (fabs(xx-mzValue) < 0.5) {
//            y = (float *) malloc((scanCount+1)*sizeof(float));
//            dummy = nc_get_var1_float(ncid, varid_intensity_value, (const size_t *) &i, &yy);
//			// *(y + (scanCount)) = yy;
//            y[scanCount] = yy;
//			//			JKLogDebug(@"scan %d: mass %f = %f %f", scanCount, xx, yy, y[scanCount]);
//            scanCount++;
//        } else {
//			
//		}
//    };
//    JKLogDebug(@"scanCount = %d", scanCount);
//    return y;
//}
//
//- (int)startValuesSpectrum:(int)scan  
//{
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    int dummy, start, varid_scan_index;
//	
//    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//	
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//    return start;
//}
//
//
//- (int)endValuesSpectrum:(int)scan  
//{
//    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
//    int dummy, end, varid_scan_index;
//	
//    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//	
//    scan++;
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//	
//    return end;
//}

//- (int)countOfValuesForSpectrumAtScan:(int)scan {
//    return [self endValuesSpectrum:scan] - [self startValuesSpectrum:scan];
//}


//- (float)retentionIndexForScan:(int)scan {
//    return (time[scan]/60.0f) * [retentionIndexSlope floatValue] + [retentionIndexRemainder floatValue];
//}


//- (float *)massValues {
//    int     dummy, dimid, num_pts, varid;
//    float 	*result;
//
//    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_varid(ncid, "mass_values", &varid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_values variable failed. Report error #%d.", dummy); return 0;}
//
//	result = (float *) malloc((num_pts)*sizeof(float));
//        
//	dummy = nc_get_var_float(ncid, varid, result);
//
//    return result;
//}
//
//- (float *)intensityValues {
//    int     dummy, dimid, num_pts, varid;
//    float 	*result;
//    
//    dummy = nc_inq_dimid(ncid, "point_number", &dimid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return nil;}
//    
//    dummy = nc_inq_dimlen(ncid, dimid, (void *) &num_pts);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return nil;}
//
//    dummy = nc_inq_varid(ncid, "intensity_values", &varid);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_values variable failed. Report error #%d.", dummy); return 0;}
//    
//	result = (float *) malloc((num_pts)*sizeof(float));
//
//	dummy = nc_get_var_float(ncid, varid, result);
//    
//    return result;
//}

#pragma mark KEY VALUE CODING/OBSERVING

- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)object toValue:(id)newValue{
	[object setValue:newValue forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
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
intUndoAccessor(searchDirection, setSearchDirection, @"Change Search Direction")
intUndoAccessor(spectrumToUse, setSpectrumToUse,@"Change Spectrum")
boolUndoAccessor(penalizeForRetentionIndex, setPenalizeForRetentionIndex, @"Change Penalize for Offset Retention Index")
idUndoAccessor(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold, @"Change Identification Score")
idUndoAccessor(minimumScoreSearchResults, setMinimumScoreSearchResults, @"Change Minimum Score")
idUndoAccessor(minimumScannedMassRange, setMinimumScannedMassRange, @"Change Minimum Scanned Mass Range")
idUndoAccessor(maximumScannedMassRange, setMaximumScannedMassRange, @"Change Maximum Scanned Mass Range")

boolAccessor(abortAction, setAbortAction)

#pragma mark ACCESSORS

- (JKMainWindowController *)mainWindowController {
    if (!mainWindowController) {
		mainWindowController = [[JKMainWindowController alloc] init];
		[self makeWindowControllers];
	}
	return mainWindowController;
}

- (void)setNcid:(int)inValue {
    ncid = inValue;
}

- (int)ncid {
    return ncid;
}


- (void)setHasSpectra:(BOOL)inValue {
    hasSpectra = inValue;
}

- (BOOL)hasSpectra {
    return hasSpectra;
}

//- (int)intensityCount  
//{
//    return intensityCount;
//}
//- (void)setIntensityCount:(int)inValue  
//{
//    intensityCount = inValue;
//}
//
//- (void)setTime:(float *)inArray withCount:(int)inValue  
//{
//    numberOfPoints = inValue;
//    time = (float *) realloc(time, numberOfPoints*sizeof(float));
//    memcpy(time, inArray, numberOfPoints*sizeof(float));
//	//jk_stats_float_minmax(&minimumTime, &maximumTime, time, 1, numberOfPoints);
//	minimumTime = jk_stats_float_min(time, numberOfPoints);
//	maximumTime = jk_stats_float_max(time, numberOfPoints);
//}
//
//- (float *)time  
//{
//    return time;
//}
//
//- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue  
//{
//    numberOfPoints = inValue;
//    totalIntensity = (float *) realloc(totalIntensity, numberOfPoints*sizeof(float));
//    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(float));
//	minimumTotalIntensity = jk_stats_float_min(totalIntensity, numberOfPoints);
//	maximumTotalIntensity = jk_stats_float_max(totalIntensity, numberOfPoints);
//	
//}
//
//- (float *)totalIntensity  
//{
//    return totalIntensity;
//}
//
//- (float)maximumTime  
//{
//    return maximumTime;
//}
//
//- (float)minimumTime  
//{
//    return minimumTime;
//}
//
//- (float)maximumTotalIntensity  
//{
//    return maximumTotalIntensity;
//}
//
//- (float)minimumTotalIntensity  
//{
//    return minimumTotalIntensity;
//}

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

//- (void)setBaseline:(NSMutableArray *)inValue  
//{
//    [[self undoManager] registerUndoWithTarget:self
//                                      selector:@selector(setBaseline:)
//                                        object:baseline];
//    [[self undoManager] setActionName:NSLocalizedString(@"Change Baseline",@"")];
//
//    [inValue retain];
//	[baseline autorelease];
//	baseline = inValue;
//}
//
//- (NSMutableArray *)baseline  
//{
//	return baseline;
//}

// Mutable To-Many relationship chromatograms
- (NSMutableArray *)chromatograms {
	return chromatograms;
}

- (void)setChromatograms:(NSMutableArray *)inValue {
    [inValue retain];
    [chromatograms release];
    chromatograms = inValue;
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
}

- (BOOL)validateChromatogram:(JKChromatogram **)aChromatogram error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end chromatograms

- (NSMutableArray *)peaks{
    NSMutableArray *array = [NSMutableArray array];
    NSEnumerator *chromEnum = [[self chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;

    while ((chromatogram = [chromEnum nextObject]) != nil) {
    	[array addObjectsFromArray:[chromatogram peaks]];
    }
	return array;
}

- (void)setPeaks:(NSMutableArray *)array{
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
            
            [chromatogram removeObjectFromPeaksAtIndex:[[chromatogram peaks] indexOfObject:peak]];
            break;
        }
    }
}

@end



