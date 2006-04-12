//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKMainDocument.h"
#import "JKDataModel.h"
#import "JKMainWindowController.h"
#import "JKPeakIdentificationWindowController.h"
#import "netcdf.h"

NSString *const JKMainDocument_DocumentDeactivateNotification = @"JKMainDocument_DocumentDeactivateNotification";
NSString *const JKMainDocument_DocumentActivateNotification = @"JKMainDocument_DocumentActivateNotification";
NSString *const JKMainDocument_DocumentLoadedNotification = @"JKMainDocument_DocumentLoadedNotification";

@implementation JKMainDocument
#pragma mark INITIALIZATION

-(id)init {
	self = [super init];
    if (self != nil) {
        mainWindowController = [[JKMainWindowController alloc] init];
		//	[NSException raise:NSLocalizedString(@"Creating new document not supported",@"Creating new document not supported") format:NSLocalizedString(@"Creating new documents is not supported, try importing a suitable file instead.",@"Creating new documents is not supported, try importing a suitable file instead.")];

    }
    return self;
}

-(void)dealloc {
    [super dealloc];
}

#pragma mark WINDOW MANAGEMENT

-(void)makeWindowControllers {
	[[NSNotificationCenter defaultCenter] postNotificationName:JKMainDocument_DocumentLoadedNotification object:self];
	NSAssert(mainWindowController != nil, @"mainWindowController is nil");
	[self addWindowController:mainWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType{
	if ([aType isEqualToString:@"Peacock File"]) {

		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver encodeObject:[self dataModel] forKey:@"dataModel"];
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
	NSDate *startT = [NSDate date];
	if ([typeName isEqualToString:@"NetCDF File"]) {
		JKLogDebug(@"Time in -[readFromURL:]: %g seconds", -[startT timeIntervalSinceNow]);
		return [self readNetCDFFile:[absoluteURL path] error:outError];
	} else if ([typeName isEqualToString:@"Peacock File"]) {
		BOOL result;		
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
		NSData *data;
		NSKeyedUnarchiver *unarchiver;
		data = [[[wrapper fileWrappers] valueForKey:@"peacock-data"] regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
		dataModel = [[unarchiver decodeObjectForKey:@"dataModel"] retain];
		[unarchiver finishDecoding];
		[unarchiver release];
		
		result = [self readNetCDFFile:[[absoluteURL path] stringByAppendingPathComponent:@"netcdf"] error:outError];
		if (result) {
			peacockFileWrapper = wrapper;
		}
		JKLogDebug(@"Time: %g seconds", -[startT timeIntervalSinceNow]);
		return result;	
	} else {
		return NO;
	}	
}

-(IBAction)openNext:(id)sender {
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

-(BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError {
	int ncid, errCode;

	// Get the file's name and pull the id. Test to make sure that this all worked.
	errCode = nc_open([fileName cString], NC_NOWRITE, &ncid);
	if (errCode != NC_NOERR) {
		if (anError != NULL)
			*anError = [[[NSError alloc] initWithDomain:@"JKNetCDFDomain" 
												   code:errCode userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unreadable file", NSLocalizedDescriptionKey, @"The file was not readable as a NetCDF file.", NSLocalizedFailureReasonErrorKey, @"Try exporting from the originating application again selecting NetCDF as the export file format.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
		return NO;
	}

	// Pass ncid to dataModel
	if (!dataModel)
		dataModel = [[JKDataModel alloc] init];
	NSAssert([self dataModel] != nil, @"JKDataModel is not inited");
	
	[[self dataModel] setNcid:ncid];
	
	absolutePathToNetCDF = fileName;

	return [[self dataModel] finishInitWithError:anError];
}

-(NSString *)exportTabDelimitedText {
	NSMutableString *outStr = [[NSMutableString alloc] init]; 
	NSArray *array = [[[self mainWindowController] peakController] arrangedObjects];
	int i;
	int count = [array count];
	
	[outStr appendString:NSLocalizedString(@"File\tID\tLabel\tScore\tIdentified\tConfirmed\tStart (scan)\tTop (scan)\tEnd (scan)\tStart (min)\tTop (min)\tEnd (min)\tHeight (normalized)\tSurface (normalized)\tHeight (abs.)\tWidth (scan)\tSurface (abs.)\tBaseline Left\tBaseline Right\tName (Lib.)\tFormula (Lib.)\tCAS No. (Lib.)\tRetention Index (Lib.)\tComment (Lib.)\n",@"Top row of tab delimited text export.")];
	for (i=0; i < count; i++) {
		[outStr appendFormat:@"%@\t", [self displayName]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"peakID"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"label"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"score"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"identified"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"confirmed"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"start"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"top"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"end"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"startTime"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"topTime"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"endTime"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"normalizedHeight"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"normalizedSurface"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"height"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"width"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"surface"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"baselineL"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKey:@"baselineR"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"libraryHit.name"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"libraryHit.formula"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"libraryHit.CASNumber"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"libraryHit.retentionIndex"]];
		[outStr appendFormat:@"%@\t", [[array objectAtIndex:i] valueForKeyPath:@"libraryHit.comment"]];
		[outStr appendString:@"\n"];
	}

	[outStr autorelease];
	return outStr;
}

-(NSComparisonResult)metadataCompare:(JKMainDocument *)otherDocument {
	int metadataChoosen = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"columnSorting"] intValue];

	switch (metadataChoosen) {
	case 1: // samplecode
		return [[[[self dataModel] metadata] valueForKey:@"sampleCode"] caseInsensitiveCompare:[[[otherDocument dataModel] metadata] valueForKey:@"sampleCode"]];
		break;
	case 2: // sampleDescription
		return [[[[self dataModel] metadata] valueForKey:@"sampleDescription"] caseInsensitiveCompare:[[[otherDocument dataModel] metadata] valueForKey:@"sampleDescription"]];
		break;
	default:
		return [[[[self dataModel] metadata] valueForKey:@"sampleCode"] caseInsensitiveCompare:[[[otherDocument dataModel] metadata] valueForKey:@"sampleCode"]];
		break;
	}
		
}
#pragma mark PRINTING

- (void)printShowingPrintPanel:(BOOL)showPanels {
    // Obtain a custom view that will be printed
    NSView *printView = [[[self mainWindowController] window] contentView];
	
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
				  didRunSelector:NULL
					 contextInfo:NULL];
}

#pragma mark ACCESSORS

-(JKDataModel *)dataModel {
    return dataModel;
}

-(JKMainWindowController *)mainWindowController {
    return mainWindowController;
}

#pragma mark NOTIFICATIONS

- (void) postNotification: (NSString *) notificationName
{
    NSNotificationCenter *center;
    center = [NSNotificationCenter defaultCenter];
    
    [center postNotificationName: notificationName
						  object: self];
	
} // postNotification


- (void) windowDidBecomeMain: (NSNotification *) notification
{
    [self postNotification: 
		JKMainDocument_DocumentActivateNotification];
	
} // windowDidBecomeMain


- (void) windowDidResignMain: (NSNotification *) notification
{
    [self postNotification: 
		JKMainDocument_DocumentDeactivateNotification];
	
} // windowDidResignMain


- (void) windowWillClose: (NSNotification *) notification
{
    [self postNotification: 
		JKMainDocument_DocumentDeactivateNotification];
	
} // windowDidClose
@end
