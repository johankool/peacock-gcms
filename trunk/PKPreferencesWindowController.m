//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKPreferencesWindowController.h"

#import "PKAppDelegate.h"

@implementation PKPreferencesWindowController

#pragma mark Initialization & deallocation
- (id)init {
    self = [super initWithWindowNibName:@"PKPreferences"];
    return self;
}

- (void)windowDidLoad {
    [[self window] setShowsResizeIndicator:NO];
    [[self window] setDelegate:self];
    
	// Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"nl.johankool.Peacock.preferences.toolbar"] autorelease];
    
    // Set up toolbar properties:Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode:NSToolbarSizeModeRegular];
    
    // We are the delegate
    [toolbar setDelegate:self];
	
    // Attach the toolbar to the document window 
    [[self window] setToolbar:toolbar];
	
	// Set an initial state
	[toolbar setSelectedItemIdentifier:@"general"];
	[[self window] setContentView:generalPreferencesView];
	[[self window] setShowsToolbarButton:NO];
    [toolbar setVisible:YES];
}

#pragma mark Actions
- (IBAction)changeAutoSaveAction:(id)sender {
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSave"] boolValue] == YES) {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSaveDelay"] intValue]*60];
    } else {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:0];
    }    
}

- (IBAction)changeLogLevelAction:(id)sender {
    JKSetVerbosityLevel([sender selectedTag]);
}

- (IBAction)showInFinder:(id)sender {
    [(PKAppDelegate *)[NSApp delegate] showInFinder];
}

- (IBAction)reloadLibrary:(id)sender {
    [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:@""]; // force empty
    [(PKAppDelegate *)[NSApp delegate] loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"libraryConfiguration"]];
}
#pragma mark -

#pragma mark Toolbar
- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    // Required delegate method: Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdent] autorelease];
    NSString *itemLabel = NSLocalizedString(itemIdent, @"String for toolbar label");
    [toolbarItem setLabel:itemLabel];
    [toolbarItem setPaletteLabel:itemLabel];
       
    // Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
    [toolbarItem setToolTip:itemLabel];
    [toolbarItem setImage:[NSImage imageNamed:itemIdent]];
    
    // Tell the item what message to send when it is clicked 
    [toolbarItem setTarget:self];
    [toolbarItem setAction:@selector(changePanes:)];
    
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
        [[self window] setShowsResizeIndicator:NO];
	} else if ([[sender itemIdentifier] isEqualToString:@"processing"]) {
		deltaHeight = [processingPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [processingPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:processingPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
        [[self window] setShowsResizeIndicator:NO];
	} else if ([[sender itemIdentifier] isEqualToString:@"presets"]) {
		deltaHeight = [presetsPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [presetsPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:presetsPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
        [[self window] setShowsResizeIndicator:YES];
        [[self window] setMinSize:NSMakeSize(445.0f,250.0f)];
	} else if ([[sender itemIdentifier] isEqualToString:@"ratios"]) {
		deltaHeight = [ratiosPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [ratiosPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:ratiosPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
        [[self window] setShowsResizeIndicator:YES];
        [[self window] setMinSize:NSMakeSize(445.0f,250.0f)];
	} else if ([[sender itemIdentifier] isEqualToString:@"display"]) {
		deltaHeight = [displayPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [displayPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:displayPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
	} else if ([[sender itemIdentifier] isEqualToString:@"libraries"]) {
		deltaHeight = [searchTemplatesPreferencesView frame].size.height - [[[self window] contentView] frame].size.height;
		deltaWidth = [searchTemplatesPreferencesView frame].size.width - [[[self window] contentView] frame].size.width;
		[[self window] setContentView:searchTemplatesPreferencesView];
		[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width+deltaWidth,windowFrame.size.height+deltaHeight) display:YES animate:YES];
        [[self window] setShowsResizeIndicator:YES];
        [[self window] setMinSize:NSMakeSize(445.0f,400.0f)];
	}
    
    // prevent window from going off screen partially
    if ([[self window] frame].origin.y < 0.0f) {
        [[self window] center];
    }    
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
	return [NSArray arrayWithObjects:@"general", @"processing", @"presets", @"ratios", @"libraries", nil];
}

- (NSArray*) toolbarSelectableItemIdentifiers:(NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}
#pragma mark -

# pragma mark Window Management
- (BOOL)windowShouldZoom:(NSWindow *)sender toFrame:(NSRect)newFrame {
    return NO;
}
- (void)awakeFromNib {
    [[self window] center];
}
#pragma mark -

#pragma mark Properties
@synthesize searchTemplatesPreferencesView;
@synthesize generalPreferencesView;
@synthesize presetsPreferencesView;
@synthesize displayPreferencesView;
@synthesize ratiosPreferencesView;
@synthesize processingPreferencesView;

@end
