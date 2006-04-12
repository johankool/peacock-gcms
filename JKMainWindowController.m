//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKMainWindowController.h"
#import "JKDataModel.h"
#import "netcdf.h"
#import "MyGraphView.h"
#import "SpectrumGraphDataSerie.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKSpectrum.h"
#import "JKLibrarySearch.h"
#import "JKPeakRecord.h"
#import "JKLibraryEntry.h"

static void *DocumentObservationContext = (void *)1100;
static void *ChromatogramObservationContext = (void *)1101;
static void *SpectrumObservationContext = (void *)1102;
//static void *PeaksObservationContext = (void *)1103;

@implementation JKMainWindowController

#pragma mark INITIALIZATION

-(id)init {
	self = [super initWithWindowNibName:@"JKMainDocument"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
		[self setLibSearch:[[JKLibrarySearch alloc] init]];		

		showTICTrace = YES;
		showSpectrum = YES;
		showCombinedSpectrum = NO;
		showLibraryHit = YES;
		showNormalizedSpectra = YES;
		showPeaks = JKAllPeaks;
	}
    return self;
}

-(void)windowDidLoad {
	// Set controller bindings
	[mainController bind:@"content" toObject:self  
			 withKeyPath:@"dataModel" options:nil];
	[peakController bind:@"contentArray" toObject:[self dataModel] 
			 withKeyPath:@"peaks" options:nil];
	[baselineController bind:@"contentArray" toObject:[self dataModel] 
				 withKeyPath:@"baseline" options:nil];
	[chromatogramDataSeriesController bind:@"contentArray" toObject:[self dataModel] 
							   withKeyPath:@"chromatograms" options:nil];	
		
	// Setup the toolbar after the document nib has been loaded 
    [self setupToolbar];	
	
	// ChromatogramView bindings
	[chromatogramView bind:@"dataSeries" toObject: chromatogramDataSeriesController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"dataSeriesSelectionIndexes" toObject: chromatogramDataSeriesController
			   withKeyPath:@"selectionIndexes" options:nil];
	[chromatogramView bind:@"baseline" toObject: baselineController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"baselineSelectionIndexes" toObject: baselineController
			   withKeyPath:@"selectionIndexes" options:nil];
	[chromatogramView bind:@"peaks" toObject: peakController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"peaksSelectionIndexes" toObject: peakController
			   withKeyPath:@"selectionIndexes" options:nil];
	NSAssert([[chromatogramView dataSeries] count] > 0, @"No chromatogram dataseries to draw.");
	if ([[chromatogramView dataSeries] objectAtIndex:0]) {
		[[[chromatogramView dataSeries] objectAtIndex:0] bind:@"peaks" toObject: peakController
												  withKeyPath:@"arrangedObjects" options:nil];
		[[[chromatogramView dataSeries] objectAtIndex:0] bind:@"peaksSelectionIndexes" toObject: peakController
												  withKeyPath:@"selectionIndexes" options:nil];		
	}
	
	// Spectrum
	[spectrumView bind:@"dataSeries" toObject: spectrumDataSeriesController
		   withKeyPath:@"arrangedObjects" options:nil];
	[spectrumView bind:@"dataSeriesSelectionIndexes" toObject: spectrumDataSeriesController
		   withKeyPath:@"selectionIndexes" options:nil];
	
	// More setup
	[chromatogramView setShouldDrawLegend:NO];
	[chromatogramView setKeyForXValue:@"Scan"];
	[chromatogramView setKeyForYValue:@"Total Intensity"];
	[chromatogramView showAll:self];
	[chromatogramView setNeedsDisplay:YES];
	
	[spectrumView setXMinimum:[NSNumber numberWithFloat:0]];
	[spectrumView setXMaximum:[NSNumber numberWithFloat:650]];
	[spectrumView setYMinimum:[NSNumber numberWithFloat:-1.1]];
	[spectrumView setYMaximum:[NSNumber numberWithFloat:1.1]];
	
	// Register as observer
	[peakController addObserver:self forKeyPath:@"selection" options:nil context:SpectrumObservationContext];
	[searchResultsController addObserver:self forKeyPath:@"selection" options:nil context:SpectrumObservationContext];
	[searchResultsController addObserver:self forKeyPath:@"content" options:nil context:SpectrumObservationContext];
	
	[[self dataModel] addObserver:self forKeyPath:@"metadata.sampleCode" options:nil context:DocumentObservationContext];
	[[self dataModel] addObserver:self forKeyPath:@"metadata.sampleDescription" options:nil context:DocumentObservationContext];
	
	[self addObserver:self forKeyPath:@"showTICTrace" options:nil context:ChromatogramObservationContext];
	[self addObserver:self forKeyPath:@"showSpectrum" options:nil context:SpectrumObservationContext];
	[self addObserver:self forKeyPath:@"showCombinedSpectrum" options:nil context:SpectrumObservationContext];
	[self addObserver:self forKeyPath:@"showLibraryHit" options:nil context:SpectrumObservationContext];
	[self addObserver:self forKeyPath:@"showNormalizedSpectra" options:nil context:SpectrumObservationContext];
}

-(void)dealloc {
	[peakController removeObserver:self forKeyPath:@"selection"];
	[searchResultsController removeObserver:self forKeyPath:@"selection"];
	[searchResultsController removeObserver:self forKeyPath:@"content"];
	[[self dataModel] removeObserver:self forKeyPath:@"metadata.sampleCode"];
	[[self dataModel] removeObserver:self forKeyPath:@"metadata.sampleDescription"];

    [super dealloc];
}

#pragma mark IBACTIONS

-(IBAction)identifyPeaks:(id)sender{
	[[self dataModel] identifyPeaks];
}

-(IBAction)showMassChromatogram:(id)sender {	
	NSString *inString = [sender stringValue];
	
	[[[self document] dataModel] addChromatogramForMass:inString];
//	[self addMassChromatogram:object];
	[sender setStringValue:@""];

	return;
}

-(void)addMassChromatogram:(id)object {
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(removeMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Add Mass Chromatogram",@"")];
	[chromatogramDataSeriesController addObject:object];	
}

-(void)removeMassChromatogram:(id)object {
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(addMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Mass Chromatogram",@"")];
	[chromatogramDataSeriesController removeObject:object];	
}

-(IBAction)renumberPeaks:(id)sender {
	int i;
	int peakCount = [[peakController arrangedObjects] count];
	NSMutableArray *array = [NSMutableArray array];
	for (i = 0; i < peakCount; i++) {	
		id object = [[peakController arrangedObjects] objectAtIndex:i];
		// Undo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[NSNumber numberWithInt:[[object valueForKey:@"peakID"] intValue]] forKey:@"peakID"];
		[array addObject:mutDict];

		// The real thing
		[object setValue:[NSNumber numberWithInt:i+1] forKey:@"peakID"];
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(undoRenumberPeaks:)
										object:array];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Renumber Peaks",@"")];
}

-(void)undoRenumberPeaks:(NSArray *)array {
	int i;
	int peakCount = [array count];
	NSMutableArray *arrayOut = [NSMutableArray array];
	for (i = 0; i < peakCount; i++) {	
		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
		
		// Redo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[object valueForKey:@"peakID"] forKey:@"peakID"];
		[arrayOut addObject:mutDict];
		
		// Reading back what was changed
		[object setValue:[[array objectAtIndex:i] valueForKey:@"peakID"] forKey:@"peakID"];
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(undoRenumberPeaks:)
										object:arrayOut];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Renumber Peaks",@"")];

}

-(IBAction)resetPeaks:(id)sender {
	int i;
	int peakCount = [[peakController arrangedObjects] count];
	NSMutableArray *array = [NSMutableArray array];
	for (i = 0; i < peakCount; i++) {
		id object = [[peakController arrangedObjects] objectAtIndex:i];
		
		// Undo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
		[mutDict setValue:[object libraryHit] forKey:@"libraryHit"];
		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
		[array addObject:mutDict];
		
		// The real thing
		[object setValue:@"" forKey:@"label"];
		[object setValue:@"" forKey:@"score"];
		[object setValue:@"" forKey:@"symbol"];
		[object setLibraryHit:[[[JKLibraryEntry alloc] init] autorelease]];
		[object setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
		[object setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];		
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
												 selector:@selector(undoResetPeaks:)
												   object:array];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Reset Peaks",@"")];
	
}
-(void)undoResetPeaks:(NSArray *)array {
	int i;
	int peakCount = [[peakController arrangedObjects] count];
	NSMutableArray *arrayOut = [NSMutableArray array];
	for (i = 0; i < peakCount; i++) {
		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
		
		// Redo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
		[arrayOut addObject:mutDict];
		
		// Reading back what was changed
		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
		
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
												 selector:@selector(undoResetPeaks:)
												   object:arrayOut];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Reset Peaks",@"")];
	
}

-(IBAction)showPeaksAction:(id)sender {
	if ([sender tag] == 1) {
		[self setShowPeaks:JKIdenitifiedPeaks];
		[peakController setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == YES"]];
	} else if ([sender tag] == 2) {
		[self setShowPeaks:JKUnidentifiedPeaks];
		[peakController setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == NO"]];		
	} else if ([sender tag] == 3) {
		[self setShowPeaks:JKConfirmedPeaks];
		[peakController setFilterPredicate:[NSPredicate predicateWithFormat:@"confirmed == YES"]];
	} else if ([sender tag] == 4) {
		[self setShowPeaks:JKUnconfirmedPeaks];
		[peakController setFilterPredicate:[NSPredicate predicateWithFormat:@"(identified == YES) AND (confirmed == NO)"]];		
	} else {
		[self setShowPeaks:JKAllPeaks];
		[peakController setFilterPredicate:nil]; 
	}
}

-(IBAction)confirm:(id)sender {
	int i;
	NSMutableArray *arrayOut = [NSMutableArray array];

	if ([peakController selectionIndex] != NSNotFound) {
		int peakCount = [[peakController selectedObjects] count];

		for (i=0; i < peakCount; i++) {
			id object = [[peakController selectedObjects] objectAtIndex:i];
			
			// Redo preparation
			NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
			[mutDict setObject:object forKey:@"peakrecord"];
			[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
			[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
			[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
			[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
			[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
			[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
			[arrayOut addObject:mutDict];
			
			// The real thing
			if (([[object valueForKey:@"identified"] boolValue] == NO) && ([searchResultsController selectionIndex] != NSNotFound)) {
				[object setValue:[NSNumber numberWithBool:YES] forKey:@"identified"];
				[object setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"score"] forKey:@"score"];
				[object setLibraryHit:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"libraryHit"]];
				[object setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.name"] forKey:@"label"];
				[object setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.symbol"] forKey:@"symbol"];
				[object setValue:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"] lastPathComponent] forKey:@"library"];
			} else if ([[object valueForKey:@"identified"] boolValue] == NO) {
				NSBeep();
				return;
			}
			[object setValue:[NSNumber numberWithBool:YES] forKey:@"confirmed"];
			
		}
		[[[self document] undoManager] registerUndoWithTarget:self
													 selector:@selector(undoConfirm:)
													   object:arrayOut];
		[[[self document] undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit(s)",@"")];
		
	} else {
		// Don't know what to confirm
		NSBeep();
	}
}
-(void)undoConfirm:(NSArray *)array {
	int i;
	int count = [array count];
	NSMutableArray *arrayOut = [NSMutableArray array];
	for (i = 0; i < count; i++) {
		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
		
		// Redo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
		[arrayOut addObject:mutDict];
		
		// Reading back what was changed
		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
		
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
												 selector:@selector(undoConfirm:)
												   object:arrayOut];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit(s)",@"")];
	
}

-(IBAction)discard:(id)sender {
	NSMutableArray *arrayOut = [NSMutableArray array];

	if ([peakController selectionIndex] != NSNotFound) {
		int i;
		int peakCount = [[peakController selectedObjects] count];
		for (i = 0; i < peakCount; i++) {
			id object = [[peakController selectedObjects] objectAtIndex:i];
		
			// Redo preparation
			NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
			[mutDict setObject:object forKey:@"peakrecord"];
			[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
			[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
			[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
			[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
			[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
			[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
			[arrayOut addObject:mutDict];
			
			[object setValue:@"" forKey:@"label"];
			[object setValue:@"" forKey:@"score"];
			[object setValue:@"" forKey:@"symbol"];
			[object setLibraryHit:[[[JKLibraryEntry alloc] init] autorelease]];
			[object setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
			[object setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];
		}	
		[[[self document] undoManager] registerUndoWithTarget:self
													 selector:@selector(undoDiscard:)
													   object:arrayOut];
		[[[self document] undoManager] setActionName:NSLocalizedString(@"Discard Library Hit",@"")];
		
	} else {
		// Don't know what to discard
		NSBeep();
	}
}
-(void)undoDiscard:(NSArray *)array {
	int i;
	int count = [array count];
	NSMutableArray *arrayOut = [NSMutableArray array];
	for (i = 0; i < count; i++) {
		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
		
		// Redo preparation
		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
		[mutDict setObject:object forKey:@"peakrecord"];
		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
		[arrayOut addObject:mutDict];
		
		// Reading back what was changed
		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
		
	}	
	[[[self document] undoManager] registerUndoWithTarget:self
												 selector:@selector(undoConfirm:)
												   object:arrayOut];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Discard Library Hit",@"")];
	
}

-(IBAction)next:(id)sender{
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] < [[peakController arrangedObjects] count]-1)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i+1]; 
	} else {
		[peakController setSelectionIndex:0]; 
	}
}

-(IBAction)previous:(id)sender{
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] > 0)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i-1]; 
	} else {
		[peakController setSelectionIndex:[[peakController arrangedObjects] count]-1]; 
	}
}

-(IBAction)search:(id)sender{
	if ([peakController selectionIndex] != NSNotFound) {
		id currentPeak = [[peakController selectedObjects] objectAtIndex:0];
		
//		[searchingIndicator startAnimation:self];
		
		// Reset any previous search results
		[currentPeak setValue:@"" forKey:@"label"];
		[currentPeak setValue:@"" forKey:@"score"];
		[currentPeak setValue:@"" forKey:@"symbol"];
		[currentPeak setLibraryHit:[[[JKLibraryEntry alloc] init] autorelease]];
		[currentPeak setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
		[currentPeak setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];
		
		[NSThread detachNewThreadSelector:@selector(search) toTarget:self withObject:nil];
//		[searchingIndicator stopAnimation:self];
	} else {
		// Don't know what to search for
		NSBeep();
	}
}

-(IBAction)searchOptions:(id)sender{
    [NSApp beginSheet: searchOptionsSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}


//-(IBAction)displayAutopilotSheet:(id)sender{
//    [NSApp beginSheet: autopilotSheet
//	   modalForWindow: [self window]
//		modalDelegate: self
//	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//		  contextInfo: nil];
//    // Sheet is up here.
//    // Return processing to the event loop
//}

//-(IBAction)autopilotAction:(id)sender{
//	[NSApp endSheet:autopilotSheet];
//	
//	
//	NSArray *currentArray = [[NSArray alloc] initWithArray:[[peakController content] copy]];
//	[[[self document] undoManager] registerUndoWithTarget:peakController 
//												 selector:@selector(setContent:)
//												   object:currentArray];
//	[[[self document] undoManager] setActionName:NSLocalizedString(@"Identify Compounds",@"")];
//	[currentArray release];
//	
//	[NSThread detachNewThreadSelector:@selector(autopilot) toTarget:self withObject:nil];
//}

-(IBAction)other:(id)sender{
    [NSApp beginSheet: addSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}

//-(IBAction)closeAutopilotSheet:(id)sender {
//    [NSApp endSheet:autopilotSheet];
//}

-(IBAction)closeAddSheet:(id)sender {
    [NSApp endSheet:addSheet];
}

-(IBAction)closeSearchOptionsSheet:(id)sender{
    [NSApp endSheet:searchOptionsSheet];
}
-(IBAction)browseForDefaultLibrary:(id)sender {
	int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"jdx"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"]
									 file:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"] types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            NSString *aFile = [filesToOpen objectAtIndex:i];
			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:aFile forKey:@"defaultLibrary"];
        }
    }
}
-(IBAction)abort:(id)sender {
    [[self libSearch] setAbortAction:YES];
}
-(IBAction)showTICTraceAction:(id)sender {
	if (showTICTrace) {
		[self setShowTICTrace:NO];
	} else {
		[self setShowTICTrace:YES];
	}
}

-(IBAction)showSpectrumAction:(id)sender {
	if (showSpectrum) {
		[self setShowSpectrum:NO];
		[self setShowCombinedSpectrum:YES];
	} else {
		[self setShowSpectrum:YES];
		[self setShowCombinedSpectrum:NO];
	}
}

-(IBAction)showCombinedSpectrumAction:(id)sender {
	if (showCombinedSpectrum) {
		[self setShowCombinedSpectrum:NO];
		[self setShowSpectrum:YES];
	} else {
		[self setShowCombinedSpectrum:YES];
		[self setShowSpectrum:NO];
	}
}

-(IBAction)showNormalizedSpectraAction:(id)sender {
	if (showNormalizedSpectra) {
		[self setShowNormalizedSpectra:NO];
	} else {
		[self setShowNormalizedSpectra:YES];
	}
}

-(IBAction)showLibraryHitAction:(id)sender {
	if (showLibraryHit) {
		[self setShowLibraryHit:NO];
	} else {
		[self setShowLibraryHit:YES];
	}
}
-(IBAction)editLibrary:(id)sender {
	NSError *error = [[NSError alloc] init];
	NSDocument *document;	
	NSString *path = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"];
	if (path == nil) {
		JKLogError(@"ERROR: No library set in preferences.",[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"]);
	} else {
		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES error:&error];
		if (document == nil) {
			JKLogError(@"ERROR: File at %@ could not be opened.",[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"]);
		}		
	}
	[error release];
}

-(IBAction)fitChromatogramDataToView:(id)sender {
	[chromatogramView showAll:self];
}
-(IBAction)fitSpectrumDataToView:(id)sender {
	[spectrumView showAll:self];
}

-(IBAction)autopilotAction:(id)sender{
    [NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	
	[NSThread detachNewThreadSelector:@selector(identifyPeaks) toTarget:self withObject:nil];
}

#pragma mark ACTIONS

-(void)search {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if ([peakController selectionIndex] != NSNotFound) {
		id currentPeak = [[peakController selectedObjects] objectAtIndex:0];
		
		[libSearch setDocument:self];
		
		[searchResultsController setSelectsInsertedObjects:NO];
		
		[searchResultsController setContent:[libSearch searchLibraryForPeak:currentPeak]];
		[searchResultsController setSelectsInsertedObjects:YES];
		[searchResultsController setSelectionIndex:0];
		[resultsTable reloadData];
		
	}
	[pool release]; 
}

-(void)identifyPeaks {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	
	NSArray *peaksArray = [peakController arrangedObjects];
	
	[libSearch setDocument:[self document]];
	[libSearch setProgressIndicator:progressBar];
	
	[libSearch searchLibraryForPeaks:peaksArray];
	
	if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"soundWhenFinished"] boolValue])
		NSBeep();	
	
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
	
	[pool release]; 
}

-(void)displaySpectrum:(JKSpectrum *)spectrum {
	SpectrumGraphDataSerie *spectrumDataSerie;
	
	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
	[spectrumDataSerie loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
	
	[(NSArrayController*)[spectrumView dataSeriesContainer] addObject:spectrumDataSerie];
	
	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
	
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	
	[spectrumDataSerie setSeriesTitle:NSLocalizedString(@"Observed Spectrum",@"")];
	[spectrumDataSerie setSeriesColor:[NSColor blueColor]];
	[spectrumDataSerie setKeyForXValue:[spectrumView keyForXValue]];
	[spectrumDataSerie setKeyForYValue:[spectrumView keyForYValue]];
	
	[spectrumView setNeedsDisplay:YES];	
	[spectrumDataSerie release];
}

-(void)displayResult:(JKLibraryEntry *)libraryEntry {	
	SpectrumGraphDataSerie *spectrumDataSerie;
	
	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
	[spectrumDataSerie loadDataPoints:[libraryEntry numberOfPoints] withXValues:[libraryEntry masses] andYValues:[libraryEntry intensities]];
	
	[(NSArrayController*)[spectrumView dataSeriesContainer] addObject:spectrumDataSerie];
	
	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
	
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	
	[spectrumDataSerie setSeriesTitle:NSLocalizedString(@"Library Hit",@"")];
	[spectrumDataSerie setSeriesColor:[NSColor orangeColor]];
	[spectrumDataSerie setKeyForXValue:[spectrumView keyForXValue]];
	[spectrumDataSerie setKeyForYValue:[spectrumView keyForYValue]];
	
	[spectrumView setNeedsDisplay:YES];	
	[spectrumDataSerie release];
}

#pragma mark KEY VALUE OBSERVATION

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {

	if (context == SpectrumObservationContext) {
		//if ((object == peakController && [keyPath isEqualToString:@"selection"]) || (object == searchResultsController)) {
		if ([peakController selectionIndex] != NSNotFound) {
			// Clear current content			
			[spectrumDataSeriesController removeObjects:[spectrumDataSeriesController arrangedObjects]];
			
			id currentPeak = [[peakController selectedObjects] objectAtIndex:0];
			
			if (object != searchResultsController) {
				[searchResultsController setContent:nil];
				[resultsTable reloadData];				
			}
			
			JKSpectrum *spectrum;
			if ([self showCombinedSpectrum]) {
				spectrum = [[self dataModel] getCombinedSpectrumForPeak:currentPeak];				
			} else {
				spectrum = [[self dataModel] getSpectrumForPeak:currentPeak];
			}
			
			if ([self showNormalizedSpectra]) 
				spectrum = [spectrum normalizedSpectrum];
			
			[self displaySpectrum:spectrum];
			
			if ([self showLibraryHit]) {				
				// Is there already a searchresult?	
				JKLibraryEntry *libraryEntry;
				if ([currentPeak identified] == NO) {
					if ([searchResultsController selectionIndex] != NSNotFound) {
						libraryEntry = [[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"libraryHit"];
					} else {
					// Nothing to display, so we're done.
						return;
					}	
				} else {
					libraryEntry = [currentPeak valueForKey:@"libraryHit"];
				}
				if ([self showNormalizedSpectra]) {
					libraryEntry = [libraryEntry negativeNormalizedLibraryEntry];
				} else {
					libraryEntry = [libraryEntry negativeLibraryEntry];
				}
				// Show library entry	
				[self displayResult:libraryEntry];			
			}
		}
	} 
	if (context == DocumentObservationContext) {
		[self synchronizeWindowTitleWithDocumentName];
	}
}

#pragma mark NSTOOLBAR MANAGEMENT

-(void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"PeacockMainWindowToolbarIdentifier"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [toolbar setVisible:NO];
	
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
}

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqual: @"Save Document Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Save",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Save",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Save Your Document",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"SaveDocumentItemImage"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: [self document]];
		[toolbarItem setAction: @selector(saveDocument:)];
    }  else if ([itemIdent isEqual: @"Identify Peaks Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Peaks",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Peaks",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"questionmark"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(identifyPeaks:)];
    } else if ([itemIdent isEqual: @"Identify Compounds Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Compounds",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Compounds",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the components associated with the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"questionmark"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(autopilotAction:)];
    } else if ([itemIdent isEqual: @"Inspector"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Inspector",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Inspector",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Show an inspector to change attributs of the selected object",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"info"]];
		
		// Tell the item what message to send when it is clicked 
		//	[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showInspector:)];
    }   else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
    return toolbarItem;
}

-(NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Save Document Item Identifier", NSToolbarPrintItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier", NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier, @"Inspector", nil];
}

-(NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:  @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier",  @"Save Document Item Identifier", NSToolbarPrintItemIdentifier, @"Inspector",
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

-(void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		[addedItem setToolTip:NSLocalizedString(@"Print Your Document",@"")];
		//	[addedItem setTarget: self];
    }
}  

-(void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
	//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
}

-(BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual: @"Save Document Item Identifier"]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
		enable = [[self document] isDocumentEdited];
		enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Peaks Item Identifier"]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Compounds Item Identifier"]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Inspector"]) {
		enable = YES;
    }
    return enable;
}


#pragma mark UNDO MANAGEMENT

-(NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
}

#pragma mark ACCESSORS

-(JKDataModel *)dataModel
{
    return [[self document] dataModel];
}

-(MyGraphView *)chromatogramView {
    return chromatogramView;
}

-(NSArrayController *)chromatogramDataSeriesController {
    return chromatogramDataSeriesController;
}

-(NSArrayController *)baselineController {
    return baselineController;
}
-(NSTableView *)peaksTable {
	return peaksTable;
}

-(NSArrayController *)peakController {
    return peakController;
}

-(NSTableView *)resultsTable {
	return resultsTable;
}


-(NSArrayController *)searchResultsController {
    return searchResultsController;
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

#pragma mark MENU/WINDOW HANDLING

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	if ([anItem action] == @selector(showTICTraceAction:)) {
		if (showTICTrace) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showSpectrumAction:)) {
		if (showSpectrum) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showCombinedSpectrumAction:)) {
		if (showCombinedSpectrum) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showLibraryHitAction:)) {
		if (showLibraryHit) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showNormalizedSpectraAction:)) {
		if (showNormalizedSpectra) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showPeaksAction:)) {
		if ([anItem tag] == [self showPeaks]) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(confirm:)) {
		if ([[[self peakController] selectedObjects] count] >= 1) {
			return YES;
		} else {
			return NO;
		}
	} else if ([anItem action] == @selector(discard:)) {
		if ([[[self peakController] selectedObjects] count] >= 1)  {
			return YES;
		} else {
			return NO;
		}
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

-(NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
	if (![[[self dataModel] metadata] valueForKey:@"sampleCode"] && ![[[self dataModel] metadata] valueForKey:@"sampleDescription"]) {
		return displayName;
	} else if ([[[self dataModel] metadata] valueForKey:@"sampleCode"] && [[[self dataModel] metadata] valueForKey:@"sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@ - %@",[[[self dataModel] metadata] valueForKey:@"sampleCode"],[[[self dataModel] metadata] valueForKey:@"sampleDescription"] ];
	} else if (![[[self dataModel] metadata] valueForKey:@"sampleCode"] && [[[self dataModel] metadata] valueForKey:@"sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@",[[[self dataModel] metadata] valueForKey:@"sampleDescription"] ];
	} else if ([[[self dataModel] metadata] valueForKey:@"sampleCode"] && ![[[self dataModel] metadata] valueForKey:@"sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@",[[[self dataModel] metadata] valueForKey:@"sampleCode"] ];
	} else {
		return displayName;
	}
}

#pragma mark ACCESSORS (MACROSTYLE)
boolAccessor(abortAction, setAbortAction)
idAccessor(libSearch, setLibSearch)
boolAccessor(showTICTrace, setShowTICTrace)
boolAccessor(showSpectrum, setShowSpectrum)
boolAccessor(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor(showLibraryHit, setShowLibraryHit)
intAccessor(showPeaks, setShowPeaks)	
idAccessor(printAccessoryView, setPrintAccessoryView);

@end
