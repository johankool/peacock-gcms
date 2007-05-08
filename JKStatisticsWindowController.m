//
//  JKStatisticsWindowController.m
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
//

#import "JKStatisticsWindowController.h"

#import "BDAlias.h"
#import "ChromatogramGraphDataSerie.h"
#import "Growl/GrowlApplicationBridge.h"
#import "JKChromatogram.h"
#import "JKCombinedPeak.h"
#import "JKGCMSDocument.h"
#import "JKMainWindowController.h"
#import "JKPeakRecord.h"
#import "JKRatio.h"
#import "JKSearchResult.h"
#import "JKSpectrum.h"
#import "MyGraphView.h"
#import "NSEvent+ModifierKeys.h"

@implementation JKStatisticsWindowController

#pragma mark Initialization & deallocation
- (id) init 
{
	self = [super initWithWindowNibName:@"JKStatisticalAnalysis"];
	if (self != nil) {
		combinedPeaks = [[NSMutableArray alloc] init];
		ratioValues = [[NSMutableArray alloc] init];
		ratios = [[NSMutableArray alloc] init];
		metadata = [[NSMutableArray alloc] init];
		files = [[NSMutableArray alloc] init];
        logMessages = [[NSMutableArray alloc] init];
		[self setAbortAction:NO];
        peaksToUse = 1;
        columnSorting = 1;
        penalizeForRetentionIndex = YES;
        setPeakSymbolToNumber = YES;
        [self setMatchThreshold:[NSNumber numberWithFloat:75.0]];
        [self setMaximumRetentionIndexDifference:[NSNumber numberWithFloat:200.0]];
        scoreBasis = 0;
        valueToUse = 3;
        closeDocuments = NO;
        calculateRatios = NO;
        comparePeaks = YES;
        performSanityCheck = YES;
        rerunNeeded = NO;
	}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[combinedPeaks release];
	[ratioValues release];
	[ratios release];
	[metadata release];
	[files release];
    [logMessages release];
	[super dealloc];
}
#pragma mark -

#pragma mark Window Management
- (void)windowDidLoad {
	// Load Ratios file from application support folder
	NSArray *paths;
	unsigned int i;
	BOOL foundFile = NO;
	NSFileManager *mgr = [NSFileManager defaultManager];
	NSString *destPath;
	
	paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
	
	for (i = 0; i < [paths count]; i++) {
		destPath = [[paths objectAtIndex:i] stringByAppendingPathComponent:@"Peacock/Ratios.plist"];
		if ([mgr fileExistsAtPath:destPath]) {
			[self setRatios:[NSKeyedUnarchiver unarchiveObjectWithFile:destPath]];
			foundFile = YES;
			break;
		}			
	}	
	if(!foundFile) {
		destPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Peacock"];
		if (![mgr createDirectoryAtPath:destPath attributes:nil]) {
			JKLogError(@"Could not create Peacock's Application Support directory.");
		} else {
			destPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Peacock/Ratios.plist"];
			if (![NSKeyedArchiver archiveRootObject:ratios toFile:destPath])
				JKLogError(@"Error creating Ratios.plist file.");
		}	
	}
		
//	[filesTableView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
	
	[resultsTable setDelegate:self];
	[ratiosTable setDelegate:self];
	[metadataTable setDelegate:self];
	[resultsTable setDoubleAction:@selector(doubleClickAction:)];
	[ratiosTable setDoubleAction:@selector(doubleClickAction:)];
	[metadataTable setDoubleAction:@selector(doubleClickAction:)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[resultsTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[ratiosTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[metadataTable superview]];
	
	if ([files count] > 0) {
        // Insert table columns (in case we're opening from a file)
        if ([combinedPeaks count] > 0) {
            // Insert table columns (in case we're opening from a file)
            [combinedPeaksController setContent:combinedPeaks];
        }
        [self insertTableColumns];
        [self insertGraphDataSeries];
 	}
    
    [altGraphView bind:@"dataSeries" toObject:chromatogramDataSeriesController
           withKeyPath:@"arrangedObjects" options:nil];
    [altGraphView bind:@"peaks" toObject: peaksController
           withKeyPath:@"arrangedObjects" options:nil];
    
    [altGraphView setKeyForXValue:@"Time"];
    [altGraphView setKeyForYValue:@"Total Intensity"];
    
    // Register as observer
	[combinedPeaksController addObserver:self forKeyPath:@"selection" options:nil context:nil];
}
#pragma mark -

#pragma mark Actions
// Move this method to JKStatisticsDocument
- (void)runStatisticalAnalysis {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	BOOL errorOccurred = NO;	
	[self setAbortAction:NO];
    int i;
    int filesCount = [files count];
	NSError *error = [[NSError alloc] init];
	JKGCMSDocument *document = nil;

	// Prepations before starting processing files
	[detailStatusTextField setStringValue:NSLocalizedString(@"Preparing processing",@"")];
	[fileProgressIndicator setIndeterminate:YES];
	[fileProgressIndicator startAnimation:self];
	
    // Reset things we'll be collecting
    [self willChangeValueForKey:@"metadata"];
	[metadata removeAllObjects];
	[combinedPeaks removeAllObjects];
	[ratioValues removeAllObjects];
    [logMessages removeAllObjects];
	[chromatogramDataSeriesController removeObjects:[chromatogramDataSeriesController arrangedObjects]];
    
    // Recreate metadata structure
	NSMutableDictionary *metadataDictSampleCode = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *metadataDictDescription = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *metadataDictPath = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *metadataDictDisplayName = [[NSMutableDictionary alloc] init];
	[metadataDictSampleCode setValue:@"Sample code" forKey:@"label"];
	[metadataDictDescription setValue:@"Description" forKey:@"label"];
	[metadataDictPath setValue:@"File path" forKey:@"label"];
	[metadataDictDisplayName setValue:@"File name" forKey:@"label"];
	[metadata addObject:metadataDictSampleCode];
	[metadata addObject:metadataDictDescription];
	[metadata addObject:metadataDictPath];
	[metadata addObject:metadataDictDisplayName];
	[metadataDictSampleCode release];
	[metadataDictDescription release];
	[metadataDictPath release];
	[metadataDictDisplayName release];
	
	// Reset
	unknownCount = 0;

	[fileProgressIndicator setIndeterminate:NO];
	[fileProgressIndicator setMaxValue:filesCount*5.0];
	[fileProgressIndicator setDoubleValue:0.0];
	for (i=0; i < filesCount; i++) {
		[detailStatusTextField setStringValue:@"Opening Document"];
		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:!closeDocuments error:&error];
        if (!document) {
            // maybe try to determine cause of error and recover first
            NSAlert *theAlert = [NSAlert alertWithError:error];
            [theAlert runModal]; // ignore return value
        }
		[[self window] makeKeyAndOrderFront:self];
		if (document == nil) {
			//  Error(@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]);
			errorOccurred = YES;
            NSString *errorMsg = [NSString stringWithFormat:@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]];
            NSDictionary *warning = [NSDictionary dictionaryWithObjectsAndKeys:@"UNKNOWN", @"document", errorMsg, @"warning", nil];
            [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
			[fileProgressIndicator setDoubleValue:(i+1)*5.0];
			continue;	
		}
		[fileStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Processing file '%@' (%d of %d)",@"Batch process status text"),[[files objectAtIndex:i] valueForKey:@"filename"],i+1,filesCount]];
		if (abortAction) {
			break;
		}		
		[detailStatusTextField setStringValue:NSLocalizedString(@"Collecting metadata",@"")];
		[self collectMetadataForDocument:document atIndex:i];
		[fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}
		if (comparePeaks) {
            [detailStatusTextField setStringValue:NSLocalizedString(@"Comparing Peaks",@"")];
            [self collectCombinedPeaksForDocument:document atIndex:i];  
        }
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}		
		if (calculateRatios) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Calculating Ratios",@"")];
			[self calculateRatiosForDocument:document atIndex:i];
		}
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}
        [detailStatusTextField setStringValue:NSLocalizedString(@"Setting up Comparison Window",@"")];
        [self setupComparisonWindowForDocument:document atIndex:i];
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}		
		if (closeDocuments) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Closing Document",@"")];
			[document close];
		}
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}
		[fileProgressIndicator setDoubleValue:(i+1)*5.0];
	}
	// Out of scope for files
	
	
	// Sorting results
    [detailStatusTextField setStringValue:NSLocalizedString(@"Sorting Results",@"")];
	[fileProgressIndicator setIndeterminate:YES];
    [self sortCombinedPeaks];
    
    if (setPeakSymbolToNumber) {        
        NSEnumerator *peaksEnumerator = nil;
        JKPeakRecord *peak = nil;
        int combinedPeaksCount = [[self combinedPeaks] count];
        [detailStatusTextField setStringValue:NSLocalizedString(@"Assigning Symbols",@"")];
        // Number in order of occurence
        for (i = 0; i < combinedPeaksCount; i++) {
            [[combinedPeaks objectAtIndex:i] setSymbol:[NSNumber numberWithInt:i+1]];
            peaksEnumerator = [[[combinedPeaks objectAtIndex:i] peaks] objectEnumerator];		
            while ((peak = [peaksEnumerator nextObject])) {
                [peak setSymbol:[NSString stringWithFormat:@"%d", i+1]];
            }		
        }
    }
    
   if (performSanityCheck) {
       [detailStatusTextField setStringValue:NSLocalizedString(@"Checking Sanity",@"")];
       for (i=0; i < filesCount; i++) {
           //NSLog(@"file %d of %d", i, filesCount);
           document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:!closeDocuments error:&error];
           if (!document) {
               // maybe try to determine cause of error and recover first
               NSAlert *theAlert = [NSAlert alertWithError:error];
               [theAlert runModal]; // ignore return value
           }           
           [self doSanityCheckForDocument:document atIndex:i];
           if (abortAction) {
               break;
           }        
       }       
   }
     
	[error release];
	[[self window] makeKeyAndOrderFront:self];
	
    [detailStatusTextField setStringValue:NSLocalizedString(@"Preparing Table",@"")];
    [self insertTableColumns];
    
	// Present graphdataseries in colors
    [detailStatusTextField setStringValue:NSLocalizedString(@"Preparing Graph",@"")];
    NSColorList *peakColors = [NSColorList colorListNamed:@"Peacock Series"];
    if (peakColors == nil) {
        peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
    }
    NSArray *peakColorsArray = [peakColors allKeys];
    int peakColorsArrayCount = [peakColorsArray count];
    
    for (i = 0; i < [[chromatogramDataSeriesController arrangedObjects] count]; i++) {
        [[[chromatogramDataSeriesController arrangedObjects] objectAtIndex:i] setShouldDrawPeaks:NO];
        [(ChromatogramGraphDataSerie *)[[chromatogramDataSeriesController arrangedObjects] objectAtIndex:i] setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:i%peakColorsArrayCount]]];
    }
    [altGraphView showAll:self];

	// This way we don't get bolded text!
    [NSApp endSheet:progressSheet];
	//[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
    
	if (errorOccurred) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error(s) during processing",@""),NSLocalizedString(@"One or more errors occurred during processing your files. The log contains more details about the error. Common errors include files moved after being added to the list and full disks.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	} else if (abortAction) {
		NSRunInformationalAlertPanel(NSLocalizedString(@"Statistical Analysis aborted",@""),NSLocalizedString(@"The execution of the statistical analysis was aborted by the user. Be advised to check the current state of the files that were being processed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	} else {
        [GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Statistical Analysis Finished",@"") description:NSLocalizedString(@"Peacock finished processing your data.",@"") notificationName:@"Statistical Analysis Finished" iconData:nil priority:0 isSticky:NO clickContext:nil];
        [tabView performSelectorOnMainThread:@selector(selectTabViewItemWithIdentifier:) withObject:@"tabular" waitUntilDone:NO];
    }
    
    rerunNeeded = NO;
    [self didChangeValueForKey:@"metadata"];
	[pool release];
}

- (void)updateCombinedPeaks {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
	BOOL errorOccurred = NO;	
	[self setAbortAction:NO];
    int i;
    int filesCount = [files count];
	NSError *error = [[NSError alloc] init];
	JKGCMSDocument *document = nil;
    
	// Prepations before starting processing files
	[detailStatusTextField setStringValue:NSLocalizedString(@"Preparing processing",@"")];
	
    [fileProgressIndicator setIndeterminate:NO];
	[fileProgressIndicator setMaxValue:filesCount*5.0];
	[fileProgressIndicator setDoubleValue:0.0];
	for (i=0; i < filesCount; i++) {
		[detailStatusTextField setStringValue:@"Opening Document"];
		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:!closeDocuments error:&error];
        if (!document) {
            // maybe try to determine cause of error and recover first
            NSAlert *theAlert = [NSAlert alertWithError:error];
            [theAlert runModal]; // ignore return value
        }
		[[self window] makeKeyAndOrderFront:self];
		if (document == nil) {
			//  Error(@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]);
			errorOccurred = YES;
            NSString *errorMsg = [NSString stringWithFormat:@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]];
            NSDictionary *warning = [NSDictionary dictionaryWithObjectsAndKeys:@"UNKNOWN", @"document", errorMsg, @"warning", nil];
            [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
			[fileProgressIndicator setDoubleValue:(i+1)*5.0];
			continue;	
		}
		[fileStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Processing file '%@' (%d of %d)",@"Batch process status text"),[[files objectAtIndex:i] valueForKey:@"filename"],i+1,filesCount]];
		if (abortAction) {
			break;
		}		
		if (comparePeaks) {
            [detailStatusTextField setStringValue:NSLocalizedString(@"Comparing Peaks",@"")];
            [self updateCombinedPeaksForDocument:document atIndex:i];  
        }
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}		
		if (closeDocuments) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Closing Document",@"")];
			[document close];
		}
        [fileProgressIndicator incrementBy:1.0];
		if (abortAction) {
			break;
		}
		[fileProgressIndicator setDoubleValue:(i+1)*5.0];
	}
	// Out of scope for files
	
	
	// Sorting results
    [detailStatusTextField setStringValue:NSLocalizedString(@"Sorting Results",@"")];
	[fileProgressIndicator setIndeterminate:YES];
    [self sortCombinedPeaks];
    
    if (setPeakSymbolToNumber) {        
        NSEnumerator *peaksEnumerator = nil;
        JKPeakRecord *peak = nil;
        int combinedPeaksCount = [[self combinedPeaks] count];
        [detailStatusTextField setStringValue:NSLocalizedString(@"Assigning Symbols",@"")];
        // Number in order of occurence
        for (i = 0; i < combinedPeaksCount; i++) {
            [[combinedPeaks objectAtIndex:i] setSymbol:[NSNumber numberWithInt:i+1]];
            peaksEnumerator = [[[combinedPeaks objectAtIndex:i] peaks] objectEnumerator];		
            while ((peak = [peaksEnumerator nextObject])) {
                [peak setSymbol:[NSString stringWithFormat:@"%d", i+1]];
            }		
        }
    }
    
    if (performSanityCheck) {
        [detailStatusTextField setStringValue:NSLocalizedString(@"Checking Sanity",@"")];
        for (i=0; i < filesCount; i++) {
            //NSLog(@"file %d of %d", i, filesCount);
            document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:!closeDocuments error:&error];
            if (!document) {
                // maybe try to determine cause of error and recover first
                NSAlert *theAlert = [NSAlert alertWithError:error];
                [theAlert runModal]; // ignore return value
            }           
            [self doSanityCheckForDocument:document atIndex:i];
            if (abortAction) {
                break;
            }        
        }       
    }
    
	[error release];
	[[self window] makeKeyAndOrderFront:self];
	    
	// This way we don't get bolded text!
    [NSApp endSheet:progressSheet];
	//[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
    
	if (errorOccurred) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error(s) during processing",@""),NSLocalizedString(@"One or more errors occurred during processing your files. The log contains more details about the error. Common errors include files moved after being added to the list and full disks.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	} else if (abortAction) {
		NSRunInformationalAlertPanel(NSLocalizedString(@"Statistical Analysis aborted",@""),NSLocalizedString(@"The execution of the statistical analysis was aborted by the user. Be advised to check the current state of the files that were being processed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	} else {
        [GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Statistical Analysis Updated",@"") description:NSLocalizedString(@"Peacock finished processing your data.",@"") notificationName:@"Statistical Analysis Updated" iconData:nil priority:0 isSticky:NO clickContext:nil];
        [tabView performSelectorOnMainThread:@selector(selectTabViewItemWithIdentifier:) withObject:@"tabular" waitUntilDone:NO];
    }
    
    [pool release];
}

// Move this method to JKStatisticsDocument
- (void)collectMetadataForDocument:(JKGCMSDocument *)document atIndex:(int)index {
	NSMutableDictionary *metadataDictSampleCode = [metadata objectAtIndex:0];
	NSMutableDictionary *metadataDictDescription = [metadata objectAtIndex:1];
	NSMutableDictionary *metadataDictPath = [metadata objectAtIndex:2];
	NSMutableDictionary *metadataDictDisplayName = [metadata objectAtIndex:3];
	
	[metadataDictSampleCode setValue:[document valueForKeyPath:@"metadata.sampleCode"] forKey:[NSString stringWithFormat:@"file_%d",index]];
	[metadataDictDescription setValue:[document valueForKeyPath:@"metadata.sampleDescription"] forKey:[NSString stringWithFormat:@"file_%d",index]];
	[metadataDictPath setValue:[document fileName] forKey:[NSString stringWithFormat:@"file_%d",index]];
	[metadataDictDisplayName setValue:[document displayName] forKey:[NSString stringWithFormat:@"file_%d",index]];
	
	NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
	[tableColumn setIdentifier:document];
	[[tableColumn headerCell] setStringValue:[document displayName]];
	NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[NSString stringWithFormat:@"file_%d",index]];
	[tableColumn bind:@"value" toObject:metadataController withKeyPath:keyPath options:nil];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	[[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
	[tableColumn setEditable:NO];
	[metadataTable addTableColumn:tableColumn];
	[tableColumn release];
	return;
}

// Move this method to JKStatisticsDocument
- (void)collectCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index {
	// This autoreleasepool allows to flush the memory after each file, to prevent using more than 2 GB during this loop!
	NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSString *warningMsg;
    NSDictionary *warning;
    
	int j,k;
	int peaksCount, combinedPeaksCount;
	int knownCombinedPeakIndex, peaksCompared;
	BOOL isKnownCombinedPeak, isKnownCompound;
	float scoreResult, maxScoreResult, previousScoreResult;
	NSDate *date = [NSDate date];
    float matchTreshold = [[self matchThreshold] floatValue];

	NSMutableArray *peaksArray = nil;
	JKPeakRecord *peak = nil;
	JKCombinedPeak *combinedPeak = nil;
	JKSpectrum *spectrum = nil;
	JKPeakRecord *previousMatchedPeak = nil;
        
	// Problems!
	//  - should use retention index instead of retention time
	// ?- measurement conditions should be similar e.g. same temp. program
	// \u201a\340\366- comparison to peaks within same chromatogram may occur when peaks within window were added
	// ?- unconfirmed peaks encountered before corresponding confirmed peak won't match
	// ?- no check to see if combined peak already had a match from the same file (highest score should win?)
	// \u201a\340\366- memory usage from opening files is problematic: open/close files on demand?
	
	date = [NSDate date];
	peaksCompared = 0;
	peaksArray = [[[document peaks] filteredArrayUsingPredicate:[self filterPredicate]] mutableCopy];
	peaksCount = [peaksArray count];
	
	// Go through the peaks
	for (j=0; j < peaksCount; j++) {
		peak = [peaksArray objectAtIndex:j];
		isKnownCombinedPeak = NO;
		isKnownCompound = NO;
		
        // Reset symbol, we'll put in the new symbol later if needed
        if (setPeakSymbolToNumber) {
            [peak setSymbol:@""];
        }
        		
		// Match with combined peaks
		combinedPeaksCount = [combinedPeaks count];
		maxScoreResult = 0.0f;
		previousScoreResult = 0.0f; 
        knownCombinedPeakIndex = 0;
        
		// Because the combinedPeaks array is empty, we add all peaks for the first one.
		if (index == 0) {
			isKnownCombinedPeak = NO;
			isKnownCompound = NO;
			if ([peak confirmed] || [peak identified]) {
				isKnownCompound = YES;
			}
		} 
		
		spectrum = [[peak spectrum] normalizedSpectrum];
  
		for (k=0; k < combinedPeaksCount; k++) {
			combinedPeak = [combinedPeaks objectAtIndex:k];
            
            // Check if models match
			if (![[[peak chromatogram] model] isEqualToString:[combinedPeak model]]) {
                continue;
            }
            
            // Check if within maximumRetentionIndexDifference range
            if (fabsf([[peak retentionIndex] floatValue] - [[combinedPeak retentionIndex] floatValue]) > [maximumRetentionIndexDifference floatValue]) {
                continue;
            }
            
			// Match according to label for confirmed  peaks
			if ([peak confirmed]) {
				isKnownCompound = YES;
				
				if ([[peak label] isEqualToString:[combinedPeak label]]) {
					maxScoreResult = 101.0; // confirmed peak!
					isKnownCombinedPeak = YES;
					knownCombinedPeakIndex = k;
					break;
                }
                // Match according to score for identified peaks
            } else if ([peak identified]) {
                isKnownCompound = YES;
                
				if ([[peak label] isEqualToString:[combinedPeak label]]) {
                    scoreResult = [spectrum scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                    peaksCompared++;
                    if (scoreResult > maxScoreResult) {
                        maxScoreResult = scoreResult; 
                        isKnownCombinedPeak = YES;                        
                        knownCombinedPeakIndex = k;
                    }
                }
                // Or if it's an unidentified peak, match according to score    
            } else {
				isKnownCompound = NO;

                scoreResult  = [spectrum scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                peaksCompared++;
                if (scoreResult > matchTreshold) {
                    if (scoreResult > maxScoreResult) {
                        maxScoreResult = scoreResult;
                        isKnownCombinedPeak = YES;
                        knownCombinedPeakIndex = k;						
                    }
                }
            }			
		}

		if (isKnownCombinedPeak) {
 			combinedPeak = [combinedPeaks objectAtIndex:knownCombinedPeakIndex];
            previousMatchedPeak = [combinedPeak valueForKey:[NSString stringWithFormat:@"file_%d",index]];
            if (previousMatchedPeak) {
                previousScoreResult = [[previousMatchedPeak spectrum] scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                
                //JKLogDebug(@"previousScoreResult %g; maxScoreResult %g for peak %@ combinedPeak %@", previousScoreResult, maxScoreResult, [peak label], [combinedPeak label]);
            } else {
                previousScoreResult = 0.0f;
            }
            if (previousScoreResult < maxScoreResult) {
                [combinedPeak setValue:peak forKey:[NSString stringWithFormat:@"file_%d",index]];
                spectrum = [[combinedPeak spectrum] spectrumByAveragingWithSpectrum:[peak spectrum] withWeight:1.0/peaksCount];
                [combinedPeak setSpectrum:spectrum];                
            } else {
                // The previous match was better
                isKnownCombinedPeak = NO;
                // WARNING: A previous peak was matched with a higher score than the current 
                warningMsg = [NSString stringWithFormat:@"WARNING: The previous match (%g) scored better than the current (%g) for peak %@. This can cause doublures of combined peaks with for the same compound.", previousScoreResult, maxScoreResult, [peak label]];
                warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                
            }            
            
            // If the combined peak has a meaningless label, but the new has, replace
            if ([combinedPeak unknownCompound]) {
                if ([peak confirmed]) {
                    // WARNING: A confirmed peak was matched to a hitherto unidentified compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The confirmed peak '%@' at index %d was matched to a hitherto unidentified compound. It was previously encountered", [peak label], [peak peakID]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    if ([[peak label] isEqualToString:@""]) {
                        NSLog(@"ARGH!!1 %@ - %@",[document displayName], [peak description]);
                    }
                    [combinedPeak setLabel:[peak label]];
                    [combinedPeak setLibraryEntry:[peak libraryHit]];
                    [combinedPeak setUnknownCompound:NO];
                    // Should log the peaks that were unidentified
                    NSEnumerator *peakEnumerator = [[combinedPeak peaks] objectEnumerator];
                    JKPeakRecord *oldPeak;
                    
                    while ((oldPeak = [peakEnumerator nextObject]) != nil) {
                        if ([oldPeak document] != document)
                            warningMsg = [warningMsg stringByAppendingFormat:@" in document '%@' as peak %d;", [[oldPeak document] displayName], [oldPeak peakID]];
                    }            
                    warningMsg = [warningMsg substringToIndex:[warningMsg length]-2];
                    warningMsg = [warningMsg stringByAppendingString:@"."];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                    
                } else if ([peak identified]) {
                    // WARNING: An identified peak was matched to a hitherto unidentified compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The identified peak '%@' at index %d was matched to a hitherto unidentified compound. It was previously encountered", [peak label], [peak peakID]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    // Do not change combinedPeak label because not confirmed >> do, because we now have the certainty factor shown
                    if ([[peak label] isEqualToString:@""]) {
                        NSLog(@"ARGH!!2 %@ - %@",[document displayName], [peak description]);
                    }
                    [combinedPeak setLabel:[peak label]];
                    [combinedPeak setLibraryEntry:[peak libraryHit]];
                    [combinedPeak setUnknownCompound:NO];
                    
                    // Should log the peaks that were unidentified
                    NSEnumerator *peakEnumerator = [[combinedPeak peaks] objectEnumerator];
                    JKPeakRecord *oldPeak;
                    
                    while ((oldPeak = [peakEnumerator nextObject]) != nil) {
                        if ([oldPeak document] != document)
                            warningMsg = [warningMsg stringByAppendingFormat:@" in document '%@' as peak %d;", [[oldPeak document] displayName], [oldPeak peakID]];
                    }            
                    warningMsg = [warningMsg substringToIndex:[warningMsg length]-2];
                    warningMsg = [warningMsg stringByAppendingString:@"."];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                } 
                // Nothing to do when matching unknown peak to unknown compound
            } else if (![combinedPeak unknownCompound]) {
                if ((![peak confirmed]) && (![peak identified])) {
                    // WARNING: An unidentified peak was matched to a known compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The unidentified peak %d was matched to the known compound '%@'.", [peak peakID], [combinedPeak valueForKey:@"label"]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];                   
                } else if ((![peak confirmed]) && ([peak identified])) {
                    // WARNING: An unconfirmed peak was matched to a known compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The unconfirmed peak %d was matched to the known compound '%@'.", [peak peakID], [combinedPeak valueForKey:@"label"]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];                   
                }    
                // Nothing to do when matching confirmed peak to known compound
            }
            
		}
        
        if (!isKnownCombinedPeak) {            
            combinedPeak = [[JKCombinedPeak alloc] init];
			if (!isKnownCompound) {
                [combinedPeak setLabel:[NSString stringWithFormat:NSLocalizedString(@"Unknown compound %d ",@"Unknown compounds in stats summary."), unknownCount]];
				unknownCount++;
   			} else {
                if ([[peak label] isEqualToString:@""]) {
                    NSLog(@"ARGH!!3 %@ - %@",[document displayName], [peak description]);
                }
                [combinedPeak setLabel:[peak label]];
                [combinedPeak setLibraryEntry:[peak libraryHit]];
			}            
            [combinedPeak setUnknownCompound:!isKnownCompound];
            [combinedPeak setRetentionIndex:[peak retentionIndex]];
            [combinedPeak setModel:[[peak chromatogram] model]];
            [combinedPeak setSpectrum:[[peak spectrum] normalizedSpectrum]];
            [combinedPeak setValue:peak forKey:[NSString stringWithFormat:@"file_%d",index]];
            [combinedPeak setDocument:[self document]];
            [self insertObject:combinedPeak inCombinedPeaksAtIndex:[self countOfCombinedPeaks]];
            [combinedPeak release];
        }
	} 	
		
    warningMsg = [NSString stringWithFormat:@"INFO: processing time: %.2g s; peaks: %d; peaks compared: %d; combined peaks: %d; speed: %.f peaks/s", -[date timeIntervalSinceNow], peaksCount, peaksCompared, [combinedPeaks count], peaksCompared/-[date timeIntervalSinceNow]];
    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
    
   // JKLogDebug(@"File %d: %@; time: %.2g s; peaks: %d; peaks comp.: %d; comb. peaks: %d; speed: %.f peaks/s",index, [document displayName], -[date timeIntervalSinceNow], peaksCount, peaksCompared, [combinedPeaks count], peaksCompared/-[date timeIntervalSinceNow]);
	
	[subPool release];
}

// Move this method to JKStatisticsDocument
- (void)updateCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index 
{
	// This autoreleasepool allows to flush the memory after each file, to prevent using more than 2 GB during this loop!
	NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
    NSString *warningMsg;
    NSDictionary *warning;
    
	int j,k;
	int peaksCount, combinedPeaksCount;
	int knownCombinedPeakIndex, peaksCompared;
	BOOL isKnownCombinedPeak, isKnownCompound;
    BOOL needsUpdating;
	float scoreResult, maxScoreResult, previousScoreResult;
	NSDate *date = [NSDate date];
    float matchTreshold = [[self matchThreshold] floatValue];
    
	NSMutableArray *peaksArray = nil;
	JKPeakRecord *peak = nil;
	JKCombinedPeak *combinedPeak = nil;
	JKSpectrum *spectrum = nil;
	JKPeakRecord *previousMatchedPeak = nil;
    
	// Problems!
	//  - should use retention index instead of retention time
	// ?- measurement conditions should be similar e.g. same temp. program
	// \u201a\340\366- comparison to peaks within same chromatogram may occur when peaks within window were added
	// ?- unconfirmed peaks encountered before corresponding confirmed peak won't match
	// ?- no check to see if combined peak already had a match from the same file (highest score should win?)
	// \u201a\340\366- memory usage from opening files is problematic: open/close files on demand?
	
	date = [NSDate date];
	peaksCompared = 0;
	peaksArray = [[[document peaks] filteredArrayUsingPredicate:[self filterPredicate]] mutableCopy];
	peaksCount = [peaksArray count];
            
	// Go through the peaks
	for (j=0; j < peaksCount; j++) {
		peak = [peaksArray objectAtIndex:j];
		isKnownCombinedPeak = NO;
		isKnownCompound = NO;
        
		// Match with combined peaks
		combinedPeaksCount = [combinedPeaks count];

        needsUpdating = YES;
        for (k=0; k < combinedPeaksCount; k++) {
            combinedPeak = [combinedPeaks objectAtIndex:k];
            if ([[[combinedPeak peaks] allValues] containsObject:peak]) {
                needsUpdating = NO;
            }              
        }
        if (!needsUpdating) {
            continue;
        } else {
            JKLogDebug(@"Updating for peak %@", peak);
        }
        
		maxScoreResult = 0.0f;
		previousScoreResult = 0.0f; 
        knownCombinedPeakIndex = 0;
        		
		spectrum = [[peak spectrum] normalizedSpectrum];
        
		for (k=0; k < combinedPeaksCount; k++) {
			combinedPeak = [combinedPeaks objectAtIndex:k];
            
            // Check if models match
			if (![[[peak chromatogram] model] isEqualToString:[combinedPeak model]]) {
                continue;
            }
            
            // Check if within maximumRetentionIndexDifference range
            if (fabsf([[peak retentionIndex] floatValue] - [[combinedPeak retentionIndex] floatValue]) > [maximumRetentionIndexDifference floatValue]) {
                continue;
            }
            
			// Match according to label for confirmed  peaks
			if ([peak confirmed]) {
				isKnownCompound = YES;
				
				if ([[peak label] isEqualToString:[combinedPeak label]]) {
                    needsUpdating = NO;
					maxScoreResult = 101.0; // confirmed peak!
					isKnownCombinedPeak = YES;
					knownCombinedPeakIndex = k;
					break;
                }
                // Match according to score for identified peaks
            } else if ([peak identified]) {
                isKnownCompound = YES;
                
				if ([[peak label] isEqualToString:[combinedPeak label]]) {
                    scoreResult = [spectrum scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                    peaksCompared++;
                    if (scoreResult > maxScoreResult) {
                        needsUpdating = NO;
                        maxScoreResult = scoreResult; 
                        isKnownCombinedPeak = YES;                        
                        knownCombinedPeakIndex = k;
                    }
                }
                // Or if it's an unidentified peak, match according to score    
            } else {
				isKnownCompound = NO;
                
                scoreResult  = [spectrum scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                peaksCompared++;
                if (scoreResult > matchTreshold) {
                    if (scoreResult > maxScoreResult) {
                        maxScoreResult = scoreResult;
                        isKnownCombinedPeak = YES;
                        knownCombinedPeakIndex = k;						
                    }
                }
            }			
		}
        
		if (isKnownCombinedPeak) {
 			combinedPeak = [combinedPeaks objectAtIndex:knownCombinedPeakIndex];
            previousMatchedPeak = [combinedPeak valueForKey:[NSString stringWithFormat:@"file_%d",index]];
            if (previousMatchedPeak) {
                previousScoreResult = [[previousMatchedPeak spectrum] scoreComparedToSpectrum:[combinedPeak spectrum] usingMethod:scoreBasis penalizingForRententionIndex:NO];
                
                //JKLogDebug(@"previousScoreResult %g; maxScoreResult %g for peak %@ combinedPeak %@", previousScoreResult, maxScoreResult, [peak label], [combinedPeak label]);
            } else {
                previousScoreResult = 0.0f;
            }
            if (previousScoreResult < maxScoreResult) {
                [combinedPeak setValue:peak forKey:[NSString stringWithFormat:@"file_%d",index]];
                spectrum = [[combinedPeak spectrum] spectrumByAveragingWithSpectrum:[peak spectrum] withWeight:1.0/peaksCount];
                [combinedPeak setSpectrum:spectrum];                
            } else {
                // The previous match was better
                isKnownCombinedPeak = NO;
                // WARNING: A previous peak was matched with a higher score than the current 
                warningMsg = [NSString stringWithFormat:@"WARNING: The previous match (%g) scored better than the current (%g) for peak %@. This can cause doublures of combined peaks with for the same compound.", previousScoreResult, maxScoreResult, [peak label]];
                warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                
            }            
            
            // If the combined peak has a meaningless label, but the new has, replace
            if ([combinedPeak unknownCompound]) {
                if ([peak confirmed]) {
                    // WARNING: A confirmed peak was matched to a hitherto unidentified compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The confirmed peak '%@' at index %d was matched to a hitherto unidentified compound. It was previously encountered", [peak label], [peak peakID]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    if ([[peak label] isEqualToString:@""]) {
                        NSLog(@"ARGH!!1 %@ - %@",[document displayName], [peak description]);
                    }
                    [combinedPeak setLabel:[peak label]];
                    [combinedPeak setLibraryEntry:[peak libraryHit]];
                    [combinedPeak setUnknownCompound:NO];
                    // Should log the peaks that were unidentified
                    NSEnumerator *peakEnumerator = [[combinedPeak peaks] objectEnumerator];
                    JKPeakRecord *oldPeak;
                    
                    while ((oldPeak = [peakEnumerator nextObject]) != nil) {
                        if ([oldPeak document] != document)
                            warningMsg = [warningMsg stringByAppendingFormat:@" in document '%@' as peak %d;", [[oldPeak document] displayName], [oldPeak peakID]];
                    }            
                    warningMsg = [warningMsg substringToIndex:[warningMsg length]-2];
                    warningMsg = [warningMsg stringByAppendingString:@"."];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                    
                } else if ([peak identified]) {
                    // WARNING: An identified peak was matched to a hitherto unidentified compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The identified peak '%@' at index %d was matched to a hitherto unidentified compound. It was previously encountered", [peak label], [peak peakID]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    // Do not change combinedPeak label because not confirmed >> do, because we now have the certainty factor shown
                    if ([[peak label] isEqualToString:@""]) {
                        NSLog(@"ARGH!!2 %@ - %@",[document displayName], [peak description]);
                    }
                    [combinedPeak setLabel:[peak label]];
                    [combinedPeak setLibraryEntry:[peak libraryHit]];
                    [combinedPeak setUnknownCompound:NO];
                    
                    // Should log the peaks that were unidentified
                    NSEnumerator *peakEnumerator = [[combinedPeak peaks] objectEnumerator];
                    JKPeakRecord *oldPeak;
                    
                    while ((oldPeak = [peakEnumerator nextObject]) != nil) {
                        if ([oldPeak document] != document)
                            warningMsg = [warningMsg stringByAppendingFormat:@" in document '%@' as peak %d;", [[oldPeak document] displayName], [oldPeak peakID]];
                    }            
                    warningMsg = [warningMsg substringToIndex:[warningMsg length]-2];
                    warningMsg = [warningMsg stringByAppendingString:@"."];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
                } 
                // Nothing to do when matching unknown peak to unknown compound
            } else if (![combinedPeak unknownCompound]) {
                if ((![peak confirmed]) && (![peak identified])) {
                    // WARNING: An unidentified peak was matched to a known compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The unidentified peak %d was matched to the known compound '%@'.", [peak peakID], [combinedPeak valueForKey:@"label"]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];                   
                } else if ((![peak confirmed]) && ([peak identified])) {
                    // WARNING: An unconfirmed peak was matched to a known compound. 
                    warningMsg = [NSString stringWithFormat:@"WARNING: The unconfirmed peak %d was matched to the known compound '%@'.", [peak peakID], [combinedPeak valueForKey:@"label"]];
                    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];                   
                }    
                // Nothing to do when matching confirmed peak to known compound
            }
            
		}
        
        if (!isKnownCombinedPeak) {            
            combinedPeak = [[JKCombinedPeak alloc] init];
			if (!isKnownCompound) {
                [combinedPeak setLabel:[NSString stringWithFormat:NSLocalizedString(@"Unknown compound %d ",@"Unknown compounds in stats summary."), unknownCount]];
				unknownCount++;
   			} else {
                if ([[peak label] isEqualToString:@""]) {
                    NSLog(@"ARGH!!3 %@ - %@",[document displayName], [peak description]);
                }
                [combinedPeak setLabel:[peak label]];
                [combinedPeak setLibraryEntry:[peak libraryHit]];
			}            
            [combinedPeak setUnknownCompound:!isKnownCompound];
            [combinedPeak setRetentionIndex:[peak retentionIndex]];
            [combinedPeak setModel:[[peak chromatogram] model]];
            [combinedPeak setSpectrum:[[peak spectrum] normalizedSpectrum]];
            [combinedPeak setValue:peak forKey:[NSString stringWithFormat:@"file_%d",index]];
            [combinedPeak setDocument:[self document]];
            [self insertObject:combinedPeak inCombinedPeaksAtIndex:[self countOfCombinedPeaks]];
            [combinedPeak release];
        }
	} 	
    
    warningMsg = [NSString stringWithFormat:@"INFO: processing time: %.2g s; peaks: %d; peaks compared: %d; combined peaks: %d; speed: %.f peaks/s", -[date timeIntervalSinceNow], peaksCount, peaksCompared, [combinedPeaks count], peaksCompared/-[date timeIntervalSinceNow]];
    warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
    [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
    
    // JKLogDebug(@"File %d: %@; time: %.2g s; peaks: %d; peaks comp.: %d; comb. peaks: %d; speed: %.f peaks/s",index, [document displayName], -[date timeIntervalSinceNow], peaksCount, peaksCompared, [combinedPeaks count], peaksCompared/-[date timeIntervalSinceNow]);
	
	[subPool release];
}

// Move this method to JKStatisticsDocument
- (void)doSanityCheckForDocument:(JKGCMSDocument *)document atIndex:(int)index  
{	
	unsigned int i,j;
	unsigned int peaksCount;
    int foundIndex = 0;
     
	NSMutableArray *peaksArray;
	JKPeakRecord *peak;
    NSDictionary *warning;
    NSString *warningMsg;
    NSMutableArray *peakLabels = [[NSMutableArray alloc] init];
    
	peaksArray = [document peaks];
	peaksCount = [peaksArray count];
	
    int lastSymbolEncountered = 0;
    
	// Go through the peaks
	for (j=0; j < peaksCount; j++) {
		peak = [peaksArray objectAtIndex:j];
        if (([peak label]) && (![[peak label] isEqualToString:@""])) {
            foundIndex = NSNotFound;
            for (i = 0; i < [peakLabels count]; i++) {
                if ([[peakLabels objectAtIndex:i] isEqualToString:[peak label]]) {
                    foundIndex = i;
                }
            }
            if (foundIndex == NSNotFound) {
                [peakLabels addObject:[peak label]];
            } else {
                warningMsg = [NSString stringWithFormat:@"WARNING: The peak '%@' at index %d has a label that occurred earlier in the same chromatogram.", [peak label], [peak peakID]];
                warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];            
            }
        }
        if (([peak symbol]) && (![[peak symbol] isEqualToString:@""])) {
            if ([[peak symbol] intValue] < lastSymbolEncountered) {
                if ([[peak label] isEqualToString:@""]) {
                    warningMsg = [NSString stringWithFormat:@"WARNING: The peak with symbol '%@' at index %d was encountered out of the normal or average order of elution.", [peak label], [peak symbol], [peak peakID]];
                } else {
                    warningMsg = [NSString stringWithFormat:@"WARNING: The peak '%@' with symbol '%@' at index %d was encountered out of the normal or average order of elution.", [peak label], [peak symbol], [peak peakID]];
                }
               warning = [NSDictionary dictionaryWithObjectsAndKeys:[document displayName], @"document", warningMsg, @"warning", nil];
                [self insertObject:warning inLogMessagesAtIndex:[self countOfLogMessages]];
            }
            lastSymbolEncountered = [[peak symbol] intValue];
        }
	} 	
	
}

// Move this method to JKStatisticsDocument
- (void)calculateRatiosForDocument:(JKGCMSDocument *)document atIndex:(int)index {
	int j;
	int ratiosCount;
	float result;
	NSMutableDictionary *mutDict = nil;
	NSString *keyPath = nil;
	
	ratiosCount = [ratios count];
	
	for (j=0; j < ratiosCount; j++) {
		if (index == 0) {
			mutDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[ratios objectAtIndex:j] valueForKey:@"name"], @"name", nil];
            [self insertObject:mutDict inRatioValuesAtIndex:[self countOfRatioValues]];
			[mutDict release];
		} else {
			mutDict = [ratioValues objectAtIndex:j];
		}
		result = 0.0;
		result = [[ratios objectAtIndex:j] calculateRatioForKey:[NSString stringWithFormat:@"file_%d",index] inCombinedPeaksArray:combinedPeaks];
		[mutDict setValue:[NSNumber numberWithFloat:result] forKey:[NSString stringWithFormat:@"file_%d",index]];
	}

    // Create and insert table column
	NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
	[tableColumn setIdentifier:document];
	[[tableColumn headerCell] setStringValue:[document displayName]];
	keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[NSString stringWithFormat:@"file_%d",index]];
	[tableColumn bind:@"value" toObject:ratiosValuesController withKeyPath:keyPath options:nil];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
	[formatter setFormatterBehavior:NSNumberFormatterPercentStyle];
	[formatter setPositiveFormat:@"#0.0 %"];
	[formatter setLocalizesFormat:YES];
	[[tableColumn dataCell] setFormatter:formatter];
	[formatter release];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:NO];
	[ratiosTable addTableColumn:tableColumn];
	[tableColumn release];
	
	return;
}

- (void)sortCombinedPeaks {
    NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
																			ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObjects:retentionIndexDescriptor,nil];
	[[self combinedPeaks] sortUsingDescriptors:sortDescriptors];
	[retentionIndexDescriptor release];
    
	return;
}

- (void)searchMissingPeaksInCombinedPeak:(JKCombinedPeak *)combinedPeak {
    JKChromatogram *chromatogramToSearch = nil;
    int filesCount = [[self files] count];
    int i;
    JKGCMSDocument *document = nil;
    NSError *error = [[NSError alloc] init];

    //    float minimumScoreSearchResultsF = [[document minimumScoreSearchResults] floatValue];
    
    if ([combinedPeak unknownCompound]) {
        // Add result to combinedPEak
        NSEnumerator *peakEnum = [[combinedPeak peaks] objectEnumerator];
        JKPeakRecord *peak;
        
        while ((peak = [peakEnum nextObject]) != nil) {
            if ([peak confirmed]) {
                break;
            }
        }
        if (peak) {
            [combinedPeak setLibraryEntry:[peak libraryHit]];
            [combinedPeak setLabel:[[peak libraryHit] name]];
            [combinedPeak setUnknownCompound:NO];
        } else {
            NSRunInformationalAlertPanel(@"Finding missing peaks not possible",@"To find missing peaks identify and confirm at least one peak in the selected combined peak.",@"OK",nil,nil);
            return;
        }  
        
    }
    
    for (i = 0; i < filesCount; i++) {
        // do we have a peak for earch file?
        if (![combinedPeak valueForKey:[NSString stringWithFormat:@"file_%d",i]]) {
            // open document if not already open and get a reference
            document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:YES error:&error];
            if (!document) {
                // maybe try to determine cause of error and recover first
                NSAlert *theAlert = [NSAlert alertWithError:error];
                [theAlert runModal]; // ignore return value
            }

            [[document undoManager] disableUndoRegistration];
            NSNumber *orignalMinimumScoreSearchResults = [document minimumScoreSearchResults];
            NSNumber *orignalMarkAsIdentifiedThreshold = [document markAsIdentifiedThreshold];
            [document setMinimumScoreSearchResults:[NSNumber numberWithFloat:0.0f]];
            [document setMarkAsIdentifiedThreshold:[NSNumber numberWithFloat:0.0f]];
            [[document undoManager] enableUndoRegistration];

            // obtain the chromatogram we need
            chromatogramToSearch = [document chromatogramForModel:[combinedPeak model]];
#warning [?] Is the right behavior?
            [[combinedPeak libraryEntry] setRetentionIndex:[combinedPeak retentionIndex]];
            [document performBackwardSearchForChromatograms:[NSArray arrayWithObject:chromatogramToSearch] withLibraryEntries:[NSArray arrayWithObject:[combinedPeak libraryEntry]] maximumRetentionIndexDifference:[maximumRetentionIndexDifference floatValue]];
            
            // Add result to combinedPEak
            NSEnumerator *peakEnum = [[chromatogramToSearch peaks] objectEnumerator];
            JKPeakRecord *peak;

            while ((peak = [peakEnum nextObject]) != nil) {
            	if ([[peak libraryHit] isEqualTo:[combinedPeak libraryEntry]]) {
                    break;
                }
            }
            if (peak) {
                [combinedPeak setValue:peak forKey:[NSString stringWithFormat:@"file_%d",i]];
            }     
            [[document undoManager] disableUndoRegistration];
            [document setMinimumScoreSearchResults:orignalMinimumScoreSearchResults];
            [document setMarkAsIdentifiedThreshold:orignalMarkAsIdentifiedThreshold];
            [[document undoManager] enableUndoRegistration];
        }
    }
    [error release];
}

//-(void)sortColumns {
//    int i,j, result;
//	NSArray *tableColumns = [metadataTable tableColumns];
//	id tableColumn1 = nil;
//	id tableColumn2 = nil;
//	int columnCount = [[metadataTable tableColumns] count];
//    
//    for (i=0; i < columnCount; i++) {
//        tableColumn1 = [tableColumns objectAtIndex:i];
//        if ([[tableColumn1 identifier] isKindOfClass:[JKGCMSDocument class]])  {
//            for (j=0; j < columnCount; j++) {
//                tableColumn2 = [tableColumns objectAtIndex:j];
//                if ([[tableColumn2 identifier] isKindOfClass:[JKGCMSDocument class]])  {
//                    result = [[tableColumn1 identifier] metadataCompare:[tableColumn2 identifier]];
//                    if (result == NSOrderedAscending) {
//                        NSLog(@"NSOrderedAscending");
//                        if (i > j)
//                            [metadataTable moveColumn:j toColumn:i]; 
//                        //[metadataTable moveColumn:i toColumn:j]; 
//                    } else if (result == NSOrderedSame) {
//                        NSLog(@"NSOrderedSame");
//                        if (i-j > 1) {
//                            [metadataTable moveColumn:j toColumn:i]; 
//                        } else if (i-j < -1) {
//                            [metadataTable moveColumn:i toColumn:j];                            
//                        }
//                    } else if (result == NSOrderedDescending) {
//                        NSLog(@"NSOrderedDescending");
//                        if (i > j)
//                            [metadataTable moveColumn:j toColumn:i]; 
//                    }
//                }
//            }
//        }
//	}
//}
//

- (void)saveRatiosFile {
	NSArray *paths;
	
	paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
	if ([paths count] > 0)  { 
		NSString *destPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Peacock/Ratios.plist"];
		if(![NSKeyedArchiver archiveRootObject:ratios toFile:destPath])
			JKLogError(@"Error saving Ratios.plist file.");
    }
}

- (void)insertTableColumns {
	int i;
	int filesCount = [files count];

//	NSError *error = [[NSError alloc] init];
	NSDocument *document;
	
	// Remove all but the first four column from the tableview
	int columnCount = [metadataTable numberOfColumns];
	for (i = columnCount-1; i > 3; i--) {
		[metadataTable removeTableColumn:[[metadataTable tableColumns] objectAtIndex:i]];
	} 
	columnCount = [resultsTable numberOfColumns];
	for (i = columnCount-1; i > 3; i--) {
		[resultsTable removeTableColumn:[[resultsTable tableColumns] objectAtIndex:i]];
	} 
	
	columnCount = [ratiosTable numberOfColumns];
	for (i = columnCount-1; i > 3; i--) {
		[ratiosTable removeTableColumn:[[ratiosTable tableColumns] objectAtIndex:i]];
	} 
	
	NSTableColumn *tableColumn;
	NSString *keyPath;
	NSNumberFormatter *formatter;
	for (i=0; i < filesCount; i++) {
		document = [[NSDocumentController sharedDocumentController] documentForURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]]];
        // If document not open, ignore...
        if (!document) continue;
        
		tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[NSString stringWithFormat:@"file_%d",i]];
		[[tableColumn headerCell] setStringValue:[[metadata objectAtIndex:3] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		[tableColumn bind:@"value" toObject:metadataController withKeyPath:keyPath options:nil];
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		[[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
		[tableColumn setEditable:NO];
		[metadataTable addTableColumn:tableColumn];
		[tableColumn release];
		
		// Combined peaks
		tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		[[tableColumn headerCell] setStringValue:[document displayName]];
        NSString *keyPath;
        switch (valueToUse) {
            case 1:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.normalizedHeight",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 2:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.retentionIndex",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 3:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.topTime",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 4:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.top",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 5:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.surface",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 6:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.height",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 7:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.width",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 8:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.score",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 9:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.identified",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 10:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.confirmed",[NSString stringWithFormat:@"file_%d",i]];
                break;
            case 0:
            default:
                keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.normalizedSurface",[NSString stringWithFormat:@"file_%d",i]];
                break;
        }
		[[tableColumn headerCell] setStringValue:[document displayName]];
		[tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		formatter = [[[NSNumberFormatter alloc] init] autorelease];
		[formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
		[formatter setPositiveFormat:@"#0.0"];
		[formatter setLocalizesFormat:YES];
		[[tableColumn dataCell] setFormatter:formatter];
		[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
		[tableColumn setEditable:NO];
		[resultsTable addTableColumn:tableColumn];
		[tableColumn release];
		
		// Ratios
		tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		[[tableColumn headerCell] setStringValue:[document displayName]];
		keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[NSString stringWithFormat:@"file_%d",i]];
		[[tableColumn headerCell] setStringValue:[[metadata objectAtIndex:3] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		[tableColumn bind:@"value" toObject:ratiosValuesController withKeyPath:keyPath options:nil];
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		formatter = [[NSNumberFormatter alloc] init];
		[formatter setFormatterBehavior:NSNumberFormatterPercentStyle];
		[formatter setPositiveFormat:@"#0.0 %"];
		[formatter setLocalizesFormat:YES];
		[[tableColumn dataCell] setFormatter:formatter];
		[formatter release];
		[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
		[tableColumn setEditable:NO];
		[ratiosTable addTableColumn:tableColumn];
		[tableColumn release];
    }
	
//	// Finishing
//	[self sortColumns];
}
- (void)insertGraphDataSeries {
	int i;
	int filesCount = [files count];
    
    //	NSError *error = [[NSError alloc] init];
	NSDocument *document;
	
	for (i=0; i < filesCount; i++) {
		document = [[NSDocumentController sharedDocumentController] documentForURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]]];
        // If document not open, ignore...
        if (!document) continue;
        
        [self setupComparisonWindowForDocument:(JKGCMSDocument *)document atIndex:i];
    }
}

- (void)setupComparisonWindowForDocument:(JKGCMSDocument *)document atIndex:(int)index{
//    NSEnumerator *chromatogramEnum = [[[document chromatograms] objectEnumerator];
    JKChromatogram *chromatogram = [[document chromatograms] objectAtIndex:0]; // TIC only!!

//    while ((chromatogram = [chromatogramEnum nextObject]) != nil) {
        ChromatogramGraphDataSerie *cgds = [[[ChromatogramGraphDataSerie alloc] initWithChromatogram:chromatogram] autorelease];
        // sets title to "filename: code - description (model)"
        [cgds setSeriesTitle:[NSString stringWithFormat:@"%@: %@ - %@ (%@)", [document displayName], [[metadata objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",index]],[[metadata objectAtIndex:1] valueForKey:[NSString stringWithFormat:@"file_%d",index]],[chromatogram model]]];
        [cgds setFilterPredicate:[self filterPredicate]];
    	[chromatogramDataSeriesController addObject:cgds];
//    }
    [peaksController addObjects:[document peaks]];
}

- (void)synchronizedZooming:(NSNotification *)theNotification{
	
		NSEnumerator *enumerator = [[[comparisonScrollView documentView] subviews] objectEnumerator];
		id subview;
		NSNumber *newXMinimum = [[theNotification userInfo] valueForKey:@"newXMinimum"];
		NSNumber *newXMaximum = [[theNotification userInfo] valueForKey:@"newXMaximum"];
		
		while ((subview = [enumerator nextObject])) {
			[subview setXMinimum:newXMinimum];
			[subview setXMaximum:newXMaximum];
		}
}

// Move this method to JKStatisticsDocument
- (NSPredicate *)filterPredicate {
    switch (peaksToUse) {
    case 0: // All peaks
        return [NSPredicate predicateWithFormat:@"(identified == YES) OR (identified == NO)"];
        break;
    case 1: // JKIdenitifiedPeaks
        return [NSPredicate predicateWithFormat:@"identified == YES"];
        break;
    case 2: // JKUnidenitifiedPeaks
        return [NSPredicate predicateWithFormat:@"identified == NO"];
        break;
    case 3: // JKConfirmedPeaks
        return [NSPredicate predicateWithFormat:@"confirmed == YES"];
        break;
    case 4: // JKUnconfirmedPeaks
        return [NSPredicate predicateWithFormat:@"(identified == YES) AND (confirmed == NO)"];
        break;
    default:
        break;
    }
    return nil;
}
#pragma mark -

#pragma mark IBActions
- (IBAction)addButtonAction:(id)sender {
	NSArray *fileTypes = [NSArray arrayWithObjects:@"peacock",nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
	[oPanel beginSheetForDirectory:nil file:nil types:fileTypes modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)repopulate:(id)sender {
    [self insertTableColumns];
}

- (IBAction)repopulateContextMenuAction:(id)sender {
    valueToUse = [sender tag];
    [self insertTableColumns];
}

- (IBAction)doubleClickAction:(id)sender {
	NSError *error = [[[NSError alloc] init] autorelease];
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
	} else if ([sender clickedColumn] == 1) {
		return;
	} else if ([sender clickedColumn] == 2) {
		return;
	} else if ([sender clickedColumn] == 3) {
		return;
	} else if ([sender clickedRow] == -1) {
		// A column was double clicked
		// Bring forward the associated file
		//[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] window] makeKeyAndOrderFront:self];
		//JKLogDebug([[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-1]]);
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-4]]] display:YES error:&error];
	} else {
		// A cell was double clicked
		// Bring forwars associated file and
		// select associated peak
		JKGCMSDocument *document;

        if ([NSEvent isOptionKeyDown]) {
            JKCombinedPeak *combiPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]];
            NSString *key = [NSString stringWithFormat:@"file_%d",[sender clickedColumn]-4];
            [combiPeak setValue:nil forKey:key];
        } else {
            // Which document?
            NSURL *url = [NSURL fileURLWithPath:[[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-4]]];
            document = [[NSDocumentController sharedDocumentController] documentForURL:url];
            // Open document if not yet open
            if (!document) {
                document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
            }
            // Select peaks
            int index, i, combinedPeaksCount = [[combinedPeaksController selectedObjects] count];
            JKPeakRecord *peak = nil;
            for (i = 0; i < combinedPeaksCount; i++) {
                NSEnumerator *peaksEnumerator = [[[[combinedPeaksController selectedObjects] objectAtIndex:i] peaks] objectEnumerator];		
                while ((peak = [peaksEnumerator nextObject])) {
                    //if ([[peak label] isEqualToString:[peakInDocument label]]
                    index = [[[[document mainWindowController] peakController] arrangedObjects] indexOfObjectIdenticalTo:peak];
                    if (index != NSNotFound) {
                        [[[document mainWindowController] peakController] setSelectionIndex:index];
                    } 
                }
            }
            // Bring document to front
            [[[document mainWindowController] window] makeKeyAndOrderFront:self];  
        }
 	}
}

- (IBAction)options:(id)sender {
	[NSApp beginSheet: optionsSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop		
}

- (IBAction)summarizeOptionsDoneAction:(id)sender {
	[NSApp endSheet:summarizeOptionsSheet];
}

- (IBAction)runStatisticalAnalysisButtonAction:(id)sender {
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	//[self runStatisticalAnalysis];
	[NSThread detachNewThreadSelector:@selector(runStatisticalAnalysis) toTarget:self withObject:nil];
	
}

- (IBAction)updateStatisticalAnalysisButtonAction:(id)sender {
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	//[self runStatisticalAnalysis];
	[NSThread detachNewThreadSelector:@selector(updateCombinedPeaks) toTarget:self withObject:nil];
	
}

- (IBAction)stopButtonAction:(id)sender {
	[self setAbortAction:YES];
    [NSApp endSheet:progressSheet];
}

- (IBAction)editRatios:(id)sender {
	[NSApp beginSheet: ratiosEditor
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop	
	
}

- (IBAction)cancelEditRatios:(id)sender {
	[NSApp endSheet:ratiosEditor];

}

- (IBAction)saveEditRatios:(id)sender {
	[self saveRatiosFile];
	[NSApp endSheet:ratiosEditor];
}


- (IBAction)exportSummary:(id)sender {
    if (rerunNeeded) {
        int answer = NSRunInformationalAlertPanel(NSLocalizedString(@"Rerun needed",@""),NSLocalizedString(@"You need to rerun the statistical analysis before exporting, because files were added after the last run.",@""),NSLocalizedString(@"Rerun Now",@""),NSLocalizedString(@"Cancel",@""),NSLocalizedString(@"Ignore",@""));
        if (answer == NSOKButton) {
            [self runStatisticalAnalysisButtonAction:self];
            return;
        } else if (answer == NSCancelButton) {
            return;
        } else {
            // Ignore...
        }
    }
	NSSavePanel *sp;
	int runResult;
	
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	
	/* set up new attributes */
	[sp setRequiredFileType:@"txt"];
	
	/* display the NSSavePanel */
	runResult = [sp runModalForDirectory:nil file:@""];
	
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		NSMutableString *outStr = [[NSMutableString alloc] init]; 
//		NSMutableString *outStr = [NSMutableString stringWithCString:"\t"];
		int i,j;
//		int fileCount = [[[self metadata] objectAtIndex:0] count]-1; incorrect because metadata can be empty
        int fileCount = [[self files] count];
		int compoundCount = [combinedPeaks count];
		NSString *normalizedSurface;
		NSString *normalizedHeight;
        NSString *retentionTime;
        
		// Sort array
		NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
																			   ascending:YES];
		NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
		[combinedPeaks sortUsingDescriptors:sortDescriptors];
		[retentionIndexDescriptor release];
		
		[outStr appendString:@"Sample code\t\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) {
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]] ];
		}
		[outStr appendString:@"\n"];

		[outStr appendString:@"Sample description\t\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) {
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:1] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		
		[outStr appendString:@"File path\t\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) {
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		
		[outStr appendString:@"\nNormalized height\n#\tCompound\tCertainty\tCount\tAverage retention index\tStandard deviation retention index\tAverage height\tStandard deviation height"];
		for (i=0; i < fileCount; i++) { // Sample code
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		for (j=0; j < compoundCount; j++) {
			[outStr appendFormat:@"%d\t", j+1];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"label"]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"certainty"]];
			[outStr appendFormat:@"%d\t", [[[[self combinedPeaks] objectAtIndex:j] valueForKey:@"compoundCount"] intValue]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageRetentionIndex"]];
			[outStr appendFormat:@"%@\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationRetentionIndex"]];
			[outStr appendFormat:@"%@\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageHeight"]];
			[outStr appendFormat:@"%@",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationHeight"]];
			for (i=0; i < fileCount; i++) {
				normalizedHeight = [[[[[self combinedPeaks] objectAtIndex:j] valueForKey:[NSString stringWithFormat:@"file_%d",i]] valueForKey:@"normalizedHeight"] stringValue];
				if (normalizedHeight != nil) {
					[outStr appendFormat:@"\t%@", normalizedHeight];					
				} else {
					[outStr appendString:@"\t-"];										
				}
			}
			[outStr appendString:@"\n"];
		}
		
		[outStr appendString:@"\nNormalized surface\n#\tCompound\tCertainty\tCount\tAverage retention index\tStandard deviation retention index\tAverage surface\tStandard deviation surface"];
		for (i=0; i < fileCount; i++) { // Sample code
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		for (j=0; j < compoundCount; j++) {
			[outStr appendFormat:@"%d\t", j+1];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"label"]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"certainty"]];
			[outStr appendFormat:@"%d\t", [[[[self combinedPeaks] objectAtIndex:j] valueForKey:@"compoundCount"] intValue]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageRetentionIndex"]];
			[outStr appendFormat:@"%@\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationRetentionIndex"]];
			[outStr appendFormat:@"%@\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageSurface"]];
			[outStr appendFormat:@"%@",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationSurface"]];
			for (i=0; i < fileCount; i++) {
				normalizedSurface = [[[[[self combinedPeaks] objectAtIndex:j] valueForKey:[NSString stringWithFormat:@"file_%d",i]] valueForKey:@"normalizedSurface"] stringValue];
				if (normalizedSurface != nil) {
					[outStr appendFormat:@"\t%@", normalizedSurface];					
				} else {
					[outStr appendString:@"\t-"];										
				}
			}
			[outStr appendString:@"\n"];
		}
		
		[outStr appendString:@"\nRetention time\n#\t\tCertainty\tCount\tAverage retention index\tStandard deviation retention index\t\t"];
		for (i=0; i < fileCount; i++) { // Sample code
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		for (j=0; j < compoundCount; j++) {
			[outStr appendFormat:@"%d\t", j+1];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"label"]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"certainty"]];
			[outStr appendFormat:@"%d\t", [[[[self combinedPeaks] objectAtIndex:j] valueForKey:@"compoundCount"] intValue]];
			[outStr appendFormat:@"%@\t", [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageRetentionIndex"]];
			[outStr appendFormat:@"%@\t\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationRetentionIndex"]];
//			[outStr appendFormat:@"%@\t",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"averageSurface"]];
//			[outStr appendFormat:@"%@",   [[[self combinedPeaks] objectAtIndex:j] valueForKey:@"standardDeviationSurface"]];
			for (i=0; i < fileCount; i++) {
				retentionTime = [[[[[self combinedPeaks] objectAtIndex:j] valueForKey:[NSString stringWithFormat:@"file_%d",i]] valueForKey:@"topTime"] stringValue];
				if (normalizedSurface != nil) {
					[outStr appendFormat:@"\t%@", retentionTime];					
				} else {
					[outStr appendString:@"\t-"];										
				}
			}
			[outStr appendString:@"\n"];
		}
		
        if (calculateRatios) {
            int ratiosCount = [ratios count];
            [outStr appendString:@"\nRatios\nLabel\t\t\t\t\t\t\t"];
            for (i=0; i < fileCount; i++) { // Sample code
                [outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
            }
            [outStr appendString:@"\n"];
            for (j=0; j < ratiosCount; j++) {
                [outStr appendFormat:@"%@\t\t\t\t\t\t\t", [[[self ratios] objectAtIndex:j] valueForKey:@"name"]];
                for (i=0; i < fileCount; i++) {
                    [outStr appendFormat:@"\t%@", [[[self ratioValues] objectAtIndex:j] valueForKey:[NSString stringWithFormat:@"file_%d.ratioResult",i]] ];
                }
                [outStr appendString:@"\n"];
            }            
        }

		if (![outStr writeToFile:[sp filename] atomically:YES encoding:NSUTF8StringEncoding error:NULL])
			NSBeep();
	}
}

- (IBAction)searchMissingPeaks:(id)sender {
    NSEnumerator *combinedPeakEnumerator = [[combinedPeaksController selectedObjects] objectEnumerator];
    JKCombinedPeak *combinedPeak;

    while ((combinedPeak = [combinedPeakEnumerator nextObject]) != nil) {
    	[self searchMissingPeaksInCombinedPeak:combinedPeak];
    }
    [[self window] orderFront:self];
}

- (IBAction)next:(id)sender {
	int i;
	if (([combinedPeaksController selectionIndex] != NSNotFound) && ([combinedPeaksController selectionIndex] < [[combinedPeaksController arrangedObjects] count]-1)){
		i = [combinedPeaksController selectionIndex]; 
		[combinedPeaksController setSelectionIndex:i+1]; 
	} else {
		[combinedPeaksController setSelectionIndex:0]; 
	}
}

- (IBAction)previous:(id)sender {
	int i;
	if (([combinedPeaksController selectionIndex] != NSNotFound) && ([combinedPeaksController selectionIndex] > 0)){
		i = [combinedPeaksController selectionIndex]; 
		[combinedPeaksController setSelectionIndex:i-1]; 
	} else {
		[combinedPeaksController setSelectionIndex:[[combinedPeaksController arrangedObjects] count]-1]; 
	}
}

- (IBAction)confirm:(id)sender {
	NSEnumerator *enumerator = [[combinedPeaksController selectedObjects] objectEnumerator];
	id combinedPeak;
	
	while ((combinedPeak = [enumerator nextObject])) {
        [combinedPeak confirm];
	}
}

- (IBAction)combinePeaksAction:(id)sender {
    int count = [[combinedPeaksController selectedObjects] count];
    if (count == 2) {
        JKCombinedPeak *firstPeak = [[combinedPeaksController selectedObjects] objectAtIndex:0];
        JKCombinedPeak *secondPeak = [[combinedPeaksController selectedObjects] objectAtIndex:1];
        if ([[firstPeak model] isEqualToString:[secondPeak model]]) {
            [[[self document] undoManager] setActionName:NSLocalizedString(@"Combine Peaks",@"")];
            if ([firstPeak unknownCompound]) {
                [[secondPeak peaks] addEntriesFromDictionary:[firstPeak peaks]];
                [combinedPeaks removeObject:firstPeak];
               // [self removeObjectFromCombinedPeaksAtIndex:[combinedPeaks indexOfObject:firstPeak]];
            } else{
                [[firstPeak peaks] addEntriesFromDictionary:[secondPeak peaks]];
                [combinedPeaks removeObject:secondPeak];
                // [self removeObjectFromCombinedPeaksAtIndex:[combinedPeaks indexOfObject:secondPeak]];
            }
        } else {
            NSBeep();
        }
    } else {
        NSBeep();
    }
}
#pragma mark -

#pragma mark Key Value Observation
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
//    int i,combinedPeaksCount;
//    id document;
//    NSEnumerator *enumerator = nil;
//    NSEnumerator *peaksEnumerator = nil;
//    JKPeakRecord *peak = nil;
//     
//	if ((object == combinedPeaksController) && ([combinedPeaksController selection] != NSNoSelectionMarker)) {
//        combinedPeaksCount = [[combinedPeaksController selectedObjects] count];;
//        for (i = 0; i < combinedPeaksCount; i++) {
//            peaksEnumerator = [[[[combinedPeaksController selectedObjects] objectAtIndex:i] peaks] objectEnumerator];		
//            while ((peak = [peaksEnumerator nextObject])) {
//                    enumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
//                    
//                    while ((document = [enumerator nextObject]) != nil) {
//                    	if ([document isKindOfClass:[JKGCMSDocument class]]) {
//                            if ([[[[document mainWindowController] peakController] arrangedObjects] containsObject:peak]) {
//                                [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:peak]];
//                            } 
//                        }
//                    }
//                }
//            }	
//    } else if ((object == combinedPeaksController) && ([combinedPeaksController selection] == NSNoSelectionMarker)) {
//        enumerator = [[[NSDocumentController sharedDocumentController] documents] objectEnumerator];
//        
//        while ((document = [enumerator nextObject]) != nil) {
//            if ([document isKindOfClass:[JKGCMSDocument class]]) {
//                [[[document mainWindowController] peakController] setSelectedObjects:nil];
//            }
//        }
//    }
}
#pragma mark -

#pragma mark Synchronized Scrolling
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn {
	if ([[aTableColumn identifier] isKindOfClass:[NSString class]]) {
		return NO;
	} else {
		return YES;
	}
}

- (void)scrollViewBoundsDidChange:(NSNotification *)aNotification {
	NSView *clipView;
	clipView = [aNotification object];
	if (!scrollingViewProgrammatically) {
		if (clipView == [resultsTable superview]) {
			scrollingViewProgrammatically = YES;
			NSRect rect = [[ratiosTable headerView] bounds];
			rect.origin.x = [[resultsTable superview] bounds].origin.x;
			[(NSClipView *)[ratiosTable superview] scrollToPoint:rect.origin];
			[[ratiosTable headerView] setBounds:rect];
			[[ratiosTable headerView] setNeedsDisplay:YES];
			scrollingViewProgrammatically = YES;
			rect = [[metadataTable headerView] bounds];
			rect.origin.x = [[resultsTable superview] bounds].origin.x;
			[(NSClipView *)[metadataTable superview] scrollToPoint:rect.origin];
			[[metadataTable headerView] setBounds:rect];
			[[metadataTable headerView] setNeedsDisplay:YES];
		} else if (clipView == [ratiosTable superview]) {
			scrollingViewProgrammatically = YES;
			NSRect rect = [[resultsTable headerView] bounds];
			rect.origin.x = [[ratiosTable superview] bounds].origin.x;
			[(NSClipView *)[resultsTable superview] scrollToPoint:rect.origin];
			[[resultsTable headerView] setBounds:rect];
			[[resultsTable headerView] setNeedsDisplay:YES];
			scrollingViewProgrammatically = YES;
			rect = [[metadataTable headerView] bounds];
			rect.origin.x = [[ratiosTable superview] bounds].origin.x;
			[(NSClipView *)[metadataTable superview] scrollToPoint:rect.origin];
			[[metadataTable headerView] setBounds:rect];
			[[metadataTable headerView] setNeedsDisplay:YES];
		} else if (clipView == [metadataTable superview]) {
			scrollingViewProgrammatically = YES;
			NSRect rect = [[resultsTable headerView] bounds];
			rect.origin.x = [[metadataTable superview] bounds].origin.x;
			[(NSClipView *)[resultsTable superview] scrollToPoint:rect.origin];
			[[resultsTable headerView] setBounds:rect];
			[[resultsTable headerView] setNeedsDisplay:YES];
			scrollingViewProgrammatically = YES;
			rect = [[ratiosTable headerView] bounds];
			rect.origin.x = [[metadataTable superview] bounds].origin.x;
			[(NSClipView *)[ratiosTable superview] scrollToPoint:rect.origin];
			[[ratiosTable headerView] setBounds:rect];
			[[ratiosTable headerView] setNeedsDisplay:YES];
		}
		
	}
	scrollingViewProgrammatically = NO;	
}

- (void)tableViewColumnDidMove:(NSNotification *)aNotification {
	NSTableView *tableView;
	tableView = [aNotification object];
	if (!movingColumnsProgramatically) {
		if (tableView == resultsTable) {
			movingColumnsProgramatically = YES;
			[ratiosTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
			movingColumnsProgramatically = YES;
			[metadataTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
		} else if (tableView == ratiosTable) {
			movingColumnsProgramatically = YES;
			[resultsTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
			movingColumnsProgramatically = YES;
			[metadataTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
		} else if (tableView == metadataTable) {
			movingColumnsProgramatically = YES;
			[ratiosTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
			movingColumnsProgramatically = YES;
			[resultsTable moveColumn:[[[aNotification userInfo] valueForKey:@"NSOldColumn"] intValue] toColumn:[[[aNotification userInfo] valueForKey:@"NSNewColumn"] intValue]];
		}
	}
	movingColumnsProgramatically = NO;	
}

- (void)tableViewColumnDidResize:(NSNotification *)aNotification {
	NSTableView *tableView;
	tableView = [aNotification object];
	if (!movingColumnsProgramatically) {
		if (tableView == resultsTable) {
			[[ratiosTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
			[[metadataTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
		} else if (tableView == ratiosTable) {
			[[resultsTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
			[[metadataTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
		} else if (tableView == metadataTable) {
			[[resultsTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
			[[ratiosTable tableColumnWithIdentifier:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] identifier]] setWidth:[[[aNotification userInfo] valueForKey:@"NSTableColumn"] width]];
		}
	}
}

- (void)tableView:(NSTableView *)tableView didDragTableColumn:(NSTableColumn *)tableColumn {
	[resultsTable moveColumn:[resultsTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[ratiosTable moveColumn:[ratiosTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[metadataTable moveColumn:[metadataTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[resultsTable moveColumn:[resultsTable columnWithIdentifier:@"model"] toColumn:1];
	[ratiosTable moveColumn:[ratiosTable columnWithIdentifier:@"model"] toColumn:1];
	[metadataTable moveColumn:[metadataTable columnWithIdentifier:@"model"] toColumn:1];
	[resultsTable moveColumn:[resultsTable columnWithIdentifier:@"certainty"] toColumn:2];
	[ratiosTable moveColumn:[ratiosTable columnWithIdentifier:@"certainty"] toColumn:2];
	[metadataTable moveColumn:[metadataTable columnWithIdentifier:@"certainty"] toColumn:2];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex {
	if (aTableView == metadataTable) {
		return NO;
	} else {
		return YES;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
	NSTableView *tableView;
	tableView = [aNotification object];
	if ([tableView selectedColumn] == NSNotFound) {
		if (tableView == ratiosTable) {
//			NSArray *selectedRatios = [ratiosController selectedObjects];
//			
//			for ([selectedRatios 
			
		}
		return;
	}
	if (!movingColumnsProgramatically) {
		if (tableView == resultsTable) {
			[ratiosTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
			[metadataTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
		} else if (tableView == ratiosTable) {
			[resultsTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
			[metadataTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
		} else if (tableView == metadataTable) {
			[ratiosTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
			[resultsTable selectColumnIndexes:[tableView selectedColumnIndexes] byExtendingSelection:NO];
		}
	}
}
#pragma mark -

#pragma mark Sheets
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if (returnCode == NSOKButton) {
        BOOL hadFilesAlready = NO;
        if ([files count] > 0) {
            hadFilesAlready = YES;
        }
		BOOL alreadyInFiles;
        NSArray *filesToOpen = [sheet filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
			alreadyInFiles = NO;
            NSString *aFile = [filesToOpen objectAtIndex:i];
			NSEnumerator *enumerator = [files objectEnumerator];
			id anObject;
			
			while ((anObject = [enumerator nextObject])) {
				if ([[anObject valueForKey:@"path"] isEqualToString:aFile])
					alreadyInFiles = YES;
			}
			if (!alreadyInFiles) {
				NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
				[mutDict setValue:[aFile lastPathComponent] forKey:@"filename"];
				[mutDict setValue:aFile forKey:@"path"];
                [mutDict setObject:[BDAlias aliasWithPath:aFile] forKey:@"alias"];
				[mutDict setObject:[[NSWorkspace sharedWorkspace] iconForFile:aFile] forKey:@"icon"];
				[self willChangeValueForKey:@"files"];
				[files addObject:mutDict];
				[self didChangeValueForKey:@"files"];
				[mutDict release];			
                rerunNeeded = YES;
			}
		}
        if (rerunNeeded && hadFilesAlready) {
            int answer = NSRunInformationalAlertPanel(NSLocalizedString(@"Rerun needed",@""),NSLocalizedString(@"You need to rerun the statistical analysis to reflect the newly added files.",@""),NSLocalizedString(@"Rerun Now",@""),NSLocalizedString(@"Ignore",@""),nil);
            if (answer == NSOKButton) {
                [self runStatisticalAnalysisButtonAction:self];
                return;
            } else if (answer == NSCancelButton) {
                return;
            } else {
                // Ignore...
            }
        }
        
	}	
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)windowWillBeginSheet:(NSNotification *)notification {
	return;
}

- (void)windowDidEndSheet:(NSNotification *)notification {
	return;
}
#pragma mark -

#pragma mark Menu Validation
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([anItem action] == @selector(repopulateContextMenuAction:)) {
		if ([anItem tag] == valueToUse) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}
#pragma mark -

#pragma mark Undo
- (NSUndoManager*)undoManager
{
    return [[self document] undoManager];
}
#pragma mark -

#pragma mark Accessors
#pragma mark (to many relationships)
// Mutable To-Many relationship files
- (NSMutableArray *)files {
	return files;
}

- (void)setFiles:(NSMutableArray *)inValue {
    [inValue retain];
    [files release];
    files = inValue;
}

- (int)countOfFiles {
    return [[self files] count];
}

- (NSDictionary *)objectInFilesAtIndex:(int)index {
    return [[self files] objectAtIndex:index];
}

- (void)getFile:(NSDictionary **)someFiles range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [files getObjects:someFiles range:inRange];
}

- (void)insertObject:(NSDictionary *)aFile inFilesAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromFilesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert File",@"")];
	}
	
	// Add aFile to the array files
	[files insertObject:aFile atIndex:index];
}

- (void)removeObjectFromFilesAtIndex:(int)index
{
	NSDictionary *aFile = [files objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aFile inFilesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete File",@"")];
	}
	
	// Remove the peak from the array
	[files removeObjectAtIndex:index];
}

- (void)replaceObjectInFilesAtIndex:(int)index withObject:(NSDictionary *)aFile
{
	NSDictionary *replacedFile = [files objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedFile];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace File",@"")];
	}
	
	// Replace the peak from the array
	[files replaceObjectAtIndex:index withObject:aFile];
}

- (BOOL)validateFile:(NSDictionary **)aFile error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end files


// Mutable To-Many relationship combinedPeaks
- (NSMutableArray *)combinedPeaks {
	return combinedPeaks;
}

- (void)setCombinedPeaks:(NSMutableArray *)inValue {
    [inValue retain];
    [combinedPeaks release];
    combinedPeaks = inValue;
}

- (int)countOfCombinedPeaks {
    return [[self combinedPeaks] count];
}

- (JKCombinedPeak *)objectInCombinedPeaksAtIndex:(int)index {
    return [[self combinedPeaks] objectAtIndex:index];
}

- (void)getCombinedPeak:(JKCombinedPeak **)someCombinedPeaks range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [combinedPeaks getObjects:someCombinedPeaks range:inRange];
}

- (void)insertObject:(JKCombinedPeak *)aCombinedPeak inCombinedPeaksAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromCombinedPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert CombinedPeak",@"")];
	}
	
	// Add aCombinedPeak to the array combinedPeaks
	[combinedPeaks insertObject:aCombinedPeak atIndex:index];
}

- (void)removeObjectFromCombinedPeaksAtIndex:(int)index
{
	JKCombinedPeak *aCombinedPeak = [combinedPeaks objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aCombinedPeak inCombinedPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete CombinedPeak",@"")];
	}
	
	// Remove the peak from the array
	[combinedPeaks removeObjectAtIndex:index];
}

- (void)replaceObjectInCombinedPeaksAtIndex:(int)index withObject:(JKCombinedPeak *)aCombinedPeak
{
	JKCombinedPeak *replacedCombinedPeak = [combinedPeaks objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedCombinedPeak];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace CombinedPeak",@"")];
	}
	
	// Replace the peak from the array
	[combinedPeaks replaceObjectAtIndex:index withObject:aCombinedPeak];
}

- (BOOL)validateCombinedPeak:(JKCombinedPeak **)aCombinedPeak error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end combinedPeaks

// Mutable To-Many relationship ratios
- (NSMutableArray *)ratios {
	return ratios;
}

- (void)setRatios:(NSMutableArray *)inValue {
    [inValue retain];
    [ratios release];
    ratios = inValue;
}

- (int)countOfRatios {
    return [[self ratios] count];
}

- (JKRatio *)objectInRatiosAtIndex:(int)index {
    return [[self ratios] objectAtIndex:index];
}

- (void)getRatio:(JKRatio **)someRatios range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [ratios getObjects:someRatios range:inRange];
}

- (void)insertObject:(JKRatio *)aRatio inRatiosAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromRatiosAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Ratio",@"")];
	}
	
	// Add aRatio to the array ratios
	[ratios insertObject:aRatio atIndex:index];
}

- (void)removeObjectFromRatiosAtIndex:(int)index
{
	JKRatio *aRatio = [ratios objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aRatio inRatiosAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Ratio",@"")];
	}
	
	// Remove the peak from the array
	[ratios removeObjectAtIndex:index];
}

- (void)replaceObjectInRatiosAtIndex:(int)index withObject:(JKRatio *)aRatio
{
	JKRatio *replacedRatio = [ratios objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedRatio];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Ratio",@"")];
	}
	
	// Replace the peak from the array
	[ratios replaceObjectAtIndex:index withObject:aRatio];
}

- (BOOL)validateRatio:(JKRatio **)aRatio error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end ratios

// Mutable To-Many relationship ratioValues
- (NSMutableArray *)ratioValues {
	return ratioValues;
}

- (void)setRatioValues:(NSMutableArray *)inValue {
    [inValue retain];
    [ratioValues release];
    ratioValues = inValue;
}

- (int)countOfRatioValues {
    return [[self ratioValues] count];
}

- (NSDictionary *)objectInRatioValuesAtIndex:(int)index {
    return [[self ratioValues] objectAtIndex:index];
}

- (void)getRatioValue:(NSDictionary **)someRatioValues range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [ratioValues getObjects:someRatioValues range:inRange];
}

- (void)insertObject:(NSDictionary *)aRatioValue inRatioValuesAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromRatioValuesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert RatioValue",@"")];
	}
	
	// Add aRatioValue to the array ratioValues
	[ratioValues insertObject:aRatioValue atIndex:index];
}

- (void)removeObjectFromRatioValuesAtIndex:(int)index
{
	NSDictionary *aRatioValue = [ratioValues objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aRatioValue inRatioValuesAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete RatioValue",@"")];
	}
	
	// Remove the peak from the array
	[ratioValues removeObjectAtIndex:index];
}

- (void)replaceObjectInRatioValuesAtIndex:(int)index withObject:(NSDictionary *)aRatioValue
{
	NSDictionary *replacedRatioValue = [ratioValues objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedRatioValue];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace RatioValue",@"")];
	}
	
	// Replace the peak from the array
	[ratioValues replaceObjectAtIndex:index withObject:aRatioValue];
}

- (BOOL)validateRatioValue:(NSDictionary **)aRatioValue error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end ratioValues

// Mutable To-Many relationship logMessages (without undo)
- (NSMutableArray *)logMessages {
	return logMessages;
}

- (void)setLogMessages:(NSMutableArray *)inValue {
    [inValue retain];
    [logMessages release];
    logMessages = inValue;
}

- (int)countOfLogMessages {
    return [[self logMessages] count];
}

- (NSDictionary *)objectInLogMessagesAtIndex:(int)index {
    return [[self logMessages] objectAtIndex:index];
}

- (void)getLogMessage:(NSDictionary **)someLogMessages range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [logMessages getObjects:someLogMessages range:inRange];
}

- (void)insertObject:(NSDictionary *)aLogMessage inLogMessagesAtIndex:(int)index {
	// Add aLogMessage to the array logMessages
	[logMessages insertObject:aLogMessage atIndex:index];
}

- (void)removeObjectFromLogMessagesAtIndex:(int)index
{
	// Remove the peak from the array
	[logMessages removeObjectAtIndex:index];
}

- (void)replaceObjectInLogMessagesAtIndex:(int)index withObject:(NSDictionary *)aLogMessage
{
	// Replace the peak from the array
	[logMessages replaceObjectAtIndex:index withObject:aLogMessage];
}

- (BOOL)validateLogMessage:(NSDictionary **)aLogMessage error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end logMessages

// Mutable To-Many relationship metadata
- (NSMutableArray *)metadata {
	return metadata;
}

- (void)setMetadata:(NSMutableArray *)inValue {
    [inValue retain];
    [metadata release];
    metadata = inValue;
}

- (int)countOfMetadata {
    return [[self metadata] count];
}

- (NSDictionary *)objectInMetadataAtIndex:(int)index {
    return [[self metadata] objectAtIndex:index];
}

- (void)getMetadata:(NSDictionary **)someMetadata range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [metadata getObjects:someMetadata range:inRange];
}

- (void)insertObject:(NSDictionary *)aMetadata inMetadataAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromMetadataAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Metadata",@"")];
	}
	
	// Add aMetadata to the array metadata
	[metadata insertObject:aMetadata atIndex:index];
}

- (void)removeObjectFromMetadataAtIndex:(int)index
{
	NSDictionary *aMetadata = [metadata objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aMetadata inMetadataAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Metadata",@"")];
	}
	
	// Remove the peak from the array
	[metadata removeObjectAtIndex:index];
}

- (void)replaceObjectInMetadataAtIndex:(int)index withObject:(NSDictionary *)aMetadata
{
	NSDictionary *replacedMetadata = [metadata objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedMetadata];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Metadata",@"")];
	}
	
	// Replace the peak from the array
	[metadata replaceObjectAtIndex:index withObject:aMetadata];
}

- (BOOL)validateMetadata:(NSDictionary **)aMetadata error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end metadata


- (NSString *)keyForValueInSummary {
	return keyForValueInSummary;
}
- (void)setKeyForValueInSummary:(NSString *)aKeyForValueInSummary {
	[[self undoManager] registerUndoWithTarget:self selector:@selector(setKeyForValueInSummary:) object:keyForValueInSummary];
	[[self undoManager] setActionName:NSLocalizedString(@"Set Key For Value In Summary",@"Set KeyForValueInSummary")];
	[keyForValueInSummary autorelease];
	keyForValueInSummary = [aKeyForValueInSummary retain];
}

#pragma mark (macrostyle)
boolAccessor(abortAction, setAbortAction)
boolAccessor(setPeakSymbolToNumber, setSetPeakSymbolToNumber)
intAccessor(valueToUse, setValueToUse)
intAccessor(peaksToUse, setPeaksToUse)
intAccessor(scoreBasis, setScoreBasis)
intAccessor(columnSorting, setColumnSorting)
boolAccessor(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor(matchThreshold, setMatchThreshold)
idAccessor(maximumRetentionIndexDifference, setMaximumRetentionIndexDifference)
boolAccessor(closeDocuments, setCloseDocuments)
boolAccessor(calculateRatios, setCalculateRatios)

@end
