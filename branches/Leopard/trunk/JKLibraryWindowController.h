//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class PKGraphView;
@class JKLibraryEntry;
@class JKMoleculeView;

@interface JKLibraryWindowController : NSWindowController {
	IBOutlet NSArrayController *libraryController;
	IBOutlet NSArrayController *spectrumViewDataseriesController;
	IBOutlet PKGraphView *spectrumView;
	IBOutlet NSTableView *tableView;
	IBOutlet JKMoleculeView *moleculeView;
    IBOutlet NSTextField *casNumberField;
    IBOutlet NSWindow *addCasNumberSheet;
    
    BOOL showNormalizedSpectra;
}

#pragma mark ACITONS
- (IBAction)addCasNumber:(id)sender;
- (IBAction)showAddCasNumber:(id)sender;
- (IBAction)cancelCasNumber:(id)sender;
//- (void)displaySpectrum:(JKLibraryEntry *)spectrum;

#pragma mark ACCESSORS
- (NSArrayController *)libraryController;

@property (retain) NSTableView *tableView;
@property (retain) JKMoleculeView *moleculeView;
@property (retain) NSWindow *addCasNumberSheet;
@property (retain) PKGraphView *spectrumView;
@property (retain) NSArrayController *spectrumViewDataseriesController;
@property (retain) NSTextField *casNumberField;
@property (retain,getter=libraryController) NSArrayController *libraryController;
@property BOOL showNormalizedSpectra;
@end
