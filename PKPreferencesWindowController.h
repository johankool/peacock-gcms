//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@interface PKPreferencesWindowController : NSWindowController {
	IBOutlet NSView *generalPreferencesView;
	IBOutlet NSView *processingPreferencesView;
	IBOutlet NSView *presetsPreferencesView;
	IBOutlet NSView *ratiosPreferencesView;
	IBOutlet NSView *displayPreferencesView;
	IBOutlet NSView *searchTemplatesPreferencesView;
}

- (IBAction)changeAutoSaveAction:(id)sender;
- (IBAction)showInFinder:(id)sender;
- (IBAction)reloadLibrary:(id)sender;

@property (retain) NSView *presetsPreferencesView;
@property (retain) NSView *displayPreferencesView;
@property (retain) NSView *searchTemplatesPreferencesView;
@property (retain) NSView *generalPreferencesView;
@property (retain) NSView *ratiosPreferencesView;
@property (retain) NSView *processingPreferencesView;
@end
