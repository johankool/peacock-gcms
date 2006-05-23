//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class MyGraphView;
@class JKLibraryEntry;
@class JKMoleculeView;

@interface JKLibraryWindowController : NSWindowController {
	IBOutlet NSArrayController *libraryController;
	IBOutlet NSArrayController *spectrumViewDataseriesController;
	IBOutlet MyGraphView *spectrumView;
	IBOutlet NSTableView *tableView;
	IBOutlet JKMoleculeView *moleculeView;
}

//#pragma mark ACITONS
//- (void)displaySpectrum:(JKLibraryEntry *)spectrum;

#pragma mark ACCESSORS
- (NSArrayController *)libraryController;

@end
