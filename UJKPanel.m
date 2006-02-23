//
//  UJKPanel.m
//  UJKPanel
//
//  Created by Uli Kusterer on Mon Jun 30 2003.
//  Copyright (c) 2003 M. Uli Kusterer. All rights reserved.
//

#import "UJKPanel.h"


@implementation UJKPanel


-(void)	awakeFromNib
{
    NSString* wndTitle = [[tabView window] title];
    [baseWindowName release];
    if( [wndTitle length] > 0 )
        baseWindowName = [[NSString stringWithFormat: @"%@: ", wndTitle] retain];
    [self setupToolbar];
}


-(id) init
{
    if( self = [super init] )
    {
        itemsList = [[NSMutableDictionary alloc] init];
        baseWindowName = [[NSString alloc] init];
    }
    
    return self;
}

-(void)	dealloc
{
    [itemsList release];
    [baseWindowName release];
	[super dealloc];
}


-(void) setupToolbar
{
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"nl.vu.geo.kool.Peacock.panel.toolbar"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode: NSToolbarSizeModeSmall];
    
    // Set up item list based on Tab View:
    int itemCount = [tabView numberOfTabViewItems], x;
    
    for( x = 0; x < itemCount; x++ )
    {
        NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:x];
        NSString*			theIdentifier = [theItem identifier];
        NSString*			theLabel = [theItem label];
        
        [itemsList setObject:theLabel forKey:theIdentifier];
    }
    
    // Set up window title:
    [[tabView window] setTitle: [baseWindowName stringByAppendingString: [[tabView tabViewItemAtIndex:0] label]]];
    
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[tabView window] setToolbar: toolbar];
    [toolbar setSelectedItemIdentifier:[[tabView tabViewItemAtIndex:0] identifier]];
}

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel;
    
    if( (itemLabel = [itemsList objectForKey:itemIdent]) != nil )
    {
        // Set the text label to be displayed in the toolbar and customization palette 
        [toolbarItem setLabel: itemLabel];
        [toolbarItem setPaletteLabel: itemLabel];
        [toolbarItem setTag:[tabView indexOfTabViewItemWithIdentifier:itemIdent]];
        
        // Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
        [toolbarItem setToolTip: itemLabel];
        [toolbarItem setImage: [NSImage imageNamed:itemIdent]];
        
        // Tell the item what message to send when it is clicked 
        [toolbarItem setTarget: self];
        [toolbarItem setAction: @selector(changePanes:)];
    }
    else
    {
        // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
        // Returning nil will inform the toolbar this kind of item is not supported 
        toolbarItem = nil;
    }
    
    return toolbarItem;
}


-(IBAction)	changePanes: (id)sender
{
    [tabView selectTabViewItemAtIndex: [sender tag]];
    [[tabView window] setTitle: [baseWindowName stringByAppendingString: [sender label]]];
}


-(NSArray*) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar
{
    int					itemCount = [tabView numberOfTabViewItems],
    x;
    NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:0];
    //NSMutableArray*	defaultItems = [NSMutableArray arrayWithObjects: [theItem identifier], NSToolbarSeparatorItemIdentifier, nil];
    NSMutableArray*	defaultItems = [NSMutableArray array];
    
    for( x = 0; x < itemCount; x++ )
    {
        theItem = [tabView tabViewItemAtIndex:x];
        
        [defaultItems addObject: [theItem identifier]];
    }
    
    return defaultItems;
}

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar
{
    int					itemCount = [tabView numberOfTabViewItems],
    x;
    NSTabViewItem*		theItem = [tabView tabViewItemAtIndex:0];
    //NSMutableArray*	defaultItems = [NSMutableArray arrayWithObjects: [theItem identifier], NSToolbarSeparatorItemIdentifier, nil];
    NSMutableArray*	defaultItems = [NSMutableArray array];
    
    for( x = 0; x < itemCount; x++ )
    {
        theItem = [tabView tabViewItemAtIndex:x];
        
        [defaultItems addObject: [theItem identifier]];
    }
    
    return defaultItems;
}

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar
{
    NSMutableArray*		allowedItems = [[itemsList allKeys] mutableCopy];
    
    [allowedItems addObjectsFromArray: [NSArray arrayWithObjects: NSToolbarSeparatorItemIdentifier,
        NSToolbarSpaceItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarCustomizeToolbarItemIdentifier, nil] ];
    
    return allowedItems;
}


@end
