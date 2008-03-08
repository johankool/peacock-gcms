//
//  CSLWindowController.m
//  CSL Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "CSLWindowController.h"

NSString *CiteEntryType = @"CiteEntryType";


@implementation CSLWindowController

-(id)init {
    if (self = [super initWithWindowNibName:@"CSLDocument"]) {
    }
    return self;
}

-(void)windowDidLoad {
	[self setupToolbar];

	[bibliographyOutlineView registerForDraggedTypes:[NSArray arrayWithObjects:CiteEntryType,nil]];
}


-(id)info {
	return [[self document] info];
}


#pragma mark NSTOOLBAR MANAGEMENT
-(IBAction)showInfo:(id)sender {
	[[[self window] contentView] retain];
	[[self window] setContentView:infoView];
	[[[self window] toolbar] setSelectedItemIdentifier:@"Show Info Item Identifier"];
}

-(IBAction)showContent:(id)sender {
	[[[self window] contentView] retain];
	[[self window] setContentView:contentView];
	[[[self window] toolbar] setSelectedItemIdentifier:@"Show Content Item Identifier"];
}
-(IBAction)showCitation:(id)sender {
	[[[self window] contentView] retain];
	[[self window] setContentView:citationView];
	[[[self window] toolbar] setSelectedItemIdentifier:@"Show Citation Item Identifier"];
}

-(IBAction)showBibliography:(id)sender {
	[[[self window] contentView] retain];
	[[self window] setContentView:bibliographyView];
	[[[self window] toolbar] setSelectedItemIdentifier:@"Show Bibliography Item Identifier"];
}

-(void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"CSLToolbar"] autorelease];
    
    // Set up toolbar properties: disallow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: NO];
	[toolbar setVisible:YES];
	
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	[toolbar setSelectedItemIdentifier:@"Show Info Item Identifier"];
}

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqual: @"Show Info Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Info"];
		[toolbarItem setPaletteLabel: @"Show Info"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Info"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showInfo:)];
	}   else if ([itemIdent isEqual: @"Show Content Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Content"];
		[toolbarItem setPaletteLabel: @"Show Content"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Content"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showContent:)];
	}   else     if ([itemIdent isEqual: @"Show Citation Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Citation"];
		[toolbarItem setPaletteLabel: @"Show Citation"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Citation"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showCitation:)];
	}   else     if ([itemIdent isEqual: @"Show Bibliography Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel: @"Bibliography"];
		[toolbarItem setPaletteLabel: @"Show Bibliography"];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		//		[toolbarItem setToolTip: @"Save Your Document"];
		[toolbarItem setImage: [NSImage imageNamed: @"Bibliography"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showBibliography:)];
	}   else  {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
    return toolbarItem;
}

-(NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

-(NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

-(NSArray *) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:	@"Show Info Item Identifier",@"Show Content Item Identifier",@"Show Citation Item Identifier",@"Show Bibliography Item Identifier", nil];
}

// The below still needs to get implemented

#pragma mark -
#pragma mark NSOutlineView Hacks for Drag and Drop

- (BOOL) outlineView: (NSOutlineView *)ov
	isItemExpandable: (id)item { return NO; }

- (int)  outlineView: (NSOutlineView *)ov
         numberOfChildrenOfItem:(id)item { return 0; }

- (id)   outlineView: (NSOutlineView *)ov
			   child:(int)index
			  ofItem:(id)item { return nil; }

- (id)   outlineView: (NSOutlineView *)ov
         objectValueForTableColumn:(NSTableColumn*)col
			  byItem:(id)item { return nil; }


- (BOOL) outlineView: (NSOutlineView *)ov
          acceptDrop: (id )info
                item: (id)item
          childIndex: (int)index
{
//    item = [item observedObject];
	NSLog([info description]);

	NSLog([[item observedObject] label]);
	
    // do whatever you would normally do with the item
	NSLog(@"acceptDrop?");
	return YES;
}
- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
	return NSDragOperationAll;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
	[pboard declareTypes:[NSArray arrayWithObjects:CiteEntryType,nil] owner:self];

//	[pboard setPropertyList:items forType:"CiteEntryType"];
	return YES;
}
@end
