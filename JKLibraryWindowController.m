//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKLibraryWindowController.h"

#import "JKLibrary.h"
#import "JKLibraryEntry.h"
#import "JKMoleculeModel.h"
#import "JKMoleculeView.h"
#import "MyGraphView.h"
#import "SpectrumGraphDataSerie.h"


@implementation JKLibraryWindowController

- (id)init  
{
	self = [super initWithWindowNibName:@"JKLibrary"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
    }
    return self;
}

- (void)windowDidLoad  
{
	[spectrumView setShouldDrawLabels:NO];
	[spectrumView setShouldDrawLegend:NO];
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	[spectrumView setPlottingArea:NSMakeRect(30,20,[spectrumView bounds].size.width-40,[spectrumView bounds].size.height-30)];
	[spectrumView setBackColor:[NSColor clearColor]];
	
	[spectrumView bind:@"dataSeries" toObject:spectrumViewDataseriesController withKeyPath:@"arrangedObjects" options:nil];
	
	[[self libraryController] setContent:[[self document] libraryArray]];
	[[self libraryController] addObserver:self forKeyPath:@"selection" options:nil context:nil];
}


- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([[[self libraryController] selectedObjects] count] > 0) {
		[moleculeView setModel:[[JKMoleculeModel alloc] initWithMoleculeString:[[[[self libraryController] selectedObjects] objectAtIndex:0] valueForKey:@"molString"]]];
		[spectrumView showAll:self];
	} else {
		[moleculeView setModel:nil];
	}
}


#pragma mark ACCESSORS

- (NSArrayController *)libraryController  
{
	return libraryController;
}
@end
