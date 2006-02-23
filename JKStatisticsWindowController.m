//
//  JKStatisticsWindowController.m
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JKStatisticsWindowController.h"
#import "JKMainDocument.h"
#import "JKPeakRecord.h"
#import "JKRatio.h"
#import "JKDataModel.h"
#import "JKSpectrum.h"

@implementation JKStatisticsWindowController

- (id) init {
	self = [super initWithWindowNibName:@"JKStatisticalAnalysis"];
	if (self != nil) {
		combinedPeaks = [[NSMutableArray alloc] init];
		ratioValues = [[NSMutableArray alloc] init];
		ratios = [[NSMutableArray alloc] init];
		metadata = [[NSMutableArray alloc] init];
//		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refetch:) name:@"JKMainDocument loaded" object:nil];
	}
	return self;
}
- (void) dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[combinedPeaks release];
	[ratioValues release];
	[ratios release];
	[metadata release];
	[super dealloc];
}

-(void)windowDidLoad {
	// Load Ratios file from application support folder
	NSArray *paths;
	int i;
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
		
	[resultsTable setDelegate:self];
	[ratiosTable setDelegate:self];
	[metadataTable setDelegate:self];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[resultsTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[ratiosTable superview]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrollViewBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[metadataTable superview]];
	[resultsTable setDoubleAction:@selector(doubleClickAction:)];
	[self collectMetadata];
	[self collectCombinedPeaks];
	[self calculateRatios];
}

-(void)doubleClickAction:(id)sender {
	JKLogDebug(@"row %d column %d",[sender clickedRow], [sender clickedColumn]);
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
	} else if ([sender clickedRow] == -1) {
		// A column was double clicked
		// Bring forward the associated file
		[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] window] makeKeyAndOrderFront:self];
	} else {
		// A cell was double clicked
		// Bring forwars associated file and
		// select associated peak
		// Ugliest code ever! note that keyPath depends on the binding, so if we bind to something else e.g. height, this will fail!
		[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] window] makeKeyAndOrderFront:self];
		NSString *keyPath = [[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] infoForBinding:@"value"] valueForKey:NSObservedKeyPathKey];
		keyPath = [keyPath substringWithRange:NSMakeRange(16,[keyPath length]-18-16)];
		// Check that we don't look for an empty cell
		if ([[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]) {
			[[[[[[sender tableColumns] objectAtIndex:[sender clickedColumn]] identifier] mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:[[[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]] valueForKey:keyPath]]];
		}
	}
}

-(void)saveRatiosFile {
	NSArray *paths;
	
	paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
	if ([paths count] > 0)  { 
		NSString *destPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Peacock/Ratios.plist"];
		if(![NSKeyedArchiver archiveRootObject:ratios toFile:destPath])
			JKLogError(@"Error saving Ratios.plist file.");
    }
}

-(IBAction)refetch:(id)sender {
	[self collectMetadata];
	[self collectCombinedPeaks];
	[self calculateRatios];
}

-(IBAction)editRatios:(id)sender {
	[ratiosEditor makeKeyAndOrderFront:self];
//	[NSApp beginSheet: ratiosEditor
//	   modalForWindow: [self window]
//		modalDelegate: self
//	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop	
	
}

//-(IBAction)cancelEditRatios:(id)sender {
//	[NSApp endSheet:ratiosEditor];
//
//}

-(IBAction)saveEditRatios:(id)sender {
	[self saveRatiosFile];
//	[NSApp endSheet:ratiosEditor];
}

-(IBAction)options:(id)sender {
	[NSApp beginSheet: optionsSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop		
}

-(IBAction)doneOptions:(id)sender {
	[self refetch:self];
	[NSApp endSheet:optionsSheet];
}
-(void)collectMetadata {
	int i;
	int filesCount;
	
	NSArray *files;
	JKMainDocument *document;
	
	files = [[NSArray arrayWithArray:[[NSDocumentController sharedDocumentController] documents]] sortedArrayUsingSelector:@selector(metadataCompare:)];
	filesCount = [files count];
	
	int columnCount = [metadataTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[metadataTable removeTableColumn:[[metadataTable tableColumns] objectAtIndex:i]];
	} 
	[self willChangeValueForKey:@"metadata"];
	[metadata removeAllObjects];

	NSMutableDictionary *metadataDictSampleCode = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *metadataDictDescription = [[NSMutableDictionary alloc] init];
	[metadataDictSampleCode setValue:@"Sample code" forKey:@"label"];
	[metadataDictDescription setValue:@"Description" forKey:@"label"];
	
	for (i=0; i < filesCount; i++) {
		document = [files objectAtIndex:i];
			
		[metadataDictSampleCode setValue:[[[document dataModel] metadata] valueForKey:@"sampleCode"] forKey:[NSString stringWithFormat:@"file_%d",i]];
		[metadataDictDescription setValue:[[[document dataModel] metadata] valueForKey:@"sampleDescription"] forKey:[NSString stringWithFormat:@"file_%d",i]];
		
		NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		[[tableColumn headerCell] setStringValue:[document displayName]];
		NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[NSString stringWithFormat:@"file_%d",i]];
		[tableColumn bind:@"value" toObject:metadataController withKeyPath:keyPath options:nil];
		[[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
		[[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
		[tableColumn setEditable:NO];
		[metadataTable addTableColumn:tableColumn];
		[tableColumn release];
	}
	[metadata addObject:metadataDictSampleCode];
	[metadata addObject:metadataDictDescription];

	[metadataDictSampleCode release];
	[metadataDictDescription release];
	[self didChangeValueForKey:@"metadata"];
	return;
}

-(void)collectCombinedPeaks {
	int i,j,k;
	int filesCount, peaksCount, combinedPeaksCount;
	int knownCombinedPeakIndex;
	BOOL knownCombinedPeak, unknownCompound;
	float scoreResult, maxScoreResult;
	
	NSArray *files;
	NSMutableArray *peaksArray;
	JKMainDocument *document;
	JKPeakRecord *peak;
	NSMutableDictionary *combinedPeak;
	NSString *peakName;
	NSString *combinedPeakName;
	
	files = [[NSArray arrayWithArray:[[NSDocumentController sharedDocumentController] documents]] sortedArrayUsingSelector:@selector(metadataCompare:)];
	filesCount = [files count];
	
	int columnCount = [resultsTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[resultsTable removeTableColumn:[[resultsTable tableColumns] objectAtIndex:i]];
	} 
	[self willChangeValueForKey:@"combinedPeaks"];
	[combinedPeaks removeAllObjects];
	int peaksToUse = [[[NSUserDefaults standardUserDefaults] valueForKey:@"peaksForSummary"] intValue]; // 1=all 2=identified 3=confirmed
	for (i=0; i < filesCount; i++) {
		document = [files objectAtIndex:i];
		peaksArray = [[document dataModel] peaks];
		peaksCount = [peaksArray count];
		
		for (j=0; j < peaksCount; j++) {
			peak = [peaksArray objectAtIndex:j];
			peakName = [peak valueForKey:@"label"];
			// Determine wether or not the user wants to use this peak
			if (![peak confirmed] && peaksToUse >= 3) {
				continue;
			} else if (![peak identified] && peaksToUse >= 2) {
				continue;
			}
			combinedPeaksCount = [combinedPeaks count];
			knownCombinedPeak = NO;
//			unknownCompound = NO;
			maxScoreResult = 0;
	
			for (k=0; k < combinedPeaksCount; k++) {
				// Match according to label for confirmed or identified peaks
				if ([peak confirmed] || [peak identified]) {
					combinedPeak = [combinedPeaks objectAtIndex:k];
					combinedPeakName = [combinedPeak valueForKey:@"label"];
					unknownCompound = NO;
					
					if ([peakName isEqualToString:combinedPeakName]) {
						knownCombinedPeak = YES;
						knownCombinedPeakIndex = k;
						unknownCompound = NO;
					} 					
				} else { // Or if it's an unidentified peak, match according to score
					combinedPeak = [combinedPeaks objectAtIndex:k];
					unknownCompound = YES;
					
					JKSpectrum *spectrum;
					spectrum = [[[document mainWindowController] getSpectrumForPeak:peak] normalizedSpectrum];
				
					if ([combinedPeak valueForKey:@"spectrum"]) {
						scoreResult  = [spectrum scoreComparedToSpectrum:[combinedPeak valueForKey:@"spectrum"]];
						if (scoreResult > 80) {
							if (scoreResult > maxScoreResult) {
								knownCombinedPeak = YES;
								knownCombinedPeakIndex = k;						
								unknownCompound = YES;
							}
						}
					}
				}
			}
			if (!knownCombinedPeak) {
				if (!unknownCompound) {
					NSMutableDictionary *combinedPeak = [[NSMutableDictionary alloc] initWithObjectsAndKeys:peakName, @"label", peak, [NSString stringWithFormat:@"file_%d",i], nil];
					[combinedPeaks addObject:combinedPeak];	
					[combinedPeak release];
				} else {
					NSMutableDictionary *combinedPeak = [[NSMutableDictionary alloc] initWithObjectsAndKeys:NSLocalizedString(@"Unknown compound",@"Unknown compounds in stats summary."), @"label", peak, [NSString stringWithFormat:@"file_%d",i],
					   [[[document mainWindowController] getSpectrumForPeak:peak] normalizedSpectrum], @"spectrum", nil];
					[combinedPeaks addObject:combinedPeak];
					[combinedPeak release];
				}
			} else {
				combinedPeak = [combinedPeaks objectAtIndex:knownCombinedPeakIndex];
				[combinedPeak setObject:peak forKey:[NSString stringWithFormat:@"file_%d",i]];		
			}
		} 	
		//[NSString stringWithFormat:@"file_%d",i]
		NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		[[tableColumn headerCell] setStringValue:[document displayName]];
		NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.normalizedSurface",[NSString stringWithFormat:@"file_%d",i]];
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
	}

	NSString *key;
//	JKPeakRecord *peak;
	NSEnumerator *peaksEnumerator;
	int count;
	float averageRetentionTime, averageSurface, averageHeigth;
	
	combinedPeaksCount = [combinedPeaks count];
	for (i = 0; i < combinedPeaksCount; i++) {
		combinedPeak = [combinedPeaks objectAtIndex:i];
		peaksEnumerator = [combinedPeak keyEnumerator];
		count = 0;
		averageRetentionTime = 0.0;
		averageSurface = 0.0;
		averageHeigth = 0.0;
		
		while (key = [peaksEnumerator nextObject]) {
			if ([[key substringToIndex:4] isEqualToString:@"file"]){
				peak = [combinedPeak objectForKey:key];
				count++;
				averageRetentionTime = averageRetentionTime + [[peak topTime] floatValue];
				averageSurface = averageSurface + [[peak normalizedSurface] floatValue];
				averageHeigth = averageHeigth + [[peak normalizedHeight] floatValue];
			}
		}
		
		// Calculate average retentionIndex
		averageRetentionTime = averageRetentionTime/count;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageRetentionTime] forKey:@"averageRetentionTime"];
		
		// Calculate average surface
		averageSurface = averageSurface/filesCount;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageSurface] forKey:@"averageSurface"];
		
		// Calculate average height
		averageHeigth = averageHeigth/filesCount	;
		[combinedPeak setValue:[NSNumber numberWithFloat:averageHeigth] forKey:@"averageHeigth"];
		
		// Calculate stdev?
	}
	NSSortDescriptor *retentionTimeDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionTime" 
													ascending:YES];
//	firstNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"firstName" 
//													 ascending:YES
//													  selector:@selector(caseInsensitiveCompare:)] autorelease];
	NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionTimeDescriptor,nil];
	[combinedPeaks sortUsingDescriptors:sortDescriptors];
	[self didChangeValueForKey:@"combinedPeaks"];
	[retentionTimeDescriptor release];
	return;
}

-(IBAction)exportSummary:(id)sender {
	JKLogWarning(@"WARNING: Future not yet implemetend");
//	[combinedPeaks writeToFile:<#(NSString *)path#> atomically:<#(BOOL)useAuxiliaryFile#>
}
-(void)calculateRatios {
	int i,j;
	int filesCount, ratiosCount;
	float result;
	NSArray *files;
	JKMainDocument *document;
	NSMutableDictionary *mutDict;
	NSString *keyPath;

	files = [[NSArray arrayWithArray:[[NSDocumentController sharedDocumentController] documents]] sortedArrayUsingSelector:@selector(metadataCompare:)];
	filesCount = [files count];
	
	int columnCount = [ratiosTable numberOfColumns];
	for (i = columnCount-1; i > 0; i--) {
		[ratiosTable removeTableColumn:[[ratiosTable tableColumns] objectAtIndex:i]];
	} 

	[self willChangeValueForKey:@"ratioValues"];
	[ratioValues removeAllObjects];
	for (i=0; i < filesCount; i++) {
		document = [files objectAtIndex:i];
		ratiosCount = [ratios count];
		
		for (j=0; j < ratiosCount; j++) {
			if (i == 0) {
				mutDict = [[NSDictionary alloc] initWithObjectsAndKeys:[[ratios objectAtIndex:j] valueForKey:@"name"], @"name", nil];
				[ratioValues addObject:mutDict];
				[mutDict release];
			} else {
				mutDict = [ratioValues objectAtIndex:j];
			}
			result = 0.0;
			result = [[ratios objectAtIndex:j] calculateRatioForKey:[NSString stringWithFormat:@"file_%d",i] inCombinedPeaksArray:combinedPeaks];
			keyPath = [NSString stringWithFormat:@"%@.ratioResult",[NSString stringWithFormat:@"file_%d",i]];
			[mutDict setValue:[NSNumber numberWithFloat:result] forKey:keyPath];
		}
				
		NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
		[tableColumn setIdentifier:document];
		[[tableColumn headerCell] setStringValue:[document displayName]];
		keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.ratioResult",[NSString stringWithFormat:@"file_%d",i]];
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
	}
	[self didChangeValueForKey:@"ratioValues"];
	return;
}

#pragma mark SYNCHRONIZED SCROLLING

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
//	if (!movingColumnsProgramatically) {
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
//	}
}

- (void)tableView:(NSTableView *)tableView didDragTableColumn:(NSTableColumn *)tableColumn {
	[resultsTable moveColumn:[resultsTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[ratiosTable moveColumn:[ratiosTable columnWithIdentifier:@"firstColumn"] toColumn:0];
	[metadataTable moveColumn:[metadataTable columnWithIdentifier:@"firstColumn"] toColumn:0];
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
//	if (!movingColumnsProgramatically) {
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
//	}
}
#pragma mark SHEETS

- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}
- (void)windowWillBeginSheet:(NSNotification *)notification {
	return;
}
- (void)windowDidEndSheet:(NSNotification *)notification {
	return;
}

idAccessor(combinedPeaks, setCombinedPeaks);
idAccessor(ratioValues, setRatioValues);
idAccessor(ratios, setRatios);

@end
