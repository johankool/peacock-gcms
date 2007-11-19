//
//  JKLibraryPanelController.m
//  Peacock
//
//  Created by Johan Kool on 16-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKLibraryPanelController.h"

#import "JKLibrary.h"
#import "JKManagedLibraryEntry.h"
#import "PKGraphView.h"
#import "PKSpectrumDataSeries.h"

static JKLibraryPanelController *theSharedController;

@implementation JKLibraryPanelController

+ (JKLibraryPanelController *) sharedController {
    if (theSharedController == nil) {
		
        theSharedController = [[JKLibraryPanelController alloc] initWithWindowNibName: @"JKLibraryPanel"];
    }
	
    return (theSharedController);
	
} 

- (id)init {
	self = [super initWithWindowNibName:@"JKLibraryPanel"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
    }
    return self;
}

- (void)windowDidLoad {
    [[self window] setDelegate:self];
	[spectrumView setShouldDrawLegend:NO];
	[spectrumView setShouldDrawFrame:YES];
	[spectrumView setShouldDrawFrameBottom:NO];
    [spectrumView setShouldDrawLabels:NO];
    [spectrumView setShouldDrawLabelsOnFrame:YES];
    [spectrumView setShouldDrawAxes:YES];
    [spectrumView setShouldDrawAxesVertical:NO];
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	[spectrumView setPlottingArea:NSMakeRect(30,20,[spectrumView bounds].size.width-40,[spectrumView bounds].size.height-30)];
	[spectrumView setBackColor:[NSColor clearColor]];
	
	[spectrumView bind:@"dataSeries" toObject:spectrumViewDataseriesController withKeyPath:@"arrangedObjects" options:nil];
	
	[libraryController addObserver:self forKeyPath:@"selection" options:0 context:nil];
    
//    [moleculeView bind:@"moleculeString" toObject: libraryController
//		   withKeyPath:@"selection.molString" options:nil];
    [tableView setDelegate:self];

    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", nil]]; 
}

- (void) dealloc {
    [[self libraryController] removeObserver:self forKeyPath:@"selection"];
    [super dealloc];
}


- (IBAction)showInspector:(id)sender {
	if (![[self window] isVisible]) {
        [[self window] orderFront:self];
    } else {
        [[self window] orderOut:self];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([[[self libraryController] selectedObjects] count] > 0) {
        //		[moleculeView setModel:[[JKMoleculeModel alloc] initWithMoleculeString:[[[[self libraryController] selectedObjects] objectAtIndex:0] valueForKey:@"molString"]]];
//        [moleculeView setNeedsDisplay:YES];
        
        [spectrumViewDataseriesController removeObjects:[spectrumViewDataseriesController arrangedObjects]];
        NSMutableArray *spectrumArray = [NSMutableArray array];
        
        PKSpectrumDataSeries *sgds;
        
        for (JKManagedLibraryEntry *libraryEntry in [libraryController selectedObjects]) {
            sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:libraryEntry] autorelease];
            if (showNormalizedSpectra) {
                [sgds setNormalizeYData:YES];
            }
            [spectrumArray addObject:sgds];
        }
        
        [spectrumViewDataseriesController setContent:spectrumArray];
        
        // spectrumView resizes to show all data
        [spectrumView showAll:self];
        [spectrumView setNeedsDisplay:YES];
// 	} else if (object == moleculeView) {
        //  [[[[self libraryController] selectedObjects] objectAtIndex:0] setMolString:[[moleculeView model] molString]];
//	} else {
//        //		[moleculeView setModel:nil];
//        [moleculeView setNeedsDisplay:YES];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [spectrumViewDataseriesController setContent:nil];
}
#pragma mark Drag-'n-drop
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    if ([rowIndexes count] != 1) {
        return NO;
    }
    if (aTableView != tableView) {
        return NO;
    }
    
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil];
    [pboard declareTypes:typesArray owner:self];
    
    NSString *uriString = [[[[[libraryController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] objectID] URIRepresentation] absoluteString];
    [pboard setString:uriString forType:@"JKManagedLibraryEntryURIType"];
	
    return YES;
}
#pragma mark -

- (JKLibrary *)library {
    return [[NSApp delegate] library];
}

@synthesize spectrumViewDataseriesController;
@synthesize spectrumView;
@synthesize libraryController;
@synthesize tableView;
@synthesize showNormalizedSpectra;
@end
