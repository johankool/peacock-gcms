//
//  JKLibraryPanelController.h
//  Peacock
//
//  Created by Johan Kool on 16-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKGraphView;
@class PKLibrary;

@interface PKLibraryPanelController : NSWindowController {
	IBOutlet NSArrayController *libraryController;
	IBOutlet NSArrayController *spectrumViewDataseriesController;
	IBOutlet PKGraphView *spectrumView;
	IBOutlet NSTableView *tableView;
    BOOL showNormalizedSpectra;
}

#pragma mark INITIALIZATION
+ (PKLibraryPanelController *) sharedController;
- (IBAction)showInspector:(id)sender;
- (PKLibrary *)library;
- (IBAction)reloadLibrary:(id)sender;

@property (retain) PKGraphView *spectrumView;
@property (retain) NSTableView *tableView;
@property BOOL showNormalizedSpectra;
@property (retain,getter=libraryController) NSArrayController *libraryController;
@property (retain) NSArrayController *spectrumViewDataseriesController;

@end
