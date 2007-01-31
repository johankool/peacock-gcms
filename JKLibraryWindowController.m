//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKLibraryWindowController.h"

#import "JKLibrary.h"
#import "JKLibraryEntry.h"
#import "JKMoleculeModel.h"
#import "JKMoleculeView.h"
#import "MyGraphView.h"
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
	
	[libraryController addObserver:self forKeyPath:@"selection" options:nil context:nil];
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
		[moleculeView setModel:[[JKMoleculeModel alloc] initWithMoleculeString:[[[[self libraryController] selectedObjects] objectAtIndex:0] valueForKey:@"molString"]]];
        [moleculeView setNeedsDisplay:YES];
      
        [spectrumViewDataseriesController removeObjects:[spectrumViewDataseriesController arrangedObjects]];
        NSMutableArray *spectrumArray = [NSMutableArray array];
        
        NSEnumerator *libraryEntryEnumerator = [[libraryController selectedObjects] objectEnumerator];
        JKLibraryEntry *libraryEntry;
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
 	} else {
		[moleculeView setModel:nil];
        [moleculeView setNeedsDisplay:YES];
	}
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
    NSLog([casNumberField stringValue]);
    NSString *string = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",[casNumberField stringValue],[casNumberField stringValue]]]];
    NSLog(string);
    JKLibraryEntry *entry = [[JKLibraryEntry alloc] initWithJCAMPString:string];
    [entry setMolString:[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[casNumberField stringValue],[casNumberField stringValue]]]]];
    [entry setDocument:[self document]];
    [libraryController addObject:entry];
    [moleculeView setNeedsDisplay:YES];
    [spectrumView setNeedsDisplay:YES];
    [spectrumView showAll:self];
    [NSApp endSheet:addCasNumberSheet];
}

- (IBAction)cancelCasNumber:(id)sender {
    [NSApp endSheet:addCasNumberSheet];
}

#pragma mark UNDO MANAGEMENT

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
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

#pragma mark ACCESSORS

- (NSArrayController *)libraryController {
	return libraryController;
}
@end
