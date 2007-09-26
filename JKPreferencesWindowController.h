//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class BDAlias;
@class JKPathPopUpButton;

@interface JKPreferencesWindowController : NSWindowController {
	IBOutlet NSView *generalPreferencesView;
	IBOutlet NSView *processingPreferencesView;
	IBOutlet NSView *presetsPreferencesView;
	IBOutlet NSView *displayPreferencesView;
	IBOutlet NSView *searchTemplatesPreferencesView;
	IBOutlet JKPathPopUpButton *libraryPopUpButton;

	NSMutableDictionary *preferencesList;
	BDAlias *libraryAlias;
}
- (IBAction)changeAutoSaveAction:(id)sender;
@property (retain) NSView *presetsPreferencesView;
@property (retain) NSView *generalPreferencesView;
@property (retain) JKPathPopUpButton *libraryPopUpButton;
@property (retain) NSMutableDictionary *preferencesList;
@property (retain) NSView *processingPreferencesView;
@property (retain) NSView *searchTemplatesPreferencesView;
@property (retain) NSView *displayPreferencesView;
@end
