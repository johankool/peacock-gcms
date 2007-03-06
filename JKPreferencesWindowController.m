//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKPreferencesWindowController.h"

#import "BDAlias.h"
#import "JKPathPopUpButton.h"

@implementation JKPreferencesWindowController

#pragma mark INITIALIZATION

- (id)init {
    self = [super initWithWindowNibName:@"JKPreferences"];
    return self;
}

- (void)windowDidLoad{
	preferencesList = [[NSMutableDictionary alloc] init];
	[preferencesList setValue:@"General" forKey:@"general"];
	[preferencesList setValue:@"Processing" forKey:@"processing"];
	[preferencesList setValue:@"Presets" forKey:@"presets"];
//	[preferencesList setValue:@"Display" forKey:@"display"];

	// Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"nl.johankool.Peacock.preferences.toolbar"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode: NSToolbarSizeModeRegular];
    
    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	
	// Set an initial state
	[toolbar setSelectedItemIdentifier:@"general"];
	[[self window] setContentView:generalPreferencesView];
	[[self window] setShowsToolbarButton:NO];
    [toolbar setVisible:YES];
    
	// Bind libraryPopUpButton manually
	[libraryPopUpButton bind:@"fileAlias" toObject:self withKeyPath:@"libraryAlias" options:nil];

}
- (IBAction)changeAutoSaveAction:(id)sender {
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSave"] boolValue] == YES) {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSaveDelay"] intValue]*60];
    } else {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:0];
    }    
}

#pragma mark TOOLBAR

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel = NSLocalizedString(itemIdent, @"String for toolbar label");//[itemsList objectForKey:itemIdent];
																						  //    if( (itemLabel = [itemsList objectForKey:itemIdent]) != nil )
																						  //   {
																						  // Set the text label to be displayed in the toolbar and customization palette 
        [toolbarItem setLabel: itemLabel];
        [toolbarItem setPaletteLabel: itemLabel];
		//       [toolbarItem setTag:[tabView indexOfTabViewItemWithIdentifier:itemIdent]];
        
        // Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
        [toolbarItem setToolTip: itemLabel];
        [toolbarItem setImage: [NSImage imageNamed:itemIdent]];
        
        // Tell the item what message to send when it is clicked 
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(changePanes:)];
		//    }
		//    else
		//   {
		//		JKLogDebug([toolbarItem description]);
		//        // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		//        // Returning nil will inform the toolbar this kind of item is not supported 
		//        toolbarItem = nil;
		//    }
		
		return toolbarItem;
}


- (IBAction)changePanes:(id)sender {
	NSRect windowFrame = [[self window] frame];
	float deltaHeight, deltaWidth;
	if ([[sender itemIdentifier] isEqualToString:@"general"]) {
		deltaHeight = [generalPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [generalPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:generalPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
	} else if ([[sender itemIdentifier] isEqualToString:@"processing"]) {
		deltaHeight = [processingPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [processingPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:processingPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
	} else if ([[sender itemIdentifier] isEqualToString:@"presets"]) {
		deltaHeight = [presetsPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [presetsPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:presetsPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
	} else if ([[sender itemIdentifier] isEqualToString:@"display"]) {
		deltaHeight = [displayPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [displayPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:displayPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
	}
    // prevent window from going off screen partially
    if ([[self window] frame].origin.y < 0.0f) {
        [[self window] center];
    }    
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:@"general", @"processing", @"presets", nil];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}


# pragma mark WINDOW MANAGEMENT

- (void)awakeFromNib {
    [[self window] center];
}

- (BDAlias *)libraryAlias {
	return [BDAlias aliasWithPath:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"libraryAlias"]];
}

- (void)setLibraryAlias:(BDAlias *)inValue {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[inValue fullPath] forKey:@"libraryAlias"];
}
@end
