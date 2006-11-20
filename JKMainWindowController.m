//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKMainWindowController.h"
#import "JKMoleculeView.h"
#import "JKMoleculeModel.h"
#import "BDAlias.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKGCMSDocument.h"
#import "JKLibraryEntry.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "MyGraphView.h"
#import "SpectrumGraphDataSerie.h"
#import "netcdf.h"
#import "RBSplitSubview.h"
#include <unistd.h>

//static void *DocumentObservationContext = (void *)1100;
static void *ChromatogramObservationContext = (void *)1101;
static void *SpectrumObservationContext = (void *)1102;
//static void *PeaksObservationContext = (void *)1103;

#define JKPeakRecordTableViewDataType @"JKPeakRecordTableViewDataType"
#define JKSearchResultTableViewDataType @"JKSearchResultTableViewDataType"
#define JKLibraryEntryTableViewDataType @"JKLibraryEntryTableViewDataType"

@implementation JKMainWindowController

#pragma mark INITIALIZATION

- (id)init  
{
	self = [super initWithWindowNibName:@"JKGCMSDocument"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];

		showTICTrace = YES;
		showSpectrum = YES;
		showCombinedSpectrum = NO;
		showLibraryHit = YES;
		showNormalizedSpectra = YES;
		showPeaks = JKAllPeaks;
	}
    return self;
}

- (void)windowDidLoad  
{
	// Setup the toolbar after the document nib has been loaded 
    [self setupToolbar];	

    [chromatogramView setDelegate:self];
    
	// ChromatogramView bindings
	[chromatogramView bind:@"dataSeries" toObject: chromatogramDataSeriesController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"baseline" toObject: baselineController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"peaks" toObject: peakController
			   withKeyPath:@"arrangedObjects" options:nil];
	NSAssert([[chromatogramView dataSeries] count] > 0, @"No chromatogram dataseries to draw.");
	if ([[chromatogramView dataSeries] objectAtIndex:0]) {
		[[[chromatogramView dataSeries] objectAtIndex:0] bind:@"peaks" toObject: peakController
												  withKeyPath:@"arrangedObjects" options:nil];
	}
	
	// SpectrumView bindings
	[spectrumView bind:@"dataSeries" toObject: spectrumDataSeriesController
		   withKeyPath:@"arrangedObjects" options:nil];
	
	// More setup
	[chromatogramView setShouldDrawLegend:YES];
	[chromatogramView setKeyForXValue:@"Time"];
	[chromatogramView setKeyForYValue:@"Total Intensity"];
    [chromatogramView setShouldDrawLabels:NO];
    [chromatogramView setShouldDrawLabelsOnFrame:YES];
	[chromatogramView showAll:self];
	
	[spectrumView setXMinimum:[NSNumber numberWithFloat:0]];
	[spectrumView setXMaximum:[NSNumber numberWithFloat:650]];
	[spectrumView setYMinimum:[NSNumber numberWithFloat:-1.1]];
	[spectrumView setYMaximum:[NSNumber numberWithFloat:1.1]];
	[spectrumView setShouldDrawLegend:YES];
	[spectrumView setShouldDrawFrame:YES];
	[spectrumView setShouldDrawFrameBottom:NO];
    [spectrumView setShouldDrawLabels:NO];
    [spectrumView setShouldDrawLabelsOnFrame:YES];
    [spectrumView setShouldDrawAxes:YES];
    [spectrumView setShouldDrawAxesVertical:NO];
    [spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];

	// Register as observer
	[searchResultsController addObserver:self forKeyPath:@"selection" options:nil context:nil];
	[peakController addObserver:self forKeyPath:@"selection" options:nil context:nil];
		
	// Double click action
	[resultsTable setDoubleAction:@selector(resultDoubleClicked:)];
	
	// Drag and drop
	[peaksTable registerForDraggedTypes:[NSArray arrayWithObjects:JKPeakRecordTableViewDataType, JKSearchResultTableViewDataType, nil]];
	[peaksTable setDataSource:self];
	[peaksTable setDraggingSourceOperationMask:NSDragOperationMove|NSDragOperationDelete forLocal:YES];
	[peaksTable setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationDelete forLocal:NO];
	[resultsTable registerForDraggedTypes:[NSArray arrayWithObject:JKSearchResultTableViewDataType]];
	[resultsTable setDataSource:self];
	[resultsTable setDraggingSourceOperationMask:NSDragOperationMove|NSDragOperationDelete forLocal:YES];
	[resultsTable setDraggingSourceOperationMask:NSDragOperationCopy|NSDragOperationDelete forLocal:NO];
    
    NSTabViewItem *detailsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"details"];
    [detailsTabViewItem setView:detailsTabViewItemView];
    [detailsTabView addTabViewItem:detailsTabViewItem];
    NSTabViewItem *searchResultsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"searchResults"];
    [searchResultsTabViewItem setView:searchResultsTabViewItemView];
    [detailsTabView addTabViewItem:searchResultsTabViewItem];
    [moleculeSplitSubview setHidden:YES];
    [detailsSplitSubview setHidden:YES];
}

- (void)dealloc  
{
	[searchResultsController removeObserver:self forKeyPath:@"selection"];
	[peakController removeObserver:self forKeyPath:@"selection"];
    // hack preventing an animating splitview to get deallocated whilst animating
    if ([RBSplitSubview animating]) {
        sleep(1);
    }
    [super dealloc];
}

#pragma mark IBACTIONS

- (IBAction)obtainBaseline:(id)sender 
{
	[[self document] obtainBaseline];
	[chromatogramView setShouldDrawBaseline:YES];
}


- (IBAction)identifyPeaks:(id)sender 
{
	[[self document] identifyPeaks];
}

- (IBAction)identifyCompounds:(id)sender 
{
	[NSThread detachNewThreadSelector:@selector(identifyCompounds) toTarget:self withObject:nil];
}

- (void)identifyCompounds 
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
		
	[[self document] searchLibraryForAllPeaks:self];
	
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
	
	[pool release]; 
}

- (IBAction)showMassChromatogram:(id)sender {	
	[[self document] addChromatogramForMass:[sender stringValue]];

	[sender setStringValue:@""];
}

- (void)addMassChromatogram:(id)object  
{
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(removeMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Add Mass Chromatogram",@"")];
	[chromatogramDataSeriesController addObject:object];	
}

- (void)removeMassChromatogram:(id)object  
{
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(addMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Mass Chromatogram",@"")];
	[chromatogramDataSeriesController removeObject:object];	
}

- (IBAction)renumberPeaks:(id)sender  
{
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

- (void)undoRenumberPeaks:(NSArray *)array  
{
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

//- (IBAction)resetPeaks:(id)sender  
//{
//	int i;
//	int peakCount = [[peakController arrangedObjects] count];
//	NSMutableArray *array = [NSMutableArray array];
//	for (i = 0; i < peakCount; i++) {
//		id object = [[peakController arrangedObjects] objectAtIndex:i];
//		
//		// Undo preparation
//		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
//		[mutDict setObject:object forKey:@"peakrecord"];
//		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
//		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
//		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
//		[mutDict setValue:[object libraryHit] forKey:@"libraryHit"];
//		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
//		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
//		[array addObject:mutDict];
//		
//		// The real thing
//		[object setValue:@"" forKey:@"label"];
//		[object setValue:@"" forKey:@"score"];
//		[object setValue:@"" forKey:@"symbol"];
//		[object setLibraryHit:[[[JKLibraryEntry alloc] init] autorelease]];
//		[object setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
//		[object setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];		
//	}	
//	[[[self document] undoManager] registerUndoWithTarget:self
//												 selector:@selector(undoResetPeaks:)
//												   object:array];
//	[[[self document] undoManager] setActionName:NSLocalizedString(@"Reset Peaks",@"")];
//	
//}
//- (void)undoResetPeaks:(NSArray *)array  
//{
//	int i;
//	int peakCount = [[peakController arrangedObjects] count];
//	NSMutableArray *arrayOut = [NSMutableArray array];
//	for (i = 0; i < peakCount; i++) {
//		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
//		
//		// Redo preparation
//		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
//		[mutDict setObject:object forKey:@"peakrecord"];
//		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
//		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
//		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
//		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
//		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
//		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
//		[arrayOut addObject:mutDict];
//		
//		// Reading back what was changed
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
//		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
//		
//	}	
//	[[[self document] undoManager] registerUndoWithTarget:self
//												 selector:@selector(undoResetPeaks:)
//												   object:arrayOut];
//	[[[self document] undoManager] setActionName:NSLocalizedString(@"Reset Peaks",@"")];
//	
//}

- (IBAction)showPeaksAction:(id)sender  
{
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

- (IBAction)confirm:(id)sender  
{
#warning [BUG] UI not updated to reflect this change
	NSEnumerator *enumerator = [[peakController selectedObjects] objectEnumerator];
	id peak;
	
	while ((peak = [enumerator nextObject])) {
		if ([peak identified]) {
			[peak confirm];
		} else if ([[searchResultsController selectedObjects] count] == 1) {
			[peak identifyAs:[[searchResultsController selectedObjects] objectAtIndex:0]];
			[peak confirm];
		} else {
            [peak confirm];
        }
	}
}

//- (void)undoConfirm:(NSArray *)array  
//{
//	int i;
//	int count = [array count];
//	NSMutableArray *arrayOut = [NSMutableArray array];
//	for (i = 0; i < count; i++) {
//		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
//		
//		// Redo preparation
//		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
//		[mutDict setObject:object forKey:@"peakrecord"];
//		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
//		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
//		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
//		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
//		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
//		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
//		[arrayOut addObject:mutDict];
//		
//		// Reading back what was changed
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
//		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
//		
//	}	
//	[[[self document] undoManager] registerUndoWithTarget:self
//												 selector:@selector(undoConfirm:)
//												   object:arrayOut];
//	[[[self document] undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit(s)",@"")];
//	
//}

- (IBAction)discard:(id)sender  
{
	NSEnumerator *enumerator = [[peakController selectedObjects] objectEnumerator];
	id peak;
	
	while ((peak = [enumerator nextObject])) {
//		if ([peak identified]) {
			[peak discard];
//		} 
	}
}

//- (void)undoDiscard:(NSArray *)array  
//{
//	int i;
//	int count = [array count];
//	NSMutableArray *arrayOut = [NSMutableArray array];
//	for (i = 0; i < count; i++) {
//		id object = [[array objectAtIndex:i] objectForKey:@"peakrecord"];
//		
//		// Redo preparation
//		NSMutableDictionary *mutDict = [NSMutableDictionary dictionary];
//		[mutDict setObject:object forKey:@"peakrecord"];
//		[mutDict setValue:[object valueForKey:@"label"] forKey:@"label"];
//		[mutDict setValue:[object valueForKey:@"score"] forKey:@"score"];
//		[mutDict setValue:[object valueForKey:@"symbol"] forKey:@"symbol"];
//		[mutDict setValue:[object valueForKey:@"libraryHit"] forKey:@"libraryHit"];
//		[mutDict setValue:[object valueForKey:@"identified"] forKey:@"identified"];
//		[mutDict setValue:[object valueForKey:@"confirmed"] forKey:@"confirmed"];
//		[arrayOut addObject:mutDict];
//		
//		// Reading back what was changed
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"label"] forKey:@"label"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"score"] forKey:@"score"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"symbol"] forKey:@"symbol"];
//		[object setLibraryHit:[[array objectAtIndex:i] valueForKey:@"libraryHit"]];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"identified"] forKey:@"identified"];
//		[object setValue:[[array objectAtIndex:i] valueForKey:@"confirmed"] forKey:@"confirmed"];
//		
//	}	
//	[[[self document] undoManager] registerUndoWithTarget:self
//												 selector:@selector(undoConfirm:)
//												   object:arrayOut];
//	[[[self document] undoManager] setActionName:NSLocalizedString(@"Discard Library Hit",@"")];
//	
//}

- (IBAction)next:(id)sender 
{
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] < [[peakController arrangedObjects] count]-1)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i+1]; 
	} else {
		[peakController setSelectionIndex:0]; 
	}
}

- (IBAction)previous:(id)sender 
{
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] > 0)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i-1]; 
	} else {
		[peakController setSelectionIndex:[[peakController arrangedObjects] count]-1]; 
	}
}



- (IBAction)other:(id)sender 
{
//    [NSApp beginSheet: addSheet
//	   modalForWindow: [self window]
//		modalDelegate: self
//	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}

- (IBAction)abort:(id)sender  
{
    [[self document] setAbortAction:YES];
}

- (IBAction)showTICTraceAction:(id)sender  
{
	if (showTICTrace) {
		[self setShowTICTrace:NO];
	} else {
		[self setShowTICTrace:YES];
	}
}

- (IBAction)showSpectrumAction:(id)sender  
{
	if (showSpectrum) {
		[self setShowSpectrum:NO];
		[self setShowCombinedSpectrum:YES];
	} else {
		[self setShowSpectrum:YES];
		[self setShowCombinedSpectrum:NO];
	}
}

- (IBAction)showCombinedSpectrumAction:(id)sender  
{
	if (showCombinedSpectrum) {
		[self setShowCombinedSpectrum:NO];
		[self setShowSpectrum:YES];
	} else {
		[self setShowCombinedSpectrum:YES];
		[self setShowSpectrum:NO];
	}
}

- (IBAction)showNormalizedSpectraAction:(id)sender  
{
	if (showNormalizedSpectra) {
		[self setShowNormalizedSpectra:NO];
	} else {
		[self setShowNormalizedSpectra:YES];
	}
}

- (IBAction)showLibraryHitAction:(id)sender  
{
	if (showLibraryHit) {
		[self setShowLibraryHit:NO];
	} else {
		[self setShowLibraryHit:YES];
	}
}
- (IBAction)editLibrary:(id)sender  
{
	NSError *error = [[NSError alloc] init];
	[[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[[self document] libraryAlias] fullPath]] display:YES error:&error];
	[error release];
}

- (IBAction)fitChromatogramDataToView:(id)sender  
{
	[chromatogramView showAll:self];
}
- (IBAction)fitSpectrumDataToView:(id)sender  
{
	[spectrumView showAll:self];
}

- (IBAction)resultDoubleClicked:(id)sender
{
	JKPeakRecord *selectedPeak = [[peakController selectedObjects] objectAtIndex:0];
	[selectedPeak identifyAs:[[searchResultsController selectedObjects] objectAtIndex:0]];
	[selectedPeak confirm];
}

- (IBAction)showPreset:(id)sender
{
	id preset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] objectAtIndex:[sender tag]];
	if ([preset valueForKey:@"massValue"]) {
		[[self document] addChromatogramForMass:[preset valueForKey:@"massValue"]];
	} 
}

- (IBAction)removeChromatogram:(id)sender
{
    [[self document] willChangeValueForKey:@"chromatograms"];
	[[[self document] chromatograms] removeObjectAtIndex:[sender tag]];
    [[self document] didChangeValueForKey:@"chromatograms"];
}

- (void)showSpectrumForScan:(int)scan {
    if (scan > 0) {
        [spectrumDataSeriesController setContent:[NSArray arrayWithObject:[[self document] spectrumForScan:scan]]];
        [spectrumView setNeedsDisplay:YES];        
    }
}

#pragma mark KEY VALUE OBSERVATION

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if (((object == peakController) | (object == searchResultsController)) && (([peakController selection] != NSNoSelectionMarker) && ([searchResultsController selection] != NSNoSelectionMarker))) {
		NSArray *peakArray = [[peakController selectedObjects] valueForKeyPath:@"spectrum.spectrumDataSerie"];
		NSArray *searchResultsArray = [[searchResultsController selectedObjects] valueForKeyPath:@"libraryHit.spectrumDataSerieUpsideDown"];
		[spectrumDataSeriesController setContent:[peakArray arrayByAddingObjectsFromArray:searchResultsArray]];
		[chromatogramView setNeedsDisplay:YES];
        [spectrumView showAll:self];
    }
	if (context == ChromatogramObservationContext) {
		[chromatogramView setNeedsDisplay:YES];
	}
	if (context == SpectrumObservationContext) {
		[spectrumView setNeedsDisplay:YES];
	}
	if ([keyPath hasPrefix:@"metadata"]) {
		[self synchronizeWindowTitleWithDocumentName];
	}

    if ([[peakController selectedObjects] count] == 1) {
        if ([[[self peakController] valueForKeyPath:@"selection.identified"] boolValue]) {
            [detailsTabView selectTabViewItemWithIdentifier:@"details"];
            [detailsSplitSubview setHidden:NO];
            [detailsSplitSubview expandWithAnimation:YES withResize:NO];
            if ([[searchResultsController selectedObjects] count] == 1) {
                NSString *molString = [[[[self searchResultsController] selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.molString"];
                if ((molString) && (![molString isEqualToString:@""])) {
                    [moleculeView setModel:[[[JKMoleculeModel alloc] initWithMoleculeString:molString] autorelease]];
                    [moleculeSplitSubview setNeedsDisplay:YES];
                    [moleculeSplitSubview setHidden:NO];
                    [moleculeSplitSubview expandWithAnimation:YES withResize:NO];                                
                } else {
                    [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
                }                
            } else {
                [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
            } 
        } else if ([[peakController valueForKeyPath:@"selection.searchResults.@count"] intValue] >= 1) {
            [detailsTabView selectTabViewItemWithIdentifier:@"searchResults"];
            [detailsSplitSubview setHidden:NO];
            [detailsSplitSubview expandWithAnimation:YES withResize:NO];
            if ([[searchResultsController selectedObjects] count] == 1) {
                NSString *molString = [[[[self searchResultsController] selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.molString"];
                if ((molString) && (![molString isEqualToString:@""])) {
                    [moleculeView setModel:[[[JKMoleculeModel alloc] initWithMoleculeString:molString] autorelease]];
                    [moleculeSplitSubview setNeedsDisplay:YES];
                    [moleculeSplitSubview setHidden:NO];
                    [moleculeSplitSubview expandWithAnimation:YES withResize:NO];                                
                } else {
                    [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
                }  
            }
        } else {
            [detailsSplitSubview collapseWithAnimation:YES withResize:NO];
            [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
        }
    } else {
            [detailsSplitSubview collapseWithAnimation:YES withResize:NO];
            [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
    }
}

#pragma mark SPLITVIEW DELEGATE METHODS
- (void)splitView:(RBSplitView*)sender didCollapse:(RBSplitSubview*)subview {
    if ((subview == detailsSplitSubview) || (subview == moleculeSplitSubview)) {
        [self performSelector:@selector(hideSubView:) withObject:subview afterDelay:0.0];
    }
}

- (void)hideSubView:(RBSplitSubview*)subview {
    if (subview)
        [subview setHidden:YES];
}

#pragma mark NSTOOLBAR MANAGEMENT

- (void)setupToolbar  
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"PeacockMainWindowToolbarIdentifier"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	//    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
	
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted  
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqual: @"Save Document Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Save",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Save",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Save Your Document",@"")];
		[toolbarItem setImage: [NSImage imageNamed:@"save_document"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: [self document]];
		[toolbarItem setAction: @selector(saveDocument:)];
    }  else if ([itemIdent isEqual: @"Identify Baseline Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Baseline",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Baseline",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the baseline in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Baseline"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(obtainBaseline:)];
    }   else if ([itemIdent isEqual: @"Identify Peaks Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Peaks",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Peaks",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Peaks"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(identifyPeaks:)];
    } else if ([itemIdent isEqual: @"Identify Compounds Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Compounds",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Compounds",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the compounds associated with the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Compounds"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(identifyCompounds:)];
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

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar  
{
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Save Document Item Identifier", NSToolbarPrintItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier", NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier, @"Inspector", nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar  
{
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:  @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier",  @"Save Document Item Identifier", NSToolbarPrintItemIdentifier, @"Inspector",
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif  
{
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

- (void) toolbarDidRemoveItem: (NSNotification *) notif  
{
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
	//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem  
{
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual: @"Save Document Item Identifier"]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
		enable = [[self document] isDocumentEdited];
		enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Baseline Item Identifier"]) {
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

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
}

#pragma mark ACCESSORS

- (MyGraphView *)chromatogramView  
{
    return chromatogramView;
}

- (NSArrayController *)chromatogramDataSeriesController  
{
    return chromatogramDataSeriesController;
}

- (NSArrayController *)baselineController  
{
    return baselineController;
}
- (NSTableView *)peaksTable  
{
	return peaksTable;
}

- (NSArrayController *)peakController  
{
    return peakController;
}

- (NSTableView *)resultsTable  
{
	return resultsTable;
}


- (NSArrayController *)searchResultsController  
{
    return searchResultsController;
}

- (NSProgressIndicator *)progressIndicator
{
	return progressBar;
}

#pragma mark SHEETS
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

#pragma mark MENU/WINDOW HANDLING

- (BOOL)validateMenuItem:(NSMenuItem *)anItem  
{
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

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName  
{
	if (![[self document] valueForKeyPath:@"metadata.sampleCode"] && ![[self document] valueForKeyPath:@"metadata.sampleDescription"]) {
		return displayName;
	} else if ([[self document] valueForKeyPath:@"metadata.sampleCode"] && [[self document] valueForKeyPath:@"metadata.sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@ - %@",[[self document] valueForKeyPath:@"metadata.sampleCode"], [[self document] valueForKeyPath:@"metadata.sampleDescription"] ];
	} else if (![[self document]valueForKeyPath:@"metadata.sampleCode"] && [[self document] valueForKeyPath:@"metadata.sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@",[[self document] valueForKeyPath:@"metadata.sampleDescription"] ];
	} else if ([[self document] valueForKeyPath:@"metadata.sampleCode"] && ![[self document] valueForKeyPath:@"metadata.sampleDescription"]) {
		return [displayName stringByAppendingFormat:@" - %@",[[self document] valueForKeyPath:@"metadata.sampleCode"] ];
	} else {
		return displayName;
	}
}

#pragma mark DRAG N DROP

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard 
{
	JKLogEnteringMethod();
    // Copy the row numbers to the pasteboard.
	if (tv == peaksTable) {
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
		[pboard declareTypes:[NSArray arrayWithObject:JKPeakRecordTableViewDataType] owner:self];
		[pboard setData:data forType:JKPeakRecordTableViewDataType];
		return YES;		
	} else if (tv == resultsTable) {
		NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
		[pboard declareTypes:[NSArray arrayWithObject:JKSearchResultTableViewDataType] owner:self];
		[pboard setData:data forType:JKSearchResultTableViewDataType];
		return YES;		
	}
	return NO;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{
	NSArray *supportedTypes = [NSArray arrayWithObjects: JKPeakRecordTableViewDataType, JKSearchResultTableViewDataType, JKLibraryEntryTableViewDataType, nil];
	NSString *availableType = [[info draggingPasteboard] availableTypeFromArray:supportedTypes];
	
	if (tv == peaksTable) {
		if (([availableType isEqualToString:JKPeakRecordTableViewDataType]) && ([info draggingSource] == tv)) {
			// Move the peaks to the appropriate place in the array
			//[info draggingSource] 
			return YES;
		} else if ([availableType isEqualToString:JKSearchResultTableViewDataType]) {
			// Add the search result to the peak
			// Recalculate score
			[[peakController arrangedObjects] objectAtIndex:row];
			return YES;
		} else if ([availableType isEqualToString:JKLibraryEntryTableViewDataType]) {
			// Add the library entry to the peak
			// Calculate score
			
			return YES;
		}	
	} else if (tv == resultsTable) {
		if ([availableType isEqualToString:JKSearchResultTableViewDataType]) {
			// Insert the search result
			// Recalculate score (to be sure)
			
			return YES;
		} else if ([availableType isEqualToString:JKLibraryEntryTableViewDataType]) {
			// Insert the library entry
			// Calculate score

			return YES;
		}
	}
    return NO;    
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op 
{
	NSArray *supportedTypes = [NSArray arrayWithObjects: JKPeakRecordTableViewDataType, JKSearchResultTableViewDataType, JKLibraryEntryTableViewDataType, nil];
	NSString *availableType = [[info draggingPasteboard] availableTypeFromArray:supportedTypes];
	
	if (tv == peaksTable) {
		if (([availableType isEqualToString:JKPeakRecordTableViewDataType]) && ([info draggingSource] == tv)) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		} else if ([availableType isEqualToString:JKSearchResultTableViewDataType]) {
			[tv setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		} else if ([availableType isEqualToString:JKLibraryEntryTableViewDataType]) {
			[tv setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		}	
	} else if (tv == resultsTable) {
		if ([availableType isEqualToString:JKSearchResultTableViewDataType]) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		} else if ([availableType isEqualToString:JKLibraryEntryTableViewDataType]) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationCopy;
		}
	}
    return NSDragOperationNone;    
}

#pragma mark ACCESSORS (MACROSTYLE)
boolAccessor(abortAction, setAbortAction)
boolAccessor(showTICTrace, setShowTICTrace)
boolAccessor(showSpectrum, setShowSpectrum)
boolAccessor(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor(showLibraryHit, setShowLibraryHit)
intAccessor(showPeaks, setShowPeaks)	
idAccessor(printAccessoryView, setPrintAccessoryView)

@end
