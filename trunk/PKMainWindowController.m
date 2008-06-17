//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKMainWindowController.h"

#import "PKChromatogramDataSeries.h"
#import "PKAppDelegate.h"
#import "PKChromatogram.h"
#import "PKGCMSDocument.h"
#import "PKLibraryEntry.h"
#import "PKMoleculeModel.h"
#import "PKMoleculeView.h"
#import "PKPeakRecord.h"
#import "PKSearchResult.h"
#import "PKSpectrum.h"
#import "PKGraphView.h"
#import "RBSplitSubview.h"
#import "PKSpectrumDataSeries.h"
#import "netcdf.h"
#include <unistd.h>


//static void *DocumentObservationContext = (void *)1100;
static void *ChromatogramObservationContext = (void *)1101;
static void *SpectrumObservationContext = (void *)1102;
static void *PeaksObservationContext = (void *)1103;
//static void *MetadataObservationContext = (void *)1104;

#define PKPeakRecordTableViewDataType @"PKPeakRecordTableViewDataType"
#define JKSearchResultTableViewDataType @"JKSearchResultTableViewDataType"
#define JKLibraryEntryTableViewDataType @"JKLibraryEntryTableViewDataType"

@implementation PKMainWindowController

#pragma mark Initialization & deallocation

- (id)init {
	self = [super initWithWindowNibName:@"PKGCMSDocument"];
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
	// Setup the toolbar after the document nib has been loaded 
    [self setupToolbar];	

    // We are the delegate for these views
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
	[peaksTable registerForDraggedTypes:[NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil]];
	[resultsTable registerForDraggedTypes:[NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil]];
	[chromatogramsTable registerForDraggedTypes:[NSArray arrayWithObjects:PKPeakRecordTableViewDataType, nil]];
	[peaksTable setDataSource:self];
	[resultsTable setDataSource:self];
	[chromatogramsTable setDataSource:self];
    
    NSTabViewItem *detailsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"details"];
    [detailsTabViewItem setView:detailsTabViewItemView];
    [detailsTabView addTabViewItem:detailsTabViewItem];
    NSTabViewItem *searchResultsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"searchResults"];
    [searchResultsTabViewItem setView:searchResultsTabViewItemView];
    [detailsTabView addTabViewItem:searchResultsTabViewItem];

// Commented out because already hidden by default and relative expensive in this method    
//    [moleculeSplitSubview setHidden:YES];
//    [detailsSplitSubview setHidden:YES];
    [[detailsTabViewItemScrollView contentView] scrollToPoint:NSMakePoint(0.0f,1000.0f)];
    _lastDetailsSplitSubviewDimension = [detailsSplitSubview dimension];
    
    [[[peaksTable tableColumnWithIdentifier:@"id"] headerCell] setImage:[NSImage imageNamed:@"flagged_header"]];
    
    [chromatogramView showAll:self];
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
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        NSError *error;
        for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
            if (![chromatogram detectBaselineAndReturnError:&error]) {
                [self presentError:error];
            }
        }
        [NSApp endSheet:chromatogramSelectionSheet];
        [chromatogramView setShouldDrawBaseline:YES];
    }
}

- (void)obtainBaselineForSelectedChromatograms:(id)sender {
    NSError *error;
    for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
        if (![chromatogram detectBaselineAndReturnError:&error]) {
            [self presentError:error];
        }
    }
    [chromatogramView setShouldDrawBaseline:YES];
    [NSApp endSheet:chromatogramSelectionSheet];
}


- (IBAction)removeBaseline:(id)sender {
    if ([[[self document] chromatograms] count] > 1) {
        // Run sheet to get selection
        [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Remove Baseline",@"")];
        [chromatogramSelectionSheetButton setAction:@selector(removeBaselineForSelectedChromatograms:)];
        [chromatogramSelectionSheetButton setTarget:self];
        [NSApp beginSheet: chromatogramSelectionSheet
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    } else if ([[[self document] chromatograms] count] == 1) {

        for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
            [chromatogram setBaselinePoints:[NSMutableArray array]];
        }
        [NSApp endSheet:chromatogramSelectionSheet];
        
        // Actually not the responsibility of this method, but I'm being lazy
        [chromatogramView setNeedsDisplay:YES];
     }
}

- (void)removeBaselineForSelectedChromatograms:(id)sender {
    for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
        [chromatogram setBaselinePoints:[NSMutableArray array]];
    }
    [NSApp endSheet:chromatogramSelectionSheet];
    
    // Actually not the responsibility of this method, but I'm being lazy
    [chromatogramView setNeedsDisplay:YES];
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
        [NSApp beginSheet:chromatogramSelectionSheet
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        NSError *error;
        for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
            if (![chromatogram detectPeaksAndReturnError:&error]) {
                [self presentError:error];
            }
        }
        [chromatogramView setShouldDrawPeaks:YES];
    }
}

- (void)identifyPeaksForSelectedChromatograms:(id)sender {
    NSError *error;
    for (PKChromatogram *chromatogram in [chromatogramsController selectedObjects]) {
        if (![chromatogram detectPeaksAndReturnError:&error]) {
            [self presentError:error];
        }
    }
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
           modalForWindow:[self window]
            modalDelegate:self
           didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
              contextInfo:nil];
    } else if ([[[self document] chromatograms] count] == 1) {
        // Ensure the chromatogram is selected
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
		
    NSError *error;
	if (![[self document] performLibrarySearchForChromatograms:[chromatogramsController selectedObjects] error:&error]) {
        [NSApp performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    }
	
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
	
	[pool release]; 
}

- (IBAction)removeChromatograms:(id)sender {
    // Run sheet to get selection
    [chromatogramSelectionSheetButton setTitle:NSLocalizedString(@"Remove",@"")];
    [chromatogramSelectionSheetButton setAction:@selector(removeSelectedChromatograms:)];
    [chromatogramSelectionSheetButton setTarget:self];
    [NSApp beginSheet: chromatogramSelectionSheet
       modalForWindow:[self window]
        modalDelegate:self
       didEndSelector:@selector(didEndSheet:returnCode:contextInfo:)
          contextInfo:nil];
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
    PKChromatogram *chrom = [[self document] chromatogramForModel:[sender stringValue]];
    if (chrom) {
        [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:chrom]];
        [sender setStringValue:@""];
    } else {
        NSBeep();
    }
}

- (void)showChromatogramForModel:(NSString *)modelString {
  	[[self document] addChromatogramForModel:modelString]; 
    PKChromatogram *chrom = [[self document] chromatogramForModel:modelString];
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
        if ([(PKChromatogram *)[[[peakController selectedObjects] objectAtIndex:0] chromatogram] combinePeaks:[peakController selectedObjects]]) {            
            [chromatogramView setNeedsDisplay:YES];
        }
    }
}

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

-(NSString *)peakTypeShown {
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

- (NSPredicate *)predicateForPeakTypeShow {
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
	for (PKPeakRecord *peak in [peakController selectedObjects]) {
		if ([peak identified]) {
			[peak confirm];
		} else if ([[searchResultsController selectedObjects] count] == 1) {
			[peak identifyAndConfirmAsSearchResult:[[searchResultsController selectedObjects] objectAtIndex:0]];
		} else {
            NSBeep();
        }
	}
}

- (IBAction)discard:(id)sender {
	for (PKPeakRecord *peak in [peakController selectedObjects]) {
        [peak discard];
	}
}


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
//    [self didEndSheet:progressSheet returnCode:0 contextInfo:nil];
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
	PKPeakRecord *selectedPeak = [[peakController selectedObjects] objectAtIndex:0];
	[selectedPeak identifyAndConfirmAsSearchResult:[[searchResultsController selectedObjects] objectAtIndex:0]];
}

- (IBAction)showPreset:(id)sender{
	id preset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] objectAtIndex:[sender tag]];
	if ([preset valueForKey:@"massValue"]) {
		[[self document] addChromatogramForModel:[preset valueForKey:@"massValue"]];
        PKChromatogram *chrom = [[self document] chromatogramForModel:[preset valueForKey:@"massValue"]];
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
        PKSpectrumDataSeries *sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:[[self document] spectrumForScan:scan]] autorelease];
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
     [NSThread detachNewThreadSelector:@selector(identifyCompound) toTarget:self withObject:nil];
}
- (void)identifyCompound {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    
    PKPeakRecord *peak;
    peak = [[peakController selectedObjects] objectAtIndex:0];
    NSError *error;// = nil;
    if (![(PKGCMSDocument *)[self document] performForwardSearchLibraryForPeak:peak error:&error]) {
        [self presentError:error];
    }	
    //[error release];
    [self observeValueForKeyPath:@"selection.searchResults" ofObject:peakController change:nil context:PeaksObservationContext];
    //    [resultsTable reloadData];
    [NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];

	[pool release]; 
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
        if ([[peakController arrangedObjects] count] > 0 && [[peakController selectedObjects] count] == 0) {
            [peakController setSelectionIndex:0];
        }
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
        
        PKSpectrumDataSeries *sgds;
        
        for (PKPeakRecord *peak in [peakController selectedObjects]) {
            if (showCombinedSpectrum) {
                sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:[peak combinedSpectrum]] autorelease];
            } else {
                sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:[peak spectrum]] autorelease];
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
            for (PKSearchResult *searchResult in [searchResultsController selectedObjects]) {
                sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:[searchResult valueForKey:@"libraryHit"]] autorelease];
                [sgds setDrawUpsideDown:YES];
                if (showNormalizedSpectra) {
                    [sgds setNormalizeYData:YES];
                }
                [sgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[spectrumArray count]%peakColorsArrayCount]]];
               // [sgds setSeriesTitle:[NSString stringWithFormat:NSLocalizedString(@"Library Hit '%@'", @""), [[searchResult libraryHit] name]]];
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
    BOOL found, added = NO;
    
    // Remove those that we don't need anymore
    NSMutableArray *cgdsToRemove = [NSMutableArray array];
    if ([chromatogramsTableSplitView isCollapsed] || [chromatogramsTableSplitView isHidden]) {
        // When chromatogramsTableSplitView is collapsed, only show those chroms for which peaks are selected
        for (PKChromatogramDataSeries *cgds in chromatogramDataSeries) {
            found = NO;
            for (PKPeakRecord *peak in [[self peakController] selectedObjects]) {
                if ([cgds chromatogram] == [peak chromatogram]) {
                    found = YES;
                    continue;
                }
            }
            if (showTICTrace && [cgds chromatogram] == [[self document] ticChromatogram]) {
                found = YES; // do  not remove
            }        
            if (!found) 
                [cgdsToRemove addObject:cgds];
        }
    } else {
        for (PKChromatogramDataSeries *cgds in chromatogramDataSeries) {
            found = NO;
            for (PKChromatogram *chromatogram in [[self chromatogramsController] selectedObjects]) {
                if ([cgds chromatogram] == chromatogram) {
                    found = YES;
                    continue;
                }
            }
            if (showTICTrace && [cgds chromatogram] == [[self document] ticChromatogram]) {
                found = YES; // do  not remove
            }        
            if (!found) 
                [cgdsToRemove addObject:cgds];
        }
    }

    [chromatogramDataSeries removeObjectsInArray:cgdsToRemove];
    
    for (PKChromatogram *chromatogram in [[self document] chromatograms]) {
        found = NO;
        for (PKChromatogramDataSeries *cgds in chromatogramDataSeries) {
            if ([cgds chromatogram] == chromatogram) {
                [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries indexOfObject:cgds]%peakColorsArrayCount]]];
                 found = YES;
            }
        }
        if (found) continue;
        
        if ([chromatogramsTableSplitView isCollapsed]) {
            if ( (!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
                 (!showTICTrace && showSelectedChromatogramsOnly && ([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
                 (showTICTrace && !showSelectedChromatogramsOnly) ||
                 (showTICTrace && showSelectedChromatogramsOnly && (([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"])) ) {
                
                PKChromatogramDataSeries *cgds = [[[PKChromatogramDataSeries alloc] initWithChromatogram:chromatogram] autorelease];
                [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
                [cgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Retention Index", @""), NSLocalizedString(@"Scan", @""), NSLocalizedString(@"Time", @""), nil]];
                [cgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Total Intensity", @""), nil]];                    
                [chromatogramDataSeries addObject:cgds]; 
                added = YES;
             }                    
        } else {
            if ( (!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
                 (!showTICTrace && showSelectedChromatogramsOnly && ([[[chromatogramsController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
                 (showTICTrace && !showSelectedChromatogramsOnly) ||
                 (showTICTrace && showSelectedChromatogramsOnly && (([[[chromatogramsController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"])) ) {
                
                PKChromatogramDataSeries *cgds = [[[PKChromatogramDataSeries alloc] initWithChromatogram:chromatogram] autorelease];
                [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
                [cgds setAcceptableKeysForXValue:[NSArray arrayWithObjects:NSLocalizedString(@"Retention Index", @""), NSLocalizedString(@"Scan", @""), NSLocalizedString(@"Time", @""), nil]];
                [cgds setAcceptableKeysForYValue:[NSArray arrayWithObjects:NSLocalizedString(@"Total Intensity", @""), nil]];
                [chromatogramDataSeries addObject:cgds];   
                added = YES;
            }                                        
        }
        
        //               if ((!showTICTrace && !showSelectedChromatogramsOnly && ![[chromatogram model] isEqualToString:@"TIC"]) || 
        //                    (!showTICTrace && showSelectedChromatogramsOnly && ([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound)) ||
        //                    (showTICTrace && !showSelectedChromatogramsOnly) ||
        //                    (showTICTrace && showSelectedChromatogramsOnly && (([[[peakController selectedObjects] valueForKey:@"model"] indexOfObjectIdenticalTo:[chromatogram model]] != NSNotFound) || [[chromatogram model] isEqualToString:@"TIC"]))) {
        //                    PKChromatogramDataSeries *cgds = [[[PKChromatogramDataSeries alloc] initWithChromatogram:chromatogram] autorelease];
        //                    [cgds setSeriesColor:[peakColors colorWithKey:[peakColorsArray objectAtIndex:[chromatogramDataSeries count]%peakColorsArrayCount]]];
        //                    [chromatogramDataSeries addObject:cgds];                    
        //                }
    }
    
    [chromatogramDataSeries makeObjectsPerformSelector:@selector(setFilterPredicate:) withObject:[self predicateForPeakTypeShow]];
    
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
    
    if (added)
        [chromatogramView showAll:self];

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
            for (PKPeakRecord *peak in [peakController selectedObjects]) {
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
- (PKGraphView *)chromatogramView {
    return chromatogramView;
}

- (PKGraphView *)spectrumView {
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
        [pboard declareTypes:[NSArray arrayWithObject:PKPeakRecordTableViewDataType] owner:self];
  
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:[[peakController arrangedObjects] objectsAtIndexes:rowIndexes] forKey:PKPeakRecordTableViewDataType];
        [archiver finishEncoding];
        [archiver release];
        
        [pboard setData:data forType:PKPeakRecordTableViewDataType];
        
        return YES;
    } else if (tv == resultsTable) {
        if ([rowIndexes count] != 1) {
            return NO;
        }
        
        // declare our own pasteboard types
        NSArray *typesArray = [NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil];
        [pboard declareTypes:typesArray owner:self];
        
        NSString *uriString = [[[[searchResultsController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] libraryHitURI] absoluteString];
        [pboard setString:uriString forType:@"JKManagedLibraryEntryURIType"];

        
 //       // declare our own pasteboard types
//        NSArray *typesArray = [NSArray arrayWithObjects:JKLibraryEntryTableViewDataType, nil];
//        [pboard declareTypes:typesArray owner:self];
//
//        NSMutableData *data = [NSMutableData data];
//        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
//        [archiver encodeObject:[[[searchResultsController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] libraryHit] forKey:JKLibraryEntryTableViewDataType];
//        [archiver finishEncoding];
//        [archiver release];
//
//        [pboard setData:data forType:JKLibraryEntryTableViewDataType];

        return YES;
	}
	return NO;
}

- (BOOL)tableView:(NSTableView *)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation{
	
	if (tv == chromatogramsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:PKPeakRecordTableViewDataType]]){
            // Add peaks to target chromatogram
            PKChromatogram *chrom = [[chromatogramsController arrangedObjects] objectAtIndex:row];
            
            NSData *data = [[info draggingPasteboard] dataForType:PKPeakRecordTableViewDataType];
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            NSArray *peaks = [unarchiver decodeObjectForKey:PKPeakRecordTableViewDataType];
            [unarchiver finishDecoding];
            [unarchiver release];

            PKPeakRecord *peak = nil;
//            PKPeakRecord *newPeak = nil;
            for (peak in peaks) {
                [[peak chromatogram] removeObjectFromPeaksAtIndex:[[[peak chromatogram] peaks] indexOfObject:peak]];
                [chrom insertObject:peak inPeaksAtIndex:[chrom countOfPeaks]];
            }
            return YES;
        }
    } else if (tv == peaksTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil]]) { //JKLibraryEntryTableViewDataType
            
            // Add the library entry to the peak
            PKPeakRecord *peak = [[peakController arrangedObjects] objectAtIndex:row];
            
            NSString *stringURI = [[info draggingPasteboard] stringForType:@"JKManagedLibraryEntryURIType"];
            NSURL *libraryHitURI = [NSURL URLWithString:stringURI];
            NSManagedObjectContext *moc = [[[NSApp delegate] library] managedObjectContext];
            NSManagedObjectID *mid = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:libraryHitURI];
            if (!mid)
                return NO;
            PKSearchResult *searchResult = [peak addSearchResultForLibraryEntry:(PKManagedLibraryEntry *)[moc objectWithID:mid]];
            [peak identifyAsSearchResult:searchResult];
            return YES;
		}	
	} else if (tv == resultsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil]]) { //JKLibraryEntryTableViewDataType
            
            NSString *stringURI = [[info draggingPasteboard] stringForType:@"JKManagedLibraryEntryURIType"];
            NSURL *libraryHitURI = [NSURL URLWithString:stringURI];
            NSManagedObjectContext *moc = [[[NSApp delegate] library] managedObjectContext];
            NSManagedObjectID *mid = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:libraryHitURI];
            if (!mid)
                return NO;
            PKManagedLibraryEntry *managedLibraryEntry = (PKManagedLibraryEntry *)[moc objectWithID:mid];
            
            // Add the library entry to the peak
            for (PKPeakRecord *peak in [peakController selectedObjects])  {
                [peak addSearchResultForLibraryEntry:managedLibraryEntry];
            }
            return YES;
		}	
    }
    return NO;    
}

- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tv == chromatogramsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:PKPeakRecordTableViewDataType]]){
            [tv setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
        }
    } else if (tv == peaksTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"JKManagedLibraryEntryURIType"]]) {
            if (row < [[peakController arrangedObjects] count]) {
                [tv setDropRow:row dropOperation:NSTableViewDropOn];
                return NSDragOperationMove;
            }
		}	
	} else 	if (tv == resultsTable) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"JKManagedLibraryEntryURIType"]]) {
			[tv setDropRow:-1 dropOperation:NSTableViewDropOn];
			return NSDragOperationMove;
		}
    }
    return NSDragOperationNone;    
}
#pragma mark -

#pragma mark Data source for pulldown menu label 
- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString *)uncompletedString {
//    NSEnumerator *entriesEnumerator;
//    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
//        entriesEnumerator = [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] objectEnumerator];
//    } else {
//        entriesEnumerator = [[[NSApp delegate] autocompleteEntries] objectEnumerator];
//    }

    for (NSString *entry in [[NSApp delegate] autocompleteEntries]) {
    	if ([entry hasPrefix:uncompletedString]) {
            return entry;
        }
    }
    return nil;
}
- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)aString {
    int i, count;
    NSArray *autocompleteArray;
//    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
//        autocompleteArray = [[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]];
//    } else {
        autocompleteArray = [[NSApp delegate] autocompleteEntries];
//    }
    count = [autocompleteArray count];
    for (i = 0; i < count; i++) {
        if ([[autocompleteArray objectAtIndex:i] isEqualToString:aString]) {
            return i;
        }
    }
    return NSNotFound;
    
}
- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(int)index {
//    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
//        return [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] objectAtIndex:index];
//    } else {
        return [[[NSApp delegate] autocompleteEntries] objectAtIndex:index];
//    }
}
- (int)numberOfItemsInComboBoxCell:(NSComboBoxCell *)aComboBoxCell {
//    if ([[[self chromatogramsController] selectedObjects] count] == 1) {
//        return [[[NSApp delegate] autocompleteEntriesForModel:[[[[self chromatogramsController] selectedObjects] objectAtIndex:0] model]] count];
//   } else {
        return [[[NSApp delegate] autocompleteEntries] count];
 //   }
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
#pragma mark -

#pragma mark Properties
@synthesize peakController;
@synthesize moleculeSplitSubview;
@synthesize peaksTable;
@synthesize detailsTabView;
@synthesize spectrumDataSeriesController;
@synthesize chromatogramSelectionSheetButton;
@synthesize moleculeView;
@synthesize spectrumView;
@synthesize mainWindowSplitView;
@synthesize _lastDetailsSplitSubviewDimension;
@synthesize chromatogramsTableSplitView;
@synthesize chromatogramsTable;
@synthesize chromatogramsController;
@synthesize progressText;
@synthesize resultsTable;
@synthesize confirmLibraryHitButton;
@synthesize chromatogramView;
@synthesize searchResultsTabViewItemView;
@synthesize progressBar;
@synthesize hiddenColumnsPeaksTable;
@synthesize chromatogramSelectionSheet;
@synthesize searchResultsController;
@synthesize discardLibraryHitButton;
@synthesize detailsTabViewItemView;
@synthesize chromatogramDataSeriesController;
@synthesize detailsSplitSubview;
@synthesize detailsTabViewItemScrollView;
@synthesize identifyCompoundBox;
@synthesize resultsTableScrollView;
@synthesize progressSheet;
#pragma mark -

@end
