//
//  JKStatisticsWindowController.m
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JKStatisticsWindowController.h"
#import "JKGCMSDocument.h"
#import "JKMainWindowController.h"
#import "JKPeakRecord.h"
#import "JKRatio.h"
#import "JKSpectrum.h"
#import "Growl/GrowlApplicationBridge.h"
#import "MyGraphView.h"

@implementation JKStatisticsWindowController

- (id) init  
{
	self = [super initWithWindowNibName:@"JKStatisticalAnalysis"];
	if (self != nil) {
		combinedPeaks = [[NSMutableArray alloc] init];
		ratioValues = [[NSMutableArray alloc] init];
		ratios = [[NSMutableArray alloc] init];
		metadata = [[NSMutableArray alloc] init];
		files = [[NSMutableArray alloc] init];
		[self setAbortAction:NO];
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
	[super dealloc];
}

#pragma mark WINDOW MANAGEMENT

- (void)awakeFromNib  
{
    [[self window] center];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName  
{
	if ([displayName hasPrefix:@"Untitled"] && ![displayName hasSuffix:@"peacock-stats"]) {
		return @"Statistical Analysis";
	} else {
		return displayName;
	}
}

- (void)windowDidLoad  
{
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
//	[filesTableView setDataSource:self];
	
	[resultsTable setDelegate:self];
	[ratiosTable setDelegate:self];
	[metadataTable setDelegate:self];
	[resultsTable setDoubleAction:@selector(doubleClickAction:)];
	[ratiosTable setDoubleAction:@selector(doubleClickAction:)];
	[metadataTable setDoubleAction:@selector(doubleClickAction:)];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[resultsTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[ratiosTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[metadataTable superview]];
	if ([combinedPeaks count] > 0) {
		[summaryWindow makeKeyAndOrderFront:self];
	}
	
	if ([files count] > 0 ) {
		// Insert table columns (in case we're opening from a file)
	//	[self insertTableColumns];
	}
}

#pragma mark ACTIONS

- (void)runStatisticalAnalysis
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL errorOccurred = NO;	
	[self setAbortAction:NO];
	int i;
	int filesCount = [files count];
	[fileProgressIndicator setMaxValue:filesCount*7.0];
	[fileProgressIndicator setDoubleValue:0.0];
	NSError *error = [[NSError alloc] init];
	JKGCMSDocument *document;
	[self willChangeValueForKey:@"metadata"];
	[self willChangeValueForKey:@"combinedPeaks"];
	[self willChangeValueForKey:@"ratioValues"];
	
	// Prepations before starting processing files
	[detailStatusTextField setStringValue:NSLocalizedString(@"Preparing processing",@"")];
	[fileProgressIndicator setIndeterminate:YES];
	[fileProgressIndicator startAnimation:self];
	
	// Remove all but the first column from the tableview
	int columnCount = [metadataTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[metadataTable removeTableColumn:[[metadataTable tableColumns] objectAtIndex:i]];
	} 
	columnCount = [resultsTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[resultsTable removeTableColumn:[[resultsTable tableColumns] objectAtIndex:i]];
	} 
	
	columnCount = [ratiosTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[ratiosTable removeTableColumn:[[ratiosTable tableColumns] objectAtIndex:i]];
	} 
	
	[metadata removeAllObjects];
	[combinedPeaks removeAllObjects];
	[ratioValues removeAllObjects];
	
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
	peaksToUse = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"peaksForSummary"] intValue]; // 1=all 2=identified 3=confirmed
	NSAssert(peaksToUse > 0 && peaksToUse < 4, @"peaksToUse has invalid value");

	// Reset the comparison window
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCompareChromatograms"] boolValue]) {
		NSEnumerator *enumerator = [[[comparisonScrollView documentView] subviews] objectEnumerator];
		id subview;
		while ((subview = [enumerator nextObject])) {
			[subview removeFromSuperview];
		}
		[[comparisonScrollView documentView] setFrame:NSMakeRect(0.0,0.0,818,200*[files count])];
	}
	
	[fileProgressIndicator setIndeterminate:NO];
	for (i=0; i < filesCount; i++) {
		[detailStatusTextField setStringValue:@"Opening Document"];
		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCloseDocument"] boolValue] error:&error];
		[[self window] makeKeyAndOrderFront:self];
		if (document == nil) {
			JKLogError(@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]);
			errorOccurred = YES;
			[fileProgressIndicator setDoubleValue:(i+1)*5.0];
			continue;	
		}
		[fileStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Processing file '%@' (%d of %d)",@"Batch process status text"),[[files objectAtIndex:i] valueForKey:@"filename"],i+1,filesCount]];
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisPerformSanityCheck"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Performing Sanity Check",@"")];
			// Not yet implemented feature
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		[detailStatusTextField setStringValue:NSLocalizedString(@"Collecting metadata",@"")];
		[self collectMetadataForDocument:document atIndex:i];
		[fileProgressIndicator incrementBy:1.0];
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisSummarize"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Collecting metadata",@"")];
			[self collectMetadataForDocument:document atIndex:i];
			[detailStatusTextField setStringValue:NSLocalizedString(@"Comparing Peaks",@"")];
			[self collectCombinedPeaksForDocument:document atIndex:i];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCalculateRatios"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Calculating Ratios",@"")];
			[self calculateRatiosForDocument:document atIndex:i];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCompareChromatograms"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Setting up Comparison Window",@"")];
			[self setupComparisonWindowForDocument:document atIndex:i];
			[fileProgressIndicator incrementBy:1.0];
		}	
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCloseDocument"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Closing Document",@"")];
			[document close];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}
		[fileProgressIndicator setDoubleValue:(i+1)*5.0];
	}
	// Out of scope for files
	
	// Finishing
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisSummarize"] boolValue]) {
		[detailStatusTextField setStringValue:NSLocalizedString(@"Sorting Results",@"")];
		[fileProgressIndicator setIndeterminate:YES];
		[self sortCombinedPeaks];
	}
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisSaveAsAnalysisPeacockFile"] boolValue]) {
		[detailStatusTextField setStringValue:NSLocalizedString(@"Saving Peacock Analysis File",@"")];
		[[self document] saveDocument:self];
		[fileProgressIndicator incrementBy:1.0];
	}
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisSaveAsTabDelimitedTextFile"] boolValue]) {
		[detailStatusTextField setStringValue:NSLocalizedString(@"Saving Tab Delimited Text File",@"")];
		[fileProgressIndicator setIndeterminate:YES];
		[self exportSummary:self];
	}
	[error release];
	[[self window] makeKeyAndOrderFront:self];
	
	// This way we don't get bolded text!
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
	
	[GrowlApplicationBridge notifyWithTitle:NSLocalizedString(@"Statistical Analysis Finished",@"") description:NSLocalizedString(@"Peacock finished processing your data.",@"") notificationName:@"Statistical Analysis Finished" iconData:nil priority:0 isSticky:NO clickContext:nil];

	// Present results
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCompareChromatograms"] boolValue]) {
		[comparisonWindow makeKeyAndOrderFront:self];
	}
	if (([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisSummarize"] boolValue]) | ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"statisticalAnalysisCalculateRatios"] boolValue])) {
		[summaryWindow makeKeyAndOrderFront:self];
	}
		
	if (errorOccurred) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error(s) during batch processing",@""),NSLocalizedString(@"One or more errors occurred during batch processing your files. The console.log available from the Console application contains more details about the error. Common errors include files moved after being added to the list and full disks.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	} else if ([self abortAction]) {
		NSRunInformationalAlertPanel(NSLocalizedString(@"Statistical Analysis aborted",@""),NSLocalizedString(@"The execution of the statistical analysis was aborted by the user. Be advised to check the current state of the files that were being processed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	}
	
	[self didChangeValueForKey:@"metadata"];
	[self didChangeValueForKey:@"combinedPeaks"];
	[self didChangeValueForKey:@"ratioValues"];
	
	
	[pool release];
}

- (void)collectMetadataForDocument:(JKGCMSDocument *)document atIndex:(int)index  
{
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

- (void)collectCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index  
{
	// This autoreleasepool allows to flush the memory after each file, to prevent using more than 2 GB during this loop!
	NSAutoreleasePool *subPool = [[NSAutoreleasePool alloc] init];
	
	int j,k;
	int peaksCount, combinedPeaksCount;
	int knownCombinedPeakIndex, peaksCompared;
	BOOL isKnownCombinedPeak, isUnknownCompound;
	float scoreResult, maxScoreResult;
	NSDate *date = [NSDate date];
	int peakCount;
    float certainty;
    
	NSMutableArray *peaksArray;
	JKPeakRecord *peak;
	NSMutableDictionary *combinedPeak;
	NSString *peakName;
	NSString *combinedPeakName;
	NSMutableArray *peakToAddToCombinedPeaks = [[NSMutableArray alloc] init];
	JKSpectrum *spectrum;
	
	// Problems!
	//  - should use retention index instead of retention time
	// ?- measurement conditions should be similar e.g. same temp. program
	// \u201a\340\366- comparison to peaks within same chromatogram may occur when peaks within window were added
	// ?- unconfirmed peaks encountered before corresponding confirmed peak won't match
	// ?- no check to see if combined peak already had a match from the same file (highest score should win?)
	// \u201a\340\366- memory usage from opening files is problematic: open/close files on demand?
	
	date = [NSDate date];
	peaksCompared = 0;
	peaksArray = [document peaks];
	peaksCount = [peaksArray count];
	
	// Go through the peaks
	for (j=0; j < peaksCount; j++) {
		peak = [peaksArray objectAtIndex:j];
		peakName = [peak valueForKey:@"label"];
		isKnownCombinedPeak = NO;
		isUnknownCompound = NO;
		
		// Determine wether or not the user wants to use this peak
		if (![peak confirmed] && peaksToUse >= 3) {
			continue;
		} else if (![peak identified] && peaksToUse >= 2) {
			continue;
		} else if ([[peak normalizedSurface] floatValue] < 0.1 && ![peak confirmed]) { // filter small peaks, but not if it's a confirmed peak
			continue;
		}
		
		// Match with combined peaks
		combinedPeaksCount = [combinedPeaks count];
		maxScoreResult = 0.0;
		
		// Because the combinedPeaks array is empty, we add all peaks for the first one.
		if (index == 0) {
			isKnownCombinedPeak = NO;
			isUnknownCompound = YES;
			if ([peak confirmed]) {
				isUnknownCompound = NO;
			}
		}
		
		spectrum = [[peak spectrum] normalizedSpectrum];
		
		for (k=0; k < combinedPeaksCount; k++) {
			combinedPeak = [combinedPeaks objectAtIndex:k];
			combinedPeakName = [combinedPeak valueForKey:@"label"];
			isKnownCombinedPeak = NO;
			
			// Match according to label for confirmed  peaks
			if ([peak confirmed]) {
				isUnknownCompound = NO;
				
				if ([peakName isEqualToString:combinedPeakName]) {
					isKnownCombinedPeak = YES;
					knownCombinedPeakIndex = k;
					maxScoreResult = 101.0; // confirmed peak!
					break;
				} 					
			} else { // Or if it's an unidentified peak, match according to score
				isUnknownCompound = YES;
				if (fabsf([[peak retentionIndex] floatValue] - [[combinedPeak valueForKey:@"retentionIndex"] floatValue]) < 500.0) {
					//NSAssert([combinedPeak valueForKey:@"spectrum"], [combinedPeak description]);
					peaksCompared++;
					scoreResult  = [spectrum scoreComparedToSpectrum:[combinedPeak valueForKey:@"spectrum"]];
					if (scoreResult > 70) {
						if (scoreResult > maxScoreResult) {
							maxScoreResult = scoreResult;
							isKnownCombinedPeak = YES;
							knownCombinedPeakIndex = k;						
						}
					}
				}
			}
			
		}
		if (maxScoreResult > 70 ){
			isKnownCombinedPeak = YES;
		}
		if (!isKnownCombinedPeak) {
			if (!isUnknownCompound) {
				NSAssert([peak spectrum], [peak description]);
				NSAssert([[peak spectrum] normalizedSpectrum], [peak description]);
				combinedPeak = [[NSMutableDictionary alloc] initWithObjectsAndKeys:peakName, @"label", 
                    peak, [NSString stringWithFormat:@"file_%d",index], 
                    [peak retentionIndex], @"retentionIndex", 
                    [[peak spectrum] normalizedSpectrum], @"spectrum", 
                    [NSNumber numberWithInt:1], @"peakCount", 
                    [NSNumber numberWithFloat:1.0], @"certainty", 
                    nil];
//				NSLog(@"%@", [combinedPeak description]);
				[peakToAddToCombinedPeaks addObject:combinedPeak];	
				[combinedPeak release];
			} else {
				NSAssert([peak spectrum], [peak description]);
				combinedPeak = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[NSString stringWithFormat:NSLocalizedString(@"Unknown compound %d ",@"Unknown compounds in stats summary."), unknownCount], @"label", 
                    peak, [NSString stringWithFormat:@"file_%d",index], 
                    [peak retentionIndex], @"retentionIndex",
                    [[peak spectrum] normalizedSpectrum], @"spectrum", 
                    [NSNumber numberWithInt:1], @"peakCount", 
                    [NSNumber numberWithFloat:0.0], @"certainty", 
                    nil];
//				NSLog(@"%@", [combinedPeak description]);
				[peakToAddToCombinedPeaks addObject:combinedPeak];
				[combinedPeak release];
				unknownCount++;
			}
		} else {
			combinedPeak = [combinedPeaks objectAtIndex:knownCombinedPeakIndex];
			if ([combinedPeak objectForKey:[NSString stringWithFormat:@"file_%d",index]]) {
				// Should average with spectrum of combinedpeak?
				if ([[combinedPeak objectForKey:[NSString stringWithFormat:@"maxScoreResult_%d",index]] floatValue] < maxScoreResult) {
					[combinedPeak setObject:peak forKey:[NSString stringWithFormat:@"file_%d",index]];		
				} else {
					//JKLogError(@"Peak matching peak '%@' encountered and ignored in file %d: %@",[combinedPeak valueForKey:@"label"], index, [document displayName]);
				}
			} else {
				[combinedPeak setObject:peak forKey:[NSString stringWithFormat:@"file_%d",index]];
            }
            
            [combinedPeak setObject:[NSNumber numberWithFloat:maxScoreResult] forKey:[NSString stringWithFormat:@"maxScoreResult_%d",index]];	
            peakCount = [[combinedPeak valueForKey:@"peakCount"] intValue];
            certainty = [[combinedPeak valueForKey:@"certainty"] intValue];
            if (isUnknownCompound) {
                certainty = (certainty*peakCount)/(peakCount+1);               
            } else {
                certainty = (certainty*peakCount + 1.0)/(peakCount+1);
            }
            peakCount++;
            [combinedPeak setValue:[NSNumber numberWithInt:peakCount] forKey:@"peakCount"];
            [combinedPeak setValue:[NSNumber numberWithFloat:certainty] forKey:@"certainty"];
            NSAssert(combinedPeak, [combinedPeak description]);
            NSAssert([combinedPeak objectForKey:@"spectrum"] != nil, [combinedPeak description]);
            spectrum = [[combinedPeak objectForKey:@"spectrum"] spectrumByAveragingWithSpectrum:[peak spectrum] withWeight:1.0/peakCount];
            NSAssert(spectrum, @"no spectrum returned");
            [combinedPeak setObject:spectrum forKey:@"spectrum"];
                
			
			// If the combined peak has a meaningless label, but the new has, replace
            if ([[combinedPeak valueForKey:@"label"] hasPrefix:NSLocalizedString(@"Unknown compound",@"Unknown compounds in stats summary.")]) {
                if ([peak confirmed]) {
//                    NSLog([peak valueForKey:@"label"]);
                    [combinedPeak setObject:[[peak valueForKey:@"label"] stringByAppendingString:@"?"] forKey:@"label"];
                } else if (![[peak valueForKey:@"label"] isEqualToString:@""] && [peak valueForKey:@"label"]) {
//                    NSLog([peak valueForKey:@"label"]);
                    [combinedPeak setObject:[peak valueForKey:@"label"] forKey:@"label"];
                }
            }
		}
	} 	
	
	[combinedPeaks addObjectsFromArray:peakToAddToCombinedPeaks];
	[peakToAddToCombinedPeaks release];
	
	JKLogInfo(@"File %d: %@; time: %.2g s; peaks: %d; peaks comp.: %d; comb. peaks: %d; speed: %.f peaks/s",index, [document displayName], -[date timeIntervalSinceNow], peaksCount, peaksCompared, [combinedPeaks count], peaksCompared/-[date timeIntervalSinceNow]);
	
	NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
	[tableColumn setIdentifier:document];
	[[tableColumn headerCell] setStringValue:[document displayName]];
	NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.normalizedSurface",[NSString stringWithFormat:@"file_%d",index]];
	[tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
	[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
	NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
	[formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
	[formatter setPositiveFormat:@"#0.0"];
	[formatter setLocalizesFormat:YES];
	[[tableColumn dataCell] setFormatter:formatter];
	[[tableColumn dataCell] setAlignment:NSRightTextAlignment];
	[tableColumn setEditable:NO];
	[resultsTable addTableColumn:tableColumn];
	[tableColumn release];
	
	[subPool release];
}

- (void)calculateRatiosForDocument:(JKGCMSDocument *)document atIndex:(int)index  
{
	int j;
	int ratiosCount;
	float result;
	NSMutableDictionary *mutDict;
	NSString *keyPath;
	
	[self willChangeValueForKey:@"ratioValues"];
	ratiosCount = [ratios count];
	
	for (j=0; j < ratiosCount; j++) {
		if (index == 0) {
			mutDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:[[ratios objectAtIndex:j] valueForKey:@"name"], @"name", nil];
			[ratioValues addObject:mutDict];
			[mutDict release];
		} else {
			mutDict = [ratioValues objectAtIndex:j];
		}
		result = 0.0;
		result = [[ratios objectAtIndex:j] calculateRatioForKey:[NSString stringWithFormat:@"file_%d",index] inCombinedPeaksArray:combinedPeaks];
		keyPath = [NSString stringWithFormat:@"%@.ratioResult",[NSString stringWithFormat:@"file_%d",index]];
		[mutDict setValue:[NSNumber numberWithFloat:result] forKey:keyPath];
	}
	
	NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
	[tableColumn setIdentifier:document];
	[[tableColumn headerCell] setStringValue:[document displayName]];
	keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.ratioResult",[NSString stringWithFormat:@"file_%d",index]];
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

- (void)sortCombinedPeaks 
{
	JKLogEnteringMethod();
	NSMutableDictionary *combinedPeak;
	NSString *key;
	JKPeakRecord *peak;
	NSEnumerator *peaksEnumerator;
	int i, count, combinedPeaksCount;
	float averageRetentionIndex, averageSurface, averageHeight;
	float standardDeviationRetentionIndex, standardDeviationSurface, standardDeviationHeight;
	// int filesCount = [[self files] count];
	
	combinedPeaksCount = [[self combinedPeaks] count];
	for (i = 0; i < combinedPeaksCount; i++) {
		combinedPeak = [[self combinedPeaks] objectAtIndex:i];
		peaksEnumerator = [combinedPeak keyEnumerator];
		count = 0;
		averageRetentionIndex = 0.0;
		averageSurface = 0.0;
		averageHeight = 0.0;
		
		while ((key = [peaksEnumerator nextObject])) {
			if ([[key substringToIndex:4] isEqualToString:@"file"]){
				peak = [combinedPeak objectForKey:key];
				count++;
				averageRetentionIndex = averageRetentionIndex + [[peak retentionIndex] floatValue];
				averageSurface = averageSurface + [[peak normalizedSurface] floatValue];
				averageHeight = averageHeight + [[peak normalizedHeight] floatValue];
			}
		}
		
		// Calculate average retentionIndex
		averageRetentionIndex = averageRetentionIndex/count;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageRetentionIndex] forKey:@"averageRetentionIndex"];
		
		// Calculate average surface
		averageSurface = averageSurface/count;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageSurface] forKey:@"averageSurface"];
		
		// Calculate average height
		averageHeight = averageHeight/count;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageHeight] forKey:@"averageHeight"];
		
		[combinedPeak setValue:[NSNumber numberWithInt:count] forKey:@"compoundCount"];
		
		// Calculate stdev 
		peaksEnumerator = [combinedPeak keyEnumerator];
		standardDeviationRetentionIndex = 0.0;
		standardDeviationSurface = 0.0;
		standardDeviationHeight = 0.0;
		count = 0;
		
		while ((key = [peaksEnumerator nextObject])) {
			if ([[key substringToIndex:4] isEqualToString:@"file"]){
				peak = [combinedPeak objectForKey:key];
				count++;
				standardDeviationRetentionIndex = standardDeviationRetentionIndex + powf(([[peak retentionIndex] floatValue] - averageRetentionIndex),2);
				standardDeviationSurface = standardDeviationSurface + powf(([[peak normalizedSurface] floatValue] - averageSurface),2);
				standardDeviationHeight = standardDeviationHeight + powf(([[peak normalizedHeight] floatValue] - averageHeight),2);
			}
		}
		// Calculate stdev retentionIndex
		standardDeviationRetentionIndex = sqrtf(standardDeviationRetentionIndex/(count-1));
		[combinedPeak setValue:[NSNumber numberWithFloat:standardDeviationRetentionIndex] forKey:@"standardDeviationRetentionIndex"];
		
		// Calculate stdev surface
		standardDeviationSurface = sqrtf(standardDeviationSurface/(count-1));
		[combinedPeak setValue:[NSNumber numberWithFloat:standardDeviationSurface] forKey:@"standardDeviationSurface"];
		
		// Calculate stdev height
		standardDeviationHeight = sqrtf(standardDeviationHeight/(count-1));
		[combinedPeak setValue:[NSNumber numberWithFloat:standardDeviationHeight] forKey:@"standardDeviationHeight"];
		
	}
	NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
																			ascending:YES];
	NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
	[[self combinedPeaks] sortUsingDescriptors:sortDescriptors];
	[retentionIndexDescriptor release];
	
	return;
}

//-(void)sortColumns {
//	NSArray *tableColumns = [metadataTable tableColumns];
//	NSEnumerator *enumerator = [tableColumns objectEnumerator];
//	id object;
//	
//	while (object = [enumerator nextObject]) {
//    // do something with object...
//		if ([[tableColumn infoForBinding:@"value"] valueForKey:NSObservedKeyPathKey]
//	}	return;
//}


- (void)saveRatiosFile  
{
	NSArray *paths;
	
	paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
	if ([paths count] > 0)  { 
		NSString *destPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Peacock/Ratios.plist"];
		if(![NSKeyedArchiver archiveRootObject:ratios toFile:destPath])
			JKLogError(@"Error saving Ratios.plist file.");
    }
}

- (void)insertTableColumns  
{
	int i;
	int filesCount = [files count];

//	NSError *error = [[NSError alloc] init];
//	JKMainDocument *document;
	
	// Remove all but the first column from the tableview
	int columnCount = [metadataTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[metadataTable removeTableColumn:[[metadataTable tableColumns] objectAtIndex:i]];
	} 
	columnCount = [resultsTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[resultsTable removeTableColumn:[[resultsTable tableColumns] objectAtIndex:i]];
	} 
	
	columnCount = [ratiosTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[ratiosTable removeTableColumn:[[ratiosTable tableColumns] objectAtIndex:i]];
	} 
	
	NSTableColumn *tableColumn;
	NSString *keyPath;
	NSNumberFormatter *formatter;
	for (i=0; i < filesCount; i++) {
//		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:NO error:&error];

		tableColumn = [[NSTableColumn alloc] init];
//		[tableColumn setIdentifier:document];
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
//		[tableColumn setIdentifier:document];
//		[[tableColumn headerCell] setStringValue:[document displayName]];
		keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.normalizedSurface",[NSString stringWithFormat:@"file_%d",i]];
		[[tableColumn headerCell] setStringValue:[[metadata objectAtIndex:3] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
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
//		[tableColumn setIdentifier:document];
//		[[tableColumn headerCell] setStringValue:[document displayName]];
		keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.ratioResult",[NSString stringWithFormat:@"file_%d",i]];
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
		
//		[document close];
	}
	
	// Finishing
	[self sortCombinedPeaks];
	
	[summaryWindow makeKeyAndOrderFront:self];
}

- (void)setupComparisonWindowForDocument:(JKGCMSDocument *)document atIndex:(int)index
{
	NSArrayController *peakController = [[NSArrayController alloc] initWithContent:[document peaks]];
	NSArrayController *chromatogramDataSeriesController = [[NSArrayController alloc] initWithContent:[document chromatograms]];
	NSArrayController *baselineController = [[NSArrayController alloc] initWithContent:[document baseline]];
	MyGraphView *chromatogramView = [[MyGraphView alloc] initWithFrame:NSMakeRect(0.0,200*([files count]-index-1),NSWidth([[comparisonScrollView documentView] frame]),200)];
	[chromatogramView setAutoresizingMask:NSViewWidthSizable];
	[chromatogramView bind:@"dataSeries" toObject: chromatogramDataSeriesController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"baseline" toObject: baselineController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"peaks" toObject: peakController
			   withKeyPath:@"arrangedObjects" options:nil];
	NSString *titleString = [NSString stringWithFormat:@"%@ - %@ - %@", [document displayName], [[document metadata] valueForKey:@"sampleCode"], [[document metadata] valueForKey:@"sampleDescription"]];
	[chromatogramView setTitleString:[[[NSAttributedString alloc] initWithString:titleString] autorelease]];
	NSRect plottingArea = [chromatogramView plottingArea];
	plottingArea.size.height = plottingArea.size.height - 20.0;
	[chromatogramView setPlottingArea:plottingArea];
	[[comparisonScrollView documentView] addSubview:chromatogramView];
	[chromatogramView showAll:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedZooming:) name:@"MyGraphViewSynchronizedZooming" object:chromatogramView];
}

- (void)synchronizedZooming:(NSNotification *)theNotification
{
	
		NSEnumerator *enumerator = [[[comparisonScrollView documentView] subviews] objectEnumerator];
		id subview;
		NSNumber *newXMinimum = [[theNotification userInfo] valueForKey:@"newXMinimum"];
		NSNumber *newXMaximum = [[theNotification userInfo] valueForKey:@"newXMaximum"];
		
		while ((subview = [enumerator nextObject])) {
			[subview setXMinimum:newXMinimum];
			[subview setXMaximum:newXMaximum];
		}
}
#pragma mark IBACTIONS

- (IBAction)addButtonAction:(id)sender  
{
	NSArray *fileTypes = [NSArray arrayWithObjects:@"cdf", @"peacock",nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
	[oPanel beginSheetForDirectory:nil file:nil types:fileTypes modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}


- (IBAction)doubleClickAction:(id)sender  
{
	JKLogDebug(@"row %d column %d",[sender clickedRow], [sender clickedColumn]);
	NSError *error = [[[NSError alloc] init] autorelease];
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
	} else if ([sender clickedRow] == -1) {
		// A column was double clicked
		// Bring forward the associated file
		//[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] window] makeKeyAndOrderFront:self];
		//NSLog([[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-1]]);
		[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-1]]] display:YES error:&error];
	} else {
		// A cell was double clicked
		// Bring forwars associated file and
		// select associated peak
		// Ugliest code ever! note that keyPath depends on the binding, so if we bind to something else e.g. height, this will fail!
		JKGCMSDocument *document;
	//	[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] window] makeKeyAndOrderFront:self];
		NSURL *url = [NSURL fileURLWithPath:[[metadata objectAtIndex:2] valueForKey:[NSString stringWithFormat:@"file_%d",[sender clickedColumn]-1]]];
		document = [[NSDocumentController sharedDocumentController] documentForURL:url];
		if (!document) {
			document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url display:YES error:&error];
		}
		[[[document mainWindowController] window] makeKeyAndOrderFront:self];
		NSString *keyPath = [[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] infoForBinding:@"value"] valueForKey:NSObservedKeyPathKey];
		keyPath = [keyPath substringWithRange:NSMakeRange(16,[keyPath length]-18-16)];
		// Check that we don't look for an empty cell
		int index = [[[[document mainWindowController] peakController] arrangedObjects] indexOfObjectIdenticalTo:[[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]];
		[[[document mainWindowController] peakController] setSelectionIndex:index];
//
//		if ([[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]) {
//			NSLog(@"%@",[[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]);
//			if(![[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:[[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]]]){
//				NSLog(@"selection didn't change");
//			}
//			NSLog(@"%@", [[[document mainWindowController] peakController] selectedObjects]);
//			
//		}
	}
}

- (IBAction)options:(id)sender  
{
	[NSApp beginSheet: optionsSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop		
}

- (IBAction)summarizeOptionsDoneAction:(id)sender  
{
	[NSApp endSheet:summarizeOptionsSheet];
}

- (IBAction)runStatisticalAnalysisButtonAction:(id)sender  
{
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	
	[NSThread detachNewThreadSelector:@selector(runStatisticalAnalysis) toTarget:self withObject:nil];
	
}

- (IBAction)stopButtonAction:(id)sender 
{
	[self setAbortAction:YES];
}

- (IBAction)editRatios:(id)sender  
{
	[NSApp beginSheet: ratiosEditor
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop	
	
}

- (IBAction)cancelEditRatios:(id)sender  
{
	[NSApp endSheet:ratiosEditor];

}

- (IBAction)saveEditRatios:(id)sender  
{
	[self saveRatiosFile];
	[NSApp endSheet:ratiosEditor];
}


- (IBAction)exportSummary:(id)sender  
{
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
		int fileCount = [[[self metadata] objectAtIndex:0] count]-1;
		int compoundCount = [combinedPeaks count];
		NSString *normalizedSurface;
		NSString *normalizedHeight;
			
		// Sort array
		NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
																			   ascending:YES];
		NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
		[combinedPeaks sortUsingDescriptors:sortDescriptors];
		[retentionIndexDescriptor release];
		
		[outStr appendString:@"Sample code\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) {
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]] ];
		}
		[outStr appendString:@"\n"];

		[outStr appendString:@"Sample description\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) {
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:1] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		
		[outStr appendString:@"File path\t\t\t\t\t\t"];
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
		
		int ratiosCount = [ratios count];
		[outStr appendString:@"\nRatios\nLabel\t\t\t\t\t\t"];
		for (i=0; i < fileCount; i++) { // Sample code
			[outStr appendFormat:@"\t%@", [[[self metadata] objectAtIndex:0] valueForKey:[NSString stringWithFormat:@"file_%d",i]]];
		}
		[outStr appendString:@"\n"];
		for (j=0; j < ratiosCount; j++) {
			[outStr appendFormat:@"%@\t\t\t\t\t\t", [[[self ratios] objectAtIndex:j] valueForKey:@"name"]];
			for (i=0; i < fileCount; i++) {
				[outStr appendFormat:@"\t%@", [[[self ratioValues] objectAtIndex:j] valueForKey:[NSString stringWithFormat:@"file_%d.ratioResult",i]] ];
			}
			[outStr appendString:@"\n"];
		}

		if (![outStr writeToFile:[sp filename] atomically:YES encoding:NSUTF8StringEncoding error:NULL])
			NSBeep();
	}
}

#pragma mark SYNCHRONIZED SCROLLING

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectTableColumn:(NSTableColumn *)aTableColumn  
{
	if ([[aTableColumn identifier] isKindOfClass:[NSString class]]) {
		return NO;
	} else {
		return YES;
	}
}

- (void)scrollViewBoundsDidChange:(NSNotification *)aNotification  
{
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

- (void)tableViewColumnDidMove:(NSNotification *)aNotification  
{
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

- (void)tableViewColumnDidResize:(NSNotification *)aNotification  
{
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

- (void)tableView:(NSTableView *)tableView didDragTableColumn:(NSTableColumn *)tableColumn  
{
	[resultsTable moveColumn:[resultsTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[ratiosTable moveColumn:[ratiosTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[metadataTable moveColumn:[metadataTable columnWithIdentifier:@"firstColumn"] toColumn:0];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex  
{
	if (aTableView == metadataTable) {
		return NO;
	} else {
		return YES;
	}
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification  
{
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

#pragma mark SHEETS

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo  
{
    if (returnCode == NSOKButton) {
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
				[mutDict setObject:[[NSWorkspace sharedWorkspace] iconForFile:aFile] forKey:@"icon"];
				[self willChangeValueForKey:@"files"];
				[files addObject:mutDict];
				[self didChangeValueForKey:@"files"];
				[mutDict release];				
			}
		}
	}	
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo  
{
    [sheet orderOut:self];
}

- (void)windowWillBeginSheet:(NSNotification *)notification  
{
	return;
}

- (void)windowDidEndSheet:(NSNotification *)notification  
{
	return;
}

#pragma mark ACCESSORS

- (NSWindow *)summaryWindow  
{
	return summaryWindow;
}

#pragma mark IBACTIOS (MACROSTYLE)

idAccessor(combinedPeaks, setCombinedPeaks)
idAccessor(ratioValues, setRatioValues)
idAccessor(ratios, setRatios)
idAccessor(metadata, setMetadata)
idAccessor(files, setFiles)
boolAccessor(abortAction, setAbortAction)

@end
