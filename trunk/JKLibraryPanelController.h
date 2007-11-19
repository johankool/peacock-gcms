//
//  JKLibraryPanelController.h
//  Peacock
//
//  Created by Johan Kool on 16-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKGraphView;
@class JKLibrary;

@interface JKLibraryPanelController : NSWindowController {
	IBOutlet NSArrayController *libraryController;
	IBOutlet NSArrayController *spectrumViewDataseriesController;
	IBOutlet PKGraphView *spectrumView;
	IBOutlet NSTableView *tableView;
    BOOL showNormalizedSpectra;
}

#pragma mark INITIALIZATION
+ (JKLibraryPanelController *) sharedController;
- (IBAction)showInspector:(id)sender;
- (JKLibrary *)library;

@property (retain) PKGraphView *spectrumView;
@property (retain) NSTableView *tableView;
@property BOOL showNormalizedSpectra;
@property (retain,getter=libraryController) NSArrayController *libraryController;
@property (retain) NSArrayController *spectrumViewDataseriesController;

@end
