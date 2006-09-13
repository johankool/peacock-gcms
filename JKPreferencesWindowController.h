//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class BDAlias;
@class JKPathPopUpButton;

@interface JKPreferencesWindowController : NSWindowController {
	IBOutlet NSView *generalPreferencesView;
	IBOutlet NSView *processingPreferencesView;
	IBOutlet NSView *presetsPreferencesView;
	IBOutlet JKPathPopUpButton *libraryPopUpButton;

	NSMutableDictionary *preferencesList;
	BDAlias *libraryAlias;
}
- (IBAction)changeAutoSaveAction:(id)sender;
@end
