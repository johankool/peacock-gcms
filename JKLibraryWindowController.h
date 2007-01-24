//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
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
    IBOutlet NSTextField *casNumberField;
    IBOutlet NSWindow *addCasNumberSheet;
}

#pragma mark ACITONS
- (IBAction)addCasNumber:(id)sender;
- (IBAction)showAddCasNumber:(id)sender;
- (IBAction)cancelCasNumber:(id)sender;
//- (void)displaySpectrum:(JKLibraryEntry *)spectrum;

#pragma mark ACCESSORS
- (NSArrayController *)libraryController;

@end
