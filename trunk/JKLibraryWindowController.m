//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKLibraryWindowController.h"

#import "JKLibrary.h"
#import "JKManagedLibraryEntry.h"
#import "JKMoleculeModel.h"
#import "JKMoleculeView.h"
#import "PKGraphView.h"
#import "SpectrumGraphDataSerie.h"


@implementation JKLibraryWindowController

- (id)init {
	self = [super initWithWindowNibName:@"JKLibrary"];
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

    [moleculeView bind:@"moleculeString" toObject: libraryController
		   withKeyPath:@"selection.molString" options:nil];
    
    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", nil]]; 
}

- (void) dealloc {
    [[self libraryController] removeObserver:self forKeyPath:@"selection"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([[[self libraryController] selectedObjects] count] > 0) {
//		[moleculeView setModel:[[JKMoleculeModel alloc] initWithMoleculeString:[[[[self libraryController] selectedObjects] objectAtIndex:0] valueForKey:@"molString"]]];
        [moleculeView setNeedsDisplay:YES];
      
        [spectrumViewDataseriesController removeObjects:[spectrumViewDataseriesController arrangedObjects]];
        NSMutableArray *spectrumArray = [NSMutableArray array];
        
        NSEnumerator *libraryEntryEnumerator = [[libraryController selectedObjects] objectEnumerator];
        JKManagedLibraryEntry *libraryEntry;
        SpectrumGraphDataSerie *sgds;
        
        while ((libraryEntry = [libraryEntryEnumerator nextObject]) != nil) {
            sgds = [[[SpectrumGraphDataSerie alloc] initWithSpectrum:libraryEntry] autorelease];
            if (showNormalizedSpectra) {
                [sgds setNormalizeYData:YES];
            }
            [spectrumArray addObject:sgds];
        }
        
        [spectrumViewDataseriesController setContent:spectrumArray];
        
         // spectrumView resizes to show all data
        [spectrumView showAll:self];
        [spectrumView setNeedsDisplay:YES];
 	} else if (object == moleculeView) {
      //  [[[[self libraryController] selectedObjects] objectAtIndex:0] setMolString:[[moleculeView model] molString]];
	} else {
//		[moleculeView setModel:nil];
        [moleculeView setNeedsDisplay:YES];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [spectrumViewDataseriesController setContent:nil];
}

#pragma mark IBACTIONS
- (IBAction)showAddCasNumber:(id)sender {
    [NSApp beginSheet: addCasNumberSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (IBAction)addCasNumber:(id)sender {
    JKLogDebug([casNumberField stringValue]);
    NSString *string = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",[casNumberField stringValue],[casNumberField stringValue]]]];
    JKLogDebug(string);
    if (string) {
        JKManagedLibraryEntry *libEntry = [NSEntityDescription insertNewObjectForEntityForName:@"JKManagedLibraryEntry" inManagedObjectContext:[[self document] managedObjectContext]];
        [libEntry setJCAMPString:string];
        [libEntry setMolString:[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[casNumberField stringValue],[casNumberField stringValue]]]]];        
    } else {
        NSBeep();
    }
    [NSApp endSheet:addCasNumberSheet];
}

- (IBAction)cancelCasNumber:(id)sender {
    [NSApp endSheet:addCasNumberSheet];
}

#pragma mark UNDO MANAGEMENT

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
}
#pragma mark -

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
    NSArray *typesArray = [NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", nil];
    [pboard declareTypes:typesArray owner:self];
    	
    NSMutableData *data;
    NSKeyedArchiver *archiver;    
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[[libraryController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] forKey:@"JKLibraryEntryTableViewDataType"];
    [archiver finishEncoding];
    [pboard setData:data forType:@"JKLibraryEntryTableViewDataType"];
    [archiver release];
	
    return YES;
}
#pragma mark -

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

#pragma mark ACCESSORS

- (NSArrayController *)libraryController {
	return libraryController;
}
@synthesize showNormalizedSpectra;
@synthesize casNumberField;
@synthesize spectrumViewDataseriesController;
@synthesize addCasNumberSheet;
@synthesize libraryController;
@synthesize tableView;
@synthesize moleculeView;
@synthesize spectrumView;
@end
