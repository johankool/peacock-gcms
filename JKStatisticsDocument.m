//
//  JKStatisticsDocument.m
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKStatisticsDocument.h"
#import "JKStatisticsWindowController.h"


@implementation JKStatisticsDocument

#pragma mark INITIALIZATION

- (id)init  
{
	self = [super init];
    if (self != nil) {
        statisticsWindowController = [[JKStatisticsWindowController alloc] init];
    }
    return self;
}

- (void)dealloc  
{
    [super dealloc];
}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers  
{
	NSAssert(statisticsWindowController != nil, @"statisticsWindowController is nil");
	[self addWindowController:statisticsWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType 
{
	if ([aType isEqualToString:@"Peacock Statistics File"]) {
		
		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
		[archiver encodeInt:1 forKey:@"version"];
		[archiver encodeObject:[statisticsWindowController combinedPeaks] forKey:@"combinedPeaks"];
		[archiver encodeObject:[statisticsWindowController ratioValues] forKey:@"ratioValues"];
		[archiver encodeObject:[statisticsWindowController metadata] forKey:@"metadata"];
		[archiver encodeObject:[statisticsWindowController files] forKey:@"files"];
		[archiver encodeObject:[statisticsWindowController logMessages] forKey:@"logMessages"];
		[archiver encodeInt:[statisticsWindowController peaksToUse] forKey:@"peaksToUse"];
        [archiver encodeInt:[statisticsWindowController columnSorting] forKey:@"columnSorting"];
        [archiver encodeBool:[statisticsWindowController penalizeForRetentionIndex] forKey:@"penalizeForRetentionIndex"];
        [archiver encodeBool:[statisticsWindowController setPeakSymbolToNumber] forKey:@"setPeakSymbolToNumber"];
        [archiver encodeObject:[statisticsWindowController matchThreshold] forKey:@"matchThreshold"];
        [archiver encodeInt:[statisticsWindowController scoreBasis] forKey:@"scoreBasis"];
        [archiver encodeInt:[statisticsWindowController valueToUse] forKey:@"valueToUse"];
        [archiver encodeBool:[statisticsWindowController closeDocuments] forKey:@"closeDocuments"];
        [archiver encodeBool:[statisticsWindowController calculateRatios] forKey:@"calculateRatios"];
               
		[archiver finishEncoding];
		[archiver release];
		
		NSFileWrapper *fileWrapperForData = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
			
		return fileWrapperForData;
	} else {
		return nil;
	}
}

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError  
{
	if ([typeName isEqualToString:@"Peacock Statistics File"]) {
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
		NSData *data;
		NSKeyedUnarchiver *unarchiver;
		data = [wrapper regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        [statisticsWindowController willChangeValueForKey:@"combinedPeaks"];
				
		[statisticsWindowController setCombinedPeaks:[unarchiver decodeObjectForKey:@"combinedPeaks"]];
		[statisticsWindowController setRatioValues:[unarchiver decodeObjectForKey:@"ratioValues"]];
		[statisticsWindowController setMetadata:[unarchiver decodeObjectForKey:@"metadata"]];
		[statisticsWindowController setFiles:[unarchiver decodeObjectForKey:@"files"]];
		[statisticsWindowController setLogMessages:[unarchiver decodeObjectForKey:@"logMessages"]];
        [statisticsWindowController setPeaksToUse:[unarchiver decodeIntForKey:@"peaksToUse"]];
        [statisticsWindowController setColumnSorting:[unarchiver decodeIntForKey:@"columnSorting"]];
        [statisticsWindowController setPenalizeForRetentionIndex:[unarchiver decodeBoolForKey:@"penalizeForRetentionIndex"]];
        [statisticsWindowController setSetPeakSymbolToNumber:[unarchiver decodeBoolForKey:@"setPeakSymbolToNumber"]];
		[statisticsWindowController setMatchThreshold:[unarchiver decodeObjectForKey:@"matchThreshold"]];
        [statisticsWindowController setScoreBasis:[unarchiver decodeIntForKey:@"scoreBasis"]];
        [statisticsWindowController setValueToUse:[unarchiver decodeIntForKey:@"valueToUse"]];
        [statisticsWindowController setCloseDocuments:[unarchiver decodeBoolForKey:@"closeDocuments"]];
        [statisticsWindowController setCalculateRatios:[unarchiver decodeBoolForKey:@"calculateRatios"]];
        [statisticsWindowController didChangeValueForKey:@"combinedPeaks"];
		[unarchiver finishDecoding];
		[unarchiver release];
		[wrapper release];
		return YES;	
	} else {
		return NO;
	}	
}
		
#pragma mark PRINTING

- (void)printShowingPrintPanel:(BOOL)showPanels  
{
    // Obtain a custom view that will be printed
    NSView *printView = [[[self statisticsWindowController] window] contentView];
	
    // Construct the print operation and setup Print panel
    NSPrintOperation *op = [NSPrintOperation
                printOperationWithView:printView
							 printInfo:[self printInfo]];
    [op setShowPanels:showPanels];
    if (showPanels) {
        // Add accessory view, if needed
//		[op setAccessoryView:[statisticsWindowController printAccessoryView]];
    }
	
    // Run operation, which shows the Print panel if showPanels was YES
    [self runModalPrintOperation:op
						delegate:nil
				  didRunSelector:NULL
					 contextInfo:NULL];
}

#pragma mark ACCESSORS

- (JKStatisticsWindowController *)statisticsWindowController  
{
    return statisticsWindowController;
}

@end
