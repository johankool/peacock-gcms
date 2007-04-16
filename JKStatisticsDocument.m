//
//  JKStatisticsDocument.m
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import "JKStatisticsDocument.h"

#import "BDAlias.h"
#import "JKLibrary.h"
#import "JKPeakRecord.h"
#import "JKStatisticsWindowController.h"

@implementation JKStatisticsDocument

#pragma mark INITIALIZATION

- (id)init {
	self = [super init];
    if (self != nil) {
        _documentProxy = [[NSDictionary alloc] initWithObjectsAndKeys:@"_documentProxy", @"_documentProxy",nil];
    }
    return self;
}

- (void)dealloc {
    [_documentProxy release];
    if (statisticsWindowController) {
        [statisticsWindowController release];
    }
    [super dealloc];
}

#pragma mark WINDOW MANAGEMENT

- (void)makeWindowControllers {
    if (!statisticsWindowController) {
        statisticsWindowController = [[JKStatisticsWindowController alloc] init];
    }
	[self addWindowController:statisticsWindowController];
}

#pragma mark FILE ACCESS MANAGEMENT

- (NSFileWrapper *)fileWrapperRepresentationOfType:(NSString *)aType {
	if ([aType isEqualToString:@"Peacock Statistics File"]) {
		
		NSMutableData *data;
		NSKeyedArchiver *archiver;
		data = [NSMutableData data];
		archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver setDelegate:self];
		[archiver encodeInt:2 forKey:@"version"];
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

- (BOOL)readFromURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	if ([typeName isEqualToString:@"Peacock Statistics File"]) {
		NSFileWrapper *wrapper = [[NSFileWrapper alloc] initWithPath:[absoluteURL path]];
		NSData *data;
		NSKeyedUnarchiver *unarchiver;
		data = [wrapper regularFileContents];
		unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        [unarchiver setDelegate:self];
#warning [BUG] Early init of statisticsWindowController
        // Bit of a hack, these values should after all reside in the document and not in the window controller
        // but moving all the methods from the window controller is a lot of work and I don't have the time for that now.
        if (!statisticsWindowController) {
            statisticsWindowController = [[JKStatisticsWindowController alloc] init];
        }        
        
        [statisticsWindowController willChangeValueForKey:@"combinedPeaks"];
        // open files first so we are ready to find peaks contained in combinedpeaks
		[statisticsWindowController setFiles:[unarchiver decodeObjectForKey:@"files"]];
        [statisticsWindowController setRatioValues:[unarchiver decodeObjectForKey:@"ratioValues"]];
		[statisticsWindowController setMetadata:[unarchiver decodeObjectForKey:@"metadata"]];
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
		[statisticsWindowController setCombinedPeaks:[unarchiver decodeObjectForKey:@"combinedPeaks"]];
        [statisticsWindowController didChangeValueForKey:@"combinedPeaks"];
        JKLogDebug(@"retaincount = %d",[self retainCount]);
        [self retain];
		[unarchiver finishDecoding];
		[unarchiver release];
		[wrapper release];
		return YES;	
	} else {
		return NO;
	}	
}
		
- (id)archiver:(NSKeyedArchiver *)archiver willEncodeObject:(id)object {
    if (object == self) {
        return _documentProxy;
    } else if ([object isKindOfClass:[JKGCMSDocument class]]) {
        return [BDAlias aliasWithPath:[object fileName]];
    } else if ([object isKindOfClass:[JKLibrary class]]) {
        return [BDAlias aliasWithPath:[object fileName]];
    } else if ([object isKindOfClass:[JKPeakRecord class]]) {
        return [NSDictionary dictionaryWithObject:[object uuid] forKey:@"_peakUuid"];
    }
    return object;
}

- (id)unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        if ([[object valueForKey:@"_documentProxy"] isEqualToString:@"_documentProxy"]) {
            return self;
        } else if ([object valueForKey:@"_peakUuid"]) {
            NSString *uuid = [object valueForKey:@"_peakUuid"];
            NSEnumerator *docEnum = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
            id document;

            while ((document = [docEnum nextObject]) != nil) {
                if ([document isKindOfClass:[JKGCMSDocument class]]) {
                    NSEnumerator *peakEnum = [[document peaks] objectEnumerator];
                    JKPeakRecord *peak;
                    
                    while ((peak = [peakEnum nextObject]) != nil) {
                        if ([[peak uuid] isEqualToString:uuid]) {
                            return peak;
                        }
                    }                    
                }
            }
            JKLogError(@"Could not find peak with uuid %@", uuid);
            return [[NSObject alloc] init]; // no autorelease?
        }
    } else if ([object isKindOfClass:[BDAlias class]]) {
        id document;
        NSError *error = [[NSError alloc] init];
        NSAssert(object, @"decoding nil BDAlias?!");
        if (![object fullPath]) {
            JKLogDebug(@"Could not resolve alias stored in document.");
            int result;
            NSArray *fileTypes = [NSArray arrayWithObject:@"peacock"];
            NSOpenPanel *oPanel = [NSOpenPanel openPanel];
            [oPanel setMessage:[NSString stringWithFormat:@"Select missing file '%@'",[object originalPath]]];
            [oPanel setPrompt:NSLocalizedString(@"Select",@"Resolving missing alias prompt")];
            [oPanel setTitle:NSLocalizedString(@"Resolve Missing File",@"Resolving missing alias title")];
            [oPanel setAllowsMultipleSelection:NO];
            result = [oPanel runModalForDirectory:nil
                                             file:nil types:fileTypes];
            if (result == NSOKButton) {
                NSArray *filesToOpen = [oPanel filenames];
                object = [BDAlias aliasWithPath:[filesToOpen objectAtIndex:0]];
            } else {
                JKLogError(@"Could not resolve alias stored in document!!! This is a big problem!");
                
                return object;                
            }
        }
        JKLogDebug(@"BDAlias at path: %@",[object fullPath]);
		document = [[NSDocumentController sharedDocumentController] documentForURL:[NSURL fileURLWithPath:[object fullPath]]];
        if (!document) {
            document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[object fullPath]] display:YES error:&error];
            if (!document) {
                // maybe try to determine cause of error and recover first
                NSAlert *theAlert = [NSAlert alertWithError:error];
                [theAlert runModal]; // ignore return value                
            }
        }
        [document retain];
        return document;
    }
    return object;
}

#pragma mark PRINTING

- (void)printShowingPrintPanel:(BOOL)showPanels {
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

- (JKStatisticsWindowController *)statisticsWindowController {
    return statisticsWindowController;
}

@end
