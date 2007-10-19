//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKMainWindowController.h"

#import "BDAlias.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKAppDelegate.h"
#import "JKChromatogram.h"
#import "JKGCMSDocument.h"
#import "JKLibraryEntry.h"
#import "JKMoleculeModel.h"
#import "JKMoleculeView.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "MyGraphView.h"
#import "RBSplitSubview.h"
#import "SpectrumGraphDataSerie.h"
#import "netcdf.h"
#include <unistd.h>


//static void *DocumentObservationContext = (void *)1100;
static void *ChromatogramObservationContext = (void *)1101;
static void *SpectrumObservationContext = (void *)1102;
static void *PeaksObservationContext = (void *)1103;
//static void *MetadataObservationContext = (void *)1104;

#define JKPeakRecordTableViewDataType @"JKPeakRecordTableViewDataType"
#define JKSearchResultTableViewDataType @"JKSearchResultTableViewDataType"
#define JKLibraryEntryTableViewDataType @"JKLibraryEntryTableViewDataType"

@implementation JKMainWindowController

#pragma mark Initialization & deallocation

- (id)init {
	self = [super initWithWindowNibName:@"JKGCMSDocument"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
		showTICTrace = YES;
		showCombinedSpectrum = NO;
		showLibraryHit = YES;
		showNormalizedSpectra = YES;
		showPeaks = JKAllPeaks;
        showSelectedChromatogramsOnly = YES;
        chromatogramDataSeries = [[NSMutableArray alloc] init];
        hiddenColumnsPeaksTable = [[NSMutableArray alloc] init];
       // [self setShouldCascadeWindows:NO];
	}
    return self;
}

- (void)dealloc {
    [searchResultsController removeObserver:self forKeyPath:@"selection"];
    [peakController removeObserver:self forKeyPath:@"selection"];
    [peakController removeObserver:self forKeyPath:@"selection.confirmed"];
    [peakController removeObserver:self forKeyPath:@"selection.identified"];
    [[self document] removeObserver:self forKeyPath:@"chromatograms"];
    [self removeObserver:self forKeyPath:@"showNormalizedSpectra"];
    [self removeObserver:self forKeyPath:@"showCombinedSpectrum"];
    [self removeObserver:self forKeyPath:@"showLibraryHit"];
    [self removeObserver:self forKeyPath:@"showTICTrace"];
    [self removeObserver:self forKeyPath:@"showSelectedChromatogramsOnly"];        

    // hack preventing an animating splitview to get deallocated whilst animating
    if ([RBSplitSubview animating]) {
        sleep(1);
    }
    [chromatogramDataSeries release];
    [hiddenColumnsPeaksTable release];
    [super dealloc];
}

- (void)windowDidLoad {
    JKLogEnteringMethod();
    
	// Setup the toolbar after the document nib has been loaded 
    [self setupToolbar];	

    [chromatogramView setDelegate:self];
    [spectrumView setDelegate:self];
    
    // Get the initial drawings for chromatograms
    [self observeValueForKeyPath:nil ofObject:nil change:nil context:ChromatogramObservationContext];

	// ChromatogramView bindings
    // Created chromatogram data series
    [self setupChromatogramDataSeries];

	[chromatogramView bind:@"dataSeries" toObject: chromatogramDataSeriesController
			   withKeyPath:@"arrangedObjects" options:nil];
	[chromatogramView bind:@"peaks" toObject: peakController
			   withKeyPath:@"arrangedObjects" options:nil];

	// SpectrumView bindings
	[spectrumView bind:@"dataSeries" toObject: spectrumDataSeriesController
		   withKeyPath:@"arrangedObjects" options:nil];

	// moleculeView bindings
	[moleculeView bind:@"moleculeString" toObject: searchResultsController
		   withKeyPath:@"selection.libraryHit.molString" options:nil];
	
	// More setup
	[chromatogramView setShouldDrawLegend:YES];
	[chromatogramView setKeyForXValue:@"Time"];
	[chromatogramView setKeyForYValue:@"Total Intensity"];
    [chromatogramView setShouldDrawLabels:NO];
    [chromatogramView setShouldDrawLabelsOnFrame:YES];
	[chromatogramView showAll:self];
    [chromatogramView setDrawingMode:JKStackedDrawingMode];
	
	[spectrumView setXMinimum:[NSNumber numberWithFloat:40]];
	[spectrumView setXMaximum:[NSNumber numberWithFloat:450]];
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
    [spectrumView setDrawingMode:JKNormalDrawingMode];

	// Register as observer
	[self addObserver:self forKeyPath:@"showNormalizedSpectra" options:0 context:SpectrumObservationContext];
	[self addObserver:self forKeyPath:@"showCombinedSpectrum" options:0 context:SpectrumObservationContext];
    [self addObserver:self forKeyPath:@"showLibraryHit" options:0 context:SpectrumObservationContext];
	[self addObserver:self forKeyPath:@"showTICTrace" options:0 context:ChromatogramObservationContext];
	[self addObserver:self forKeyPath:@"showSelectedChromatogramsOnly" options:0 context:ChromatogramObservationContext];

    [chromatogramsController addObserver:self forKeyPath:@"selection" options:0 context:ChromatogramObservationContext];
	[peakController addObserver:self forKeyPath:@"selection" options:0 context:PeaksObservationContext];
	[peakController addObserver:self forKeyPath:@"selection.countOfSearchResults" options:0 context:PeaksObservationContext];
	[peakController addObserver:self forKeyPath:@"selection.confirmed" options:0 context:PeaksObservationContext];
	[peakController addObserver:self forKeyPath:@"selection.identified" options:0 context:PeaksObservationContext];
	[searchResultsController addObserver:self forKeyPath:@"selection" options:0 context:SpectrumObservationContext];

	// Double click action
	[resultsTable setDoubleAction:@selector(resultDoubleClicked:)];
	
	// Drag and drop
	[peaksTable registerForDraggedTypes:[NSArray arrayWithObjects:JKLibraryEntryTableViewDataType, nil]];
	[resultsTable registerForDraggedTypes:[NSArray arrayWithObjects:JKLibraryEntryTableViewDataType, nil]];
	[chromatogramsTable registerForDraggedTypes:[NSArray arrayWithObjects:JKPeakRecordTableViewDataType, nil]];
	[peaksTable setDataSource:self];
	[resultsTable setDataSource:self];
	[chromatogramsTable setDataSource:self];
    
    NSTabViewItem *detailsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"details"];
    [detailsTabViewItem setView:detailsTabViewItemView];
    [detailsTabView addTabViewItem:detailsTabViewItem];
    NSTabViewItem *searchResultsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"searchResults"];
    [searchResultsTabViewItem setView:searchResultsTabViewItemView];
    [detailsTabView addTabViewItem:searchResultsTabViewItem];
    [moleculeSplitSubview setHidden:YES];
    [detailsSplitSubview setHidden:YES];
    [[detailsTabViewItemScrollView contentView] scrollToPoint:NSMakePoint(0.0f,1000.0f)];
    _lastDetailsSplitSubviewDimension = [detailsSplitSubview dimension];
    
    [[[peaksTable tableColumnWithIdentifier:@"id"] headerCell] setImage:[NSImage imageNamed:@"flagged_header"]];
    // 	[tableView setObligatoryTableColumns:[NSSet setWithObject:[tableView tableColumnWithIdentifier:@"name"]]];
    [[self window] setFrameFromString:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"mainWindowFrame"]];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[[self window] stringWithSavedFrame] forKey:@"mainWindowFrame"];
}
#pragma mark -

#pragma mark IBActions

- (IBAction)obtainBaseline:(id)sender {
    if ([[[self document] chromatograms] count] > 1) {
        // Run sheet to get selection
        [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Obtain Baseline",@"")];
        [chromatogramSelectionSheetButton setAction:@selector(obtainBaselineForSelectedChromatograms:)];
        [chromatogramSelectionSheetButton setTarget:self];
        [NSApp beginSheet: chromatogramSelectionSheet
           modalForWindow: [self window]
            modalDelegate: self
           didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
              contextInfo: nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        [[[self document] chromatograms] makeObjectsPerformSelector:@selector(obtainBaseline)];
        [chromatogramView setShouldDrawBaseline:YES];
    }
   
}

- (void)obtainBaselineForSelectedChromatograms:(id)sender {
    [[chromatogramsController selectedObjects] makeObjectsPerformSelector:@selector(obtainBaseline)];
	[chromatogramView setShouldDrawBaseline:YES];
    [NSApp endSheet:chromatogramSelectionSheet];
}

- (IBAction)cancel:(id)sender {
    [NSApp endSheet:chromatogramSelectionSheet];
}

- (IBAction)identifyPeaks:(id)sender {
    if ([[[self document] chromatograms] count] > 1) {
        // Run sheet to get selection
        [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Identify Peaks",@"")];
        [chromatogramSelectionSheetButton setAction:@selector(identifyPeaksForSelectedChromatograms:)];
        [chromatogramSelectionSheetButton setTarget:self];
        [NSApp beginSheet: chromatogramSelectionSheet
           modalForWindow: [self window]
            modalDelegate: self
           didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
              contextInfo: nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        [[[self document] chromatograms] makeObjectsPerformSelector:@selector(identifyPeaks)];
        [chromatogramView setShouldDrawPeaks:YES];
    }
}

- (void)identifyPeaksForSelectedChromatograms:(id)sender {
    [[chromatogramsController selectedObjects] makeObjectsPerformSelector:@selector(identifyPeaks)];
    [chromatogramView setShouldDrawPeaks:YES];
    [NSApp endSheet:chromatogramSelectionSheet];
}

- (IBAction)identifyCompounds:(id)sender {
    if ([[self document] searchDirection] == JKBackwardSearchDirection) {
        [NSThread detachNewThreadSelector:@selector(identifyCompounds) toTarget:self withObject:nil];
    } else if ([[[self document] chromatograms] count] > 1) {
        // Run sheet to get selection
        [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Identify Compounds",@"")];
        [chromatogramSelectionSheetButton setAction:@selector(identifyCompoundsForSelectedChromatograms:)];
        [chromatogramSelectionSheetButton setTarget:self];
        [NSApp beginSheet: chromatogramSelectionSheet
           modalForWindow: [self window]
            modalDelegate: self
           didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
              contextInfo: nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        // ensure the chromatogram is selected
        [chromatogramsController setSelectedObjects:[chromatogramsController arrangedObjects]];
        [NSThread detachNewThreadSelector:@selector(identifyCompounds) toTarget:self withObject:nil];
    }
}

- (void)identifyCompoundsForSelectedChromatograms:(id)sender {
    [NSApp endSheet:chromatogramSelectionSheet];
    [NSThread detachNewThreadSelector:@selector(identifyCompounds) toTarget:self withObject:nil];
}

- (void)identifyCompounds {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
		
	[[self document] performLibrarySearchForChromatograms:[chromatogramsController selectedObjects]];
	
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
	
	[pool release]; 
}

- (IBAction)removeChromatograms:(id)sender {
    // Run sheet to get selection
    [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Remove",@"")];
    [chromatogramSelectionSheetButton setAction:@selector(removeSelectedChromatograms:)];
    [chromatogramSelectionSheetButton setTarget:self];
    [NSApp beginSheet: chromatogramSelectionSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
}

- (void)removeSelectedChromatograms:(id)sender {
    // Make sure we don't delete TIC
    NSMutableIndexSet *indexes = [[chromatogramsController selectionIndexes] mutableCopy];
    [indexes removeIndex:0];
    [chromatogramsController removeObjectsAtArrangedObjectIndexes:indexes];
    [NSApp endSheet:chromatogramSelectionSheet];
}

- (IBAction)showMassChromatogram:(id)sender {	
	[[self document] addChromatogramForModel:[sender stringValue]];
    JKChromatogram *chrom = [[self document] chromatogramForModel:[sender stringValue]];
    if (chrom) {
        [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:chrom]];
        [sender setStringValue:@""];
    } else {
        NSBeep();
    }
}

- (void)showChromatogramForModel:(NSString *)modelString {
  	[[self document] addChromatogramForModel:modelString]; 
    JKChromatogram *chrom = [[self document] chromatogramForModel:modelString];
    if (chrom) {
        [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:chrom]];
    } else {
        NSBeep();
    }
}

- (void)addMassChromatogram:(id)object {
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(removeMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Add Mass Chromatogram",@"")];
	[chromatogramDataSeriesController addObject:object];	
}

- (void)removeMassChromatogram:(id)object {
	[[[self document] undoManager] registerUndoWithTarget:self
									  selector:@selector(addMassChromatogram:)
										object:object];
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Remove Mass Chromatogram",@"")];
	[chromatogramDataSeriesController removeObject:object];	
}

- (IBAction)renumberPeaks:(id)sender {
	[[self document] renumberPeaks];
}

- (IBAction)resetPeaks:(id)sender {
	[[self document] setPeaks:nil];
}

- (IBAction)combinePeaksAction:(id)sender{
	[[[self document] undoManager] setActionName:NSLocalizedString(@"Combine Peaks",@"")];
    if ([[[self peakController] selectedObjects] count] != NSNotFound) {
        if ([(JKChromatogram *)[[[peakController selectedObjects] objectAtIndex:0] chromatogram] combinePeaks:[peakController selectedObjects]]) {            
            [chromatogramView setNeedsDisplay:YES];
        }
    }
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

- (IBAction)showPeaksAction:(id)sender {
	if ([sender tag] == 1) {
		[self setShowPeaks:JKIdenitifiedPeaks];
	} else if ([sender tag] == 2) {
		[self setShowPeaks:JKUnidentifiedPeaks];
	} else if ([sender tag] == 3) {
		[self setShowPeaks:JKConfirmedPeaks];
	} else if ([sender tag] == 4) {
		[self setShowPeaks:JKUnconfirmedPeaks];
	} else if ([sender tag] == 5) {
		[self setShowPeaks:JKFlaggedPeaks];
	} else {
		[self setShowPeaks:JKAllPeaks];
	}
    [peakController setFilterPredicate:[self predicateForPeakTypeShow]];
    [chromatogramDataSeries makeObjectsPerformSelector:@selector(setFilterPredicate:) withObject:[self predicateForPeakTypeShow]];
}

-(NSString *)peakTypeShown
{
    // Value used in information field about peaks
    if ([self showPeaks] == JKAllPeaks) {
        return NSLocalizedString(@"", @"Value used in information field about peaks.");
    } else if ([self showPeaks] == JKIdenitifiedPeaks) {
        return NSLocalizedString(@"identified ", @"Value used in information field about peaks, requires trailing space.");
    } else if ([self showPeaks] == JKUnidentifiedPeaks) {
        return NSLocalizedString(@"unidentified ", @"Value used in information field about peaks, requires trailing space.");
    } else if ([self showPeaks] == JKConfirmedPeaks) {
        return NSLocalizedString(@"confirmed ", @"Value used in information field about peaks, requires trailing space.");
    } else if ([self showPeaks] == JKUnconfirmedPeaks) {
        return NSLocalizedString(@"unconfirmed ", @"Value used in information field about peaks, requires trailing space.");
    } else if ([self showPeaks] == JKFlaggedPeaks) {
        return NSLocalizedString(@"flagged ", @"Value used in information field about peaks, requires trailing space.");
    }
    return NSLocalizedString(@"",@"Value used in information field about peaks.");
}

- (NSPredicate *)predicateForPeakTypeShow
{
    // Value used in information field about peaks
    if ([self showPeaks] == JKAllPeaks) {
        return nil;
    } else if ([self showPeaks] == JKIdenitifiedPeaks) {
        return [NSPredicate predicateWithFormat:@"identified == YES"];
    } else if ([self showPeaks] == JKUnidentifiedPeaks) {
        return[NSPredicate predicateWithFormat:@"identified == NO"];
    } else if ([self showPeaks] == JKConfirmedPeaks) {
        return [NSPredicate predicateWithFormat:@"confirmed == YES"];
    } else if ([self showPeaks] == JKUnconfirmedPeaks) {
        return [NSPredicate predicateWithFormat:@"(identified == YES) AND (confirmed == NO)"];
    } else if ([self showPeaks] == JKFlaggedPeaks) {
        return [NSPredicate predicateWithFormat:@"flagged == YES"];
    }
    return nil;
}

- (IBAction)confirm:(id)sender {
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

- (IBAction)discard:(id)sender {
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

- (IBAction)next:(id)sender {
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] < [[peakController arrangedObjects] count]-1)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i+1]; 
	} else {
		[peakController setSelectionIndex:0]; 
	}
}

- (IBAction)previous:(id)sender {
	int i;
	if (([peakController selectionIndex] != NSNotFound) && ([peakController selectionIndex] > 0)){
		i = [peakController selectionIndex]; 
		[peakController setSelectionIndex:i-1]; 
	} else {
		[peakController setSelectionIndex:[[peakController arrangedObjects] count]-1]; 
	}
}



- (IBAction)other:(id)sender {
//    [NSApp beginSheet: addSheet
//	   modalForWindow: [self window]
//		modalDelegate: self
//	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
//		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}

- (IBAction)abort:(id)sender {
    [[self document] setAbortAction:YES];
}

- (IBAction)showTICTraceAction:(id)sender {
	if (showTICTrace) {
		[self setShowTICTrace:NO];
	} else {
		[self setShowTICTrace:YES];
	}
}

- (IBAction)showSpectrumAction:(id)sender {
	if (showCombinedSpectrum) {
		[self setShowCombinedSpectrum:NO];
	} else {
		[self setShowCombinedSpectrum:YES];
	}
}

- (IBAction)showChromatogramsTableAction:(id)sender {
    if ([chromatogramsTableSplitView isCollapsed] || [chromatogramsTableSplitView isHidden]) {
        [chromatogramsTableSplitView setHidden:NO];
        [chromatogramsTableSplitView expandWithAnimation];
    } else {
        [chromatogramsTableSplitView collapseWithAnimation];
    }
}

- (IBAction)showCombinedSpectrumAction:(id)sender {
	if (showCombinedSpectrum) {
		[self setShowCombinedSpectrum:NO];
	} else {
		[self setShowCombinedSpectrum:YES];
	}
}

- (IBAction)showNormalizedSpectraAction:(id)sender {
	if (showNormalizedSpectra) {
		[self setShowNormalizedSpectra:NO];
	} else {
		[self setShowNormalizedSpectra:YES];
	}
}

- (IBAction)showLibraryHitAction:(id)sender {
	if (showLibraryHit) {
		[self setShowLibraryHit:NO];
	} else {
		[self setShowLibraryHit:YES];
	}
}

- (IBAction)showSelectedChromatogramsOnlyAction:(id)sender {
	if (showSelectedChromatogramsOnly) {
		[self setShowSelectedChromatogramsOnly:NO];
	} else {
		[self setShowSelectedChromatogramsOnly:YES];
	}
}

- (IBAction)fitChromatogramDataToView:(id)sender {
	[chromatogramView showAll:self];
}
- (IBAction)fitSpectrumDataToView:(id)sender {
	[spectrumView showAll:self];
}

- (IBAction)resultDoubleClicked:(id)sender{
	JKPeakRecord *selectedPeak = [[peakController selectedObjects] objectAtIndex:0];
	[selectedPeak identifyAs:[[searchResultsController selectedObjects] objectAtIndex:0]];
	[selectedPeak confirm];
}

- (IBAction)showPreset:(id)sender{
	id preset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] objectAtIndex:[sender tag]];
	if ([preset valueForKey:@"massValue"]) {
		[[self document] addChromatogramForModel:[preset valueForKey:@"massValue"]];
        JKChromatogram *chrom = [[self document] chromatogramForModel:[preset valueForKey:@"massValue"]];
        if (chrom) {
            [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:chrom]];
            
        } else {
            NSBeep();
        }
        
	} 
}

- (IBAction)removeChromatogram:(id)sender{
    [[self document] willChangeValueForKey:@"chromatograms"];
	[[[self document] chromatograms] removeObjectAtIndex:[sender tag]];
    [[self document] didChangeValueForKey:@"chromatograms"];
}

- (void)showSpectrumForScan:(int)scan {
    if (scan > 0) {
        SpectrumGraphDataSerie *sgds = [[[SpectrumGraphDataSerie alloc] initWithSpectrum:[[self document] spectrumForScan:scan]] autorelease];
        if (showNormalizedSpectra) {
            [sgds setNormalizeYData:YES];
        }
        [spectrumDataSeriesController setContent:[NSMutableArray arrayWithObject:sgds]];
        [spectrumView setNeedsDisplay:YES];        
    }
}

- (IBAction)showPeakColumn:(id)sender {
    [peaksTable addTableColumn:[hiddenColumnsPeaksTable objectAtIndex:[sender tag]]];
    [hiddenColumnsPeaksTable removeObject:[hiddenColumnsPeaksTable objectAtIndex:[sender tag]]];
}

- (IBAction)hidePeakColumn:(id)sender {
    [hiddenColumnsPeaksTable addObject:[[peaksTable tableColumns] objectAtIndex:[sender tag]]];
    [peaksTable removeTableColumn:[[peaksTable tableColumns] objectAtIndex:[sender tag]]];
}

- (IBAction)removeUnidentifiedPeaksAction:(id)sender
{
    [[self document] removeUnidentifiedPeaks];
}
- (IBAction)identifyCompound:(id)sender
{
    [NSApp beginSheet: progressSheet
       modalForWindow: [self window]
        modalDelegate: self
       didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
          contextInfo: nil];
    
    
    JKPeakRecord *peak;
    peak = [[peakController selectedObjects] objectAtIndex:0];
    if (![(JKGCMSDocument *)[self document] performForwardSearchLibraryForPeak:peak]) {
        NSBeep();
    }	
    [self observeValueForKeyPath:@"selection.searchResults" ofObject:peakController change:nil context:PeaksObservationContext];
//    [resultsTable reloadData];
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
    
}

#pragma mark -

#pragma mark Key Value Observation
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
    // Disable updates
    if ([[self document] isBusy]) {
        return;
    }
    if (([keyPath isEqualToString:@"chromatograms"]) || (context == ChromatogramObservationContext) || ((object == peakController) && showSelectedChromatogramsOnly)) {
        // Created chromatogram data series
        [self setupChromatogramDataSeries];
    }
	if ((((object == peakController) | (object == searchResultsController)) && (([peakController selection] != NSNoSelectionMarker) && ([searchResultsController selection] != NSNoSelectionMarker))) || (context == SpectrumObservationContext)) {
        NSMutableArray *spectrumArray = [NSMutableArray array];
        
        // Present graphdataseries in colors
        NSColorList *peakColors = [NSColorList colorListNamed:@"Peacock Series"];
        if (peakColors == nil) {
            peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
        }
        NSArray *peakColorsArray = [peakColors allKeys];
        int peakColorsArrayCount = [peakColorsArray count];
        
        NSEnumerator *peakEnumerator = [[peakController selectedObjects] objectEnumerator];
        JKPeakRecord *peak;
        SpectrumGraphDataSerie *sgds;
        
        while ((peak = [peakEnumerator nextObject]) != nil) {
            if (showCombinedSpectrum) {
                sgds = [[[SpectrumGraphDataSerie alloc] initWithSpectrum:[peak combinedSpectrum]] autorelease];
            } else {
                sgds = [[[SpectrumGraphDataSerie alloc] initWithSpectrum:[peak spectrum]] autorelease];
            }
            if (showNormalizedSpectra) {
                [sgds setNormalizeYData:YES];
            }
            [sgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[spectrumArray count]%peakColorsArrayCount]]];
            [sgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Mass", @""), nil]];
            [sgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Intensity", @""), nil]];
            [spectrumArray addObject:sgds];
        }
        
        if (showLibraryHit) {
            NSEnumerator *searchResultEnumerator = [[searchResultsController selectedObjects] objectEnumerator];
            NSDictionary *searchResult;
            
            while ((searchResult = [searchResultEnumerator nextObject]) != nil) {
                sgds = [[[SpectrumGraphDataSerie alloc] initWithSpectrum:[searchResult valueForKey:@"libraryHit"]] autorelease];
                [sgds setDrawUpsideDown:YES];
                if (showNormalizedSpectra) {
                    [sgds setNormalizeYData:YES];
                }
                [sgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[spectrumArray count]%peakColorsArrayCount]]];
                [sgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Mass", @""), nil]];
                [sgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Intensity", @""), nil]];
                [spectrumArray addObject:sgds];
            }            
        }
        
		[spectrumDataSeriesController setContent:spectrumArray];
        
        // chromatogramView needs updating to reflect peak selection
		[chromatogramView setNeedsDisplay:YES];
        
        // spectrumView resizes to show all data
 //       [spectrumView showAll:self];
		[spectrumView setNeedsDisplay:YES];
    }
	if (context == ChromatogramObservationContext) {
		[chromatogramView setNeedsDisplay:YES];
	}
	if (context == SpectrumObservationContext) {
   //     [spectrumView showAll:self];
		[spectrumView setNeedsDisplay:YES];
	}
	if ([keyPath hasPrefix:@"metadata"]) {
		[self synchronizeWindowTitleWithDocumentName];
	}
    
    if ([[peakController selectedObjects] count] == 1) {
        if ([[[self peakController] valueForKeyPath:@"selection.identified"] boolValue]) {
            [detailsTabView selectTabViewItemWithIdentifier:@"details"];
            [detailsSplitSubview setMinDimension:250.0f andMaxDimension:400.0f];
            [detailsSplitSubview setDimension:_lastDetailsSplitSubviewDimension];
            [detailsSplitSubview setHidden:NO];
            [detailsSplitSubview expandWithAnimation:YES withResize:NO];
            if ([[searchResultsController selectedObjects] count] == 1) {
                NSString *molString = [[[[self searchResultsController] selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.molString"];
                if ((molString) && (![molString isEqualToString:@""])) {
                    //                    [moleculeView setModel:[[[JKMoleculeModel alloc] initWithMoleculeString:molString] autorelease]];
                    [moleculeSplitSubview setNeedsDisplay:YES];
                    [moleculeSplitSubview setHidden:NO];
                    [moleculeSplitSubview expandWithAnimation:YES withResize:NO];                                
                } else {
                    [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
                }                
            } else {
                [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
            } 
        } else if ([[peakController valueForKeyPath:@"selection.searchResults.@count"] intValue] >= 0) {
            [detailsTabView selectTabViewItemWithIdentifier:@"searchResults"];
            [detailsSplitSubview setHidden:NO];
            [detailsSplitSubview expandWithAnimation:YES withResize:NO];
            if ([[peakController valueForKeyPath:@"selection.searchResults.@count"] intValue] == 0) {
                // Show IdentifyCompoundBox
                _lastDetailsSplitSubviewDimension = [detailsSplitSubview dimension];
                [detailsSplitSubview setMinDimension:280.0f andMaxDimension:280.0f];
                [confirmLibraryHitButton setHidden:YES];
                [discardLibraryHitButton setHidden:YES];
                [resultsTableScrollView setHidden:YES];
                [identifyCompoundBox setHidden:NO];
                [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
            } else {
                [detailsSplitSubview setMinDimension:250.0f andMaxDimension:400.0f];
                [detailsSplitSubview setDimension:_lastDetailsSplitSubviewDimension];
                [identifyCompoundBox setHidden:YES];               
                [resultsTableScrollView setHidden:NO];
                [confirmLibraryHitButton setHidden:NO];
                [discardLibraryHitButton setHidden:NO];
                
                if ([[searchResultsController selectedObjects] count] == 1) {
                    NSString *molString = [[[[self searchResultsController] selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.molString"];
                    if ((molString) && (![molString isEqualToString:@""])) {
                        [moleculeSplitSubview setNeedsDisplay:YES];
                        [moleculeSplitSubview setHidden:NO];
                        [moleculeSplitSubview expandWithAnimation:YES withResize:NO];                                
                    } else {
                        [moleculeSplitSubview collapseWithAnimation:YES withResize:NO];
                    }  
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

- (void)setupChromatogramDataSeries
{
    // Present graphdataseries in colors
    NSColorList *peakColors = [NSColorList colorListNamed:@"Peacock Series"];
    if (peakColors == nil) {
        peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
    }
    NSArray *peakColorsArray = [peakColors allKeys];
    int peakColorsArrayCount = [peakColorsArray count];
    int prevCount = [chromatogramDataSeries count];
    
    [chromatogramDataSeries removeAllObjects];
    NSEnumerator *chromatogramEnumerator = [[[self document] chromatograms] objectEnumerator];
    JKChromatogram *chromatogram;
    
    while ((chromatogram = [chromatogramEnumerator nextObject]) != nil) {
        if ([chromatogramsTableSplitView isCollapsed]) {
            if ( (!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
                 (!showTICTrace && showSelectedChromatogramsOnly && ([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
                 (showTICTrace && !showSelectedChromatogramsOnly) ||
                 (showTICTrace && showSelectedChromatogramsOnly && (([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"])) ) {
                
                ChromatogramGraphDataSerie *cgds = [[[ChromatogramGraphDataSerie alloc] initWithChromatogram:chromatogram] autorelease];
                [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
                [cgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Retention Index", @""), NSLocalizedString(@"Scan", @""), NSLocalizedString(@"Time", @""), nil]];
                [cgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Total Intensity", @""), nil]];                    
                [chromatogramDataSeries addObject:cgds];                    
            }                    
        } else {
            if ( (!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
                 (!showTICTrace && showSelectedChromatogramsOnly && ([[[chromatogramsController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
                 (showTICTrace && !showSelectedChromatogramsOnly) ||
                 (showTICTrace && showSelectedChromatogramsOnly && (([[[chromatogramsController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"])) ) {
                
                ChromatogramGraphDataSerie *cgds = [[[ChromatogramGraphDataSerie alloc] initWithChromatogram:chromatogram] autorelease];
                [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
                [cgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Retention Index", @""), NSLocalizedString(@"Scan", @""), NSLocalizedString(@"Time", @""), nil]];
                [cgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Total Intensity", @""), nil]];
                [chromatogramDataSeries addObject:cgds];                    
            }                                        
        }
        
        //               if ((!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
        //                    (!showTICTrace && showSelectedChromatogramsOnly && ([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
        //                    (showTICTrace && !showSelectedChromatogramsOnly) ||
        //                    (showTICTrace && showSelectedChromatogramsOnly && (([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"]))) {
        //                    ChromatogramGraphDataSerie *cgds = [[[ChromatogramGraphDataSerie alloc] initWithChromatogram:chromatogram] autorelease];
        //                    [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
        //                    [chromatogramDataSeries addObject:cgds];                    
        //                }
    }
    
    [chromatogramDataSeries makeObjectsPerformSelector:@selector(setFilterPredicate:) withObject:[self predicateForPeakTypeShow]];

    [chromatogramView scaleVertically];
    
    // this should actually be done in MyGraphView
    int newCount = [chromatogramDataSeries count];
    switch ([chromatogramView drawingMode]) {
        case JKStackedDrawingMode:
            if (prevCount < newCount) {
                [chromatogramView setYMaximum:[NSNumber numberWithFloat:([[chromatogramView yMaximum] floatValue] + [[chromatogramView yMaximum] floatValue] /prevCount)]];
            } else if (prevCount > newCount) {
                [chromatogramView setYMaximum:[NSNumber numberWithFloat:([[chromatogramView yMaximum] floatValue] - [[chromatogramView yMaximum] floatValue] /prevCount)]];
            } 
            break;
        case JKNormalDrawingMode:
        default:            
            break;
    }
    [chromatogramView setNeedsDisplay:YES];
}
#pragma mark -

#pragma mark Splitview Delegate Methods
- (void)splitView:(RBSplitView*)sender didCollapse:(RBSplitSubview*)subview {
    if ((subview == detailsSplitSubview) || (subview == moleculeSplitSubview)) {
        [self performSelector:@selector(hideSubView:) withObject:subview afterDelay:0.0];
    } 
    if (subview == chromatogramsTableSplitView) {
        [self performSelector:@selector(hideSubView:) withObject:subview afterDelay:0.0];
        [chromatogramsController setSelectedObjects:[chromatogramsController arrangedObjects]];
    }
}
- (void)splitView:(RBSplitView*)sender didExpand:(RBSplitSubview*)subview {
    if (subview == chromatogramsTableSplitView) {
        if ([[peakController selectedObjects] count] > 0) {
            NSMutableArray *chromsToSelect = [NSMutableArray array];
            NSEnumerator *peakEnum = [[peakController selectedObjects] objectEnumerator];
            JKPeakRecord *peak;
            while ((peak = [peakEnum nextObject]) != nil) {
                [chromsToSelect addObject:[[self document] chromatogramForModel:[peak model]]];
            }
            [chromatogramsController setSelectedObjects:chromsToSelect];            
        } else {
            [chromatogramsController setSelectedObjects:[NSArray arrayWithObject:[[self document] ticChromatogram]]];
        }
        
    }
}

- (void)hideSubView:(RBSplitSubview*)subview {
    if (subview)
        [subview setHidden:YES];
}
#pragma mark -

#pragma mark NSToolbar Management

- (void)setupToolbar {
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

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
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

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Save Document Item Identifier", NSToolbarPrintItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier", NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier, @"Inspector", nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:  @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier",  @"Save Document Item Identifier", NSToolbarPrintItemIdentifier, @"Inspector",
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		[addedItem setToolTip:NSLocalizedString(@"Print Your Document",@"")];
		//	[addedItem setTarget: self];
    }
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
	//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
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
#pragma mark -

#pragma mark Undo Management
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
}
#pragma mark -

#pragma mark Accessors
- (MyGraphView *)chromatogramView {
    return chromatogramView;
}

- (MyGraphView *)spectrumView {
    return spectrumView;
}

- (NSArrayController *)chromatogramDataSeriesController {
    return chromatogramDataSeriesController;
}

- (NSTableView *)peaksTable {
	return peaksTable;
}

- (NSArrayController *)peakController {
    return peakController;
}

- (NSArrayController *)chromatogramsController {
    return chromatogramsController;
}

- (NSTableView *)resultsTable {
	return resultsTable;
}


- (NSArrayController *)searchResultsController {
    return searchResultsController;
}

- (NSProgressIndicator *)progressIndicator{
	return progressBar;
}

- (NSTextField *)progressText {
    return progressText;
}

- (NSMutableArray *)hiddenColumnsPeaksTable {
    return hiddenColumnsPeaksTable;
}
#pragma mark -

#pragma mark Sheets
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

#pragma mark Menu/Window Handling
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	if ([anItem action] == @selector(showTICTraceAction:)) {
		if (showTICTrace) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showSpectrumAction:)) {
		if (!showCombinedSpectrum) {
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
	} else if ([anItem action] == @selector(showSelectedChromatogramsOnlyAction:)) {
		if (showSelectedChromatogramsOnly) {
			[anItem setState:NSOnState];
		} else {
			[anItem setState:NSOffState];
		}
		return YES;
	} else if ([anItem action] == @selector(showChromatogramsTableAction:)) {
		if (![chromatogramsTableSplitView isCollapsed]) {
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
		if ([[[self peakController] selectedObjects] count] >= 1) {
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

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
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
#pragma mark -

#pragma mark Drag 'n Drop
- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {
    if (tv == peaksTable) {
        if ([rowIndexes count] < 1) {
            return NO;
        }
        
        // declare our own pasteboard types
        [pboard declareTypes:[NSArray arrayWithObject:JKPeakRecordTableViewDataType] owner:self];
  
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:[[peakController arrangedObjects] objectsAtIndexes:rowIndexes] forKey:JKPeakRecordTableViewDataType];
        [archiver finishEncoding];
        [archiver release];
        
        [pboard setData:data forType:JKPeakRecordTableViewDataType];
        
        return YES;
    } else if (tv == resultsTable) {
        if ([rowIndexes count] != 1) {
            return NO;
        }

        // declare our own pasteboard types
        NSArray *typesArray = [NSArray arrayWithObjects:JKLibraryEntryTableViewDataType, nil];
        [pboard declareTypes:typesArray owner:self];

        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:[[[searchResultsController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] libraryHit] forKey:JKLibraryEntryTableViewDataType];
        [archiver finishEncoding];
        [archiver release];

        [pboard setData:data forType:JKLibraryEntryTableViewDataType];

        return YES;
	}
	return NO;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation{
	
	if (tv == chromatogramsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKPeakRecordTableViewDataType]]){
            // Add peaks to target chromatogram
            JKChromatogram *chrom = [[chromatogramsController arrangedObjects] objectAtIndex:row];
            
            NSData *data = [[info draggingPasteboard] dataForType:JKPeakRecordTableViewDataType];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            NSArray *peaks = [unarchiver decodeObjectForKey:JKPeakRecordTableViewDataType];
            [unarchiver finishDecoding];
            [unarchiver release];

            NSEnumerator *enumerator = [peaks objectEnumerator];
            JKPeakRecord *peak = nil;
//            JKPeakRecord *newPeak = nil;
            while ((peak = [enumerator nextObject]) != nil) {
                [[peak chromatogram] removeObjectFromPeaksAtIndex:[[[peak chromatogram] peaks] indexOfObject:peak]];
                [chrom insertObject:peak inPeaksAtIndex:[chrom countOfPeaks]];
            }
            return YES;
        }
    } else if (tv == peaksTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKLibraryEntryTableViewDataType]]) {
            // Add the library entry to the peak
            JKPeakRecord *peak = [[peakController arrangedObjects] objectAtIndex:row];
            
            NSData *data = [[info draggingPasteboard] dataForType:JKLibraryEntryTableViewDataType];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            [unarchiver setClass:[JKLibraryEntry class] forClassName:@"JKManagedLibraryEntry"];
            JKLibraryEntry *libEntry = [unarchiver decodeObjectForKey:JKLibraryEntryTableViewDataType];
            [unarchiver finishDecoding];
            [unarchiver release];
            if ([peak identifyAsLibraryEntry:libEntry]) {
                [peak confirm];
                return YES;
            } else {
                return NO;
            }
		}	
	} else if (tv == resultsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKLibraryEntryTableViewDataType]]) {
            // Add the library entry to the peak
            if ([[peakController selectedObjects] count] != 1) {
                return NO;
            }
            JKPeakRecord *peak = [[peakController selectedObjects] objectAtIndex:0];
            
            NSData *data = [[info draggingPasteboard] dataForType:JKLibraryEntryTableViewDataType];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            [unarchiver setClass:[JKLibraryEntry class] forClassName:@"JKManagedLibraryEntry"];
            JKLibraryEntry *libEntry = [unarchiver decodeObjectForKey:JKLibraryEntryTableViewDataType];
            [unarchiver finishDecoding];
            [unarchiver release];
            if ([peak addSearchResultForLibraryEntry:libEntry]) {
                return YES;
            } else {
                return NO;
            }
  		}	
    }
    return NO;    
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == chromatogramsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKPeakRecordTableViewDataType]]){
            [tv setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
        }
    } else if (tv == peaksTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKLibraryEntryTableViewDataType]]) {
			[tv setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		}	
	} else 	if (tv == resultsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:JKLibraryEntryTableViewDataType]]) {
			[tv setDropRow:row dropOperation:NSTableViewDropAbove];
			return NSDragOperationMove;
		}
    }
    return NSDragOperationNone;    
}
#pragma mark -

#pragma mark Data source for pulldown menu label 
- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString *)uncompletedString {
    NSEnumerator *entriesEnumerator;
    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
        entriesEnumerator = [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] objectEnumerator];
    } else {
        entriesEnumerator = [[[NSApp delegate] autocompleteEntries] objectEnumerator];
    }
    NSString *entry;

    while ((entry = [entriesEnumerator nextObject]) != nil) {
    	if ([entry hasPrefix:uncompletedString]) {
            return entry;
        }
    }
    return nil;
}
- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)aString {
    int i, count;
    NSArray *autocompleteArray;
    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
        autocompleteArray = [[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]];
    } else {
        autocompleteArray = [[NSApp delegate] autocompleteEntries];
    }
    count = [autocompleteArray count];
    for (i = 0; i < count; i++) {
        if ([[autocompleteArray objectAtIndex:i] isEqualToString:aString]) {
            return i;
        }
    }
    return NSNotFound;
    
}
- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(int)index {
    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
        return [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] objectAtIndex:index];
    } else {
        return [[[NSApp delegate] autocompleteEntries] objectAtIndex:index];
    }
}
- (int)numberOfItemsInComboBoxCell:(NSComboBoxCell *)aComboBoxCell {
    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
        return [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] count];
   } else {
        return [[[NSApp delegate] autocompleteEntries] count];
    }
}
#pragma mark -

#pragma mark Accessors 
#pragma mark (macrostyle)
boolAccessor(abortAction, setAbortAction)
boolAccessor(showTICTrace, setShowTICTrace)
boolAccessor(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor(showLibraryHit, setShowLibraryHit)
boolAccessor(showSelectedChromatogramsOnly, setShowSelectedChromatogramsOnly)
intAccessor(showPeaks, setShowPeaks)	
idAccessor(printAccessoryView, setPrintAccessoryView)
idAccessor(chromatogramDataSeries, setChromatogramDataSeries)

@end
