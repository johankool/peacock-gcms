//
//  PKWindowController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKWindowController.h"

#import "JKGCMSDocument.h"
#import "JKAppDelegate.h"
#import "PKDocumentController.h"

@implementation PKWindowController

- (void)awakeFromNib
{
    [[documentTabView tabViewItemAtIndex:0] setView:[[[(JKAppDelegate *)[NSApp delegate] summaryController] window] contentView]];
    [[(JKAppDelegate *)[NSApp delegate] summaryController] setWindow:[self window]];
    [[documentTabView tabViewItemAtIndex:1] setView:[[[(JKAppDelegate *)[NSApp delegate] ratiosController] window] contentView]];
    [[(JKAppDelegate *)[NSApp delegate] ratiosController] setWindow:[self window]];
    [self setupToolbar];
    [[self window] setDelegate:self];
    NSButton *closeButton = [[self window] standardWindowButton:NSWindowCloseButton];
    [closeButton setTarget:[PKDocumentController sharedDocumentController]];
    [closeButton setAction:@selector(performClose:)];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isKindOfClass:[JKGCMSDocument class]]) {
        [[tabViewItem identifier] addWindowController:self];
        [[self window] setTitle:[[[tabViewItem identifier] mainWindowController] windowTitleForDocumentDisplayName:[[tabViewItem identifier] displayName]]];
//        [[self window] setTitleWithRepresentedFilename:[[tabViewItem identifier] fileName]];
//        [[self window] setNextResponder:[[tabViewItem identifier] mainWindowController]];
        [[[tabViewItem identifier] mainWindowController] setWindow:[self window]];
     } else if ([[tabViewItem identifier] isEqualToString:@"summary"]) {
        [[self document] removeWindowController:self];
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Summary"];
        [[self document] removeWindowController:self];
//        [[self window] setDelegate:self];
//        [[self window] setNextResponder:(NSResponder *)[(JKAppDelegate *)[NSApp delegate] summaryController]];
    } else if ([[tabViewItem identifier] isEqualToString:@"ratios"]) {
        [[self document] removeWindowController:self];
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Ratios"];
        [[self document] removeWindowController:self];
//        [[self window] setDelegate:self];
//       [[self window] setNextResponder:(NSResponder *)[(JKAppDelegate *)[NSApp delegate] ratiosController]];
	} else if ([[tabViewItem identifier] isEqualToString:@"multiple"]) {
        [[self document] removeWindowController:self];
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Multiple Items Selected"];
        [[self document] removeWindowController:self];
//        [[self window] setNextResponder:nil];
//        [[self window] setDelegate:self];
	}
}

- (IBAction)showSummary:(id)sender {
    [documentTableView selectRow:0 byExtendingSelection:NO];
}

- (IBAction)showRatios:(id)sender {
    [documentTableView selectRow:1 byExtendingSelection:NO];
}

//-(IBAction)printDocument:(id)sender {
//    if ([[[documentTabView selectedTabViewItem] identifier] isKindOfClass:[JKGCMSDocument class]]) {
//        [[[documentTabView selectedTabViewItem] identifier] printDocument:sender];
//    } else if ([[[documentTabView selectedTabViewItem] identifier] isEqualToString:@"multiple"]) {
//        // Run print dialog for first documetn only, then for all other documents with the same settings
//        JKLogDebug(@"multiple print");
//        JKGCMSDocument *firstDoc = [[[PKDocumentController sharedDocumentController] managedDocuments] objectAtIndex:0];
//        [firstDoc printDocumentWithSettings:nil showPrintPanel:YES delegate:self didPrintSelector:@selector(document:didPrint:contextInfo:) contextInfo:[NSNumber numberWithInt:0]];
//    } else {
//        NSBeep();
//    }
//}
//
//- (void)document:(NSDocument *)document didPrint:(BOOL)didPrintSuccessfully  contextInfo: (void *)contextInfo
//{
//    if (didPrintSuccessfully) {
//     	JKLogDebug(@"printed %@ number %d", [document displayName], [contextInfo intValue]);   
//        if ([contextInfo intValue]+1 < [[[PKDocumentController sharedDocumentController] managedDocuments] count]) {
//            JKGCMSDocument *nextDoc = [[[PKDocumentController sharedDocumentController] managedDocuments] objectAtIndex:[contextInfo intValue]+1];
//            [nextDoc printDocumentWithSettings:nil showPrintPanel:NO delegate:self didPrintSelector:@selector(document:didPrint:contextInfo:) contextInfo:[NSNumber numberWithInt:[contextInfo intValue]+1]];
//        }
//    }
//}
#pragma mark NSToolbar Management

- (void)setupToolbar {
    // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"PeacockAllInOneWindowToolbarIdentifier"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setVisible:YES];
    [toolbar setAllowsUserCustomization: YES];
    [toolbar setAutosavesConfiguration: YES];
	
    // We are the delegate
    [toolbar setDelegate: self];
    
    // Attach the toolbar to the document window 
    [[self window] setToolbar:toolbar];
}

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier: (NSString *) itemIdent willBeInsertedIntoToolbar:(BOOL) willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    
    if ([itemIdent isEqual: @"Save Document Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Save",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Save",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Save Your Document",@"")];
		[toolbarItem setImage: [NSImage imageNamed:@"save_document"]];
		
		// Tell the item what message to send when it is clicked 
		[toolbarItem setTarget: [self document]];
		[toolbarItem setAction: @selector(saveDocument:)];
    }  else if ([itemIdent isEqual: @"Identify Baseline Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Baseline",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Baseline",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the baseline in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Baseline"]];
		
		// Tell the item what message to send when it is clicked 
//		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(obtainBaseline:)];
    }   else if ([itemIdent isEqual: @"Identify Peaks Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Peaks",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Peaks",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Peaks"]];
		
		// Tell the item what message to send when it is clicked 
//		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(identifyPeaks:)];
    } else if ([itemIdent isEqual: @"Identify Compounds Item Identifier"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Identify Compounds",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Identify Compounds",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Identify the compounds associated with the peaks in your chromatogram",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"Identify Compounds"]];
		
		// Tell the item what message to send when it is clicked 
//		[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(identifyCompounds:)];
    } else if ([itemIdent isEqual: @"Inspector"]) {
		// Set the text label to be displayed in the toolbar and customization palette 
		[toolbarItem setLabel:NSLocalizedString(@"Inspector",@"")];
		[toolbarItem setPaletteLabel:NSLocalizedString(@"Inspector",@"")];
		
		// Set up a reasonable tooltip, and image   Note, these aren't localized, but you will likely want to localize many of the item's properties 
		[toolbarItem setToolTip:NSLocalizedString(@"Show an inspector to change attributs of the selected object",@"")];
		[toolbarItem setImage: [NSImage imageNamed: @"info"]];
		
		// Tell the item what message to send when it is clicked 
		//	[toolbarItem setTarget: self];
		[toolbarItem setAction: @selector(showInspector:)];
    }   else {
		// itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
		// Returning nil will inform the toolbar this kind of item is not supported 
		toolbarItem = nil;
    }
    return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the ordered list of items to be shown in the toolbar by default    
    // If during the toolbar's initialization, no overriding values are found in the user defaults, or if the
    // user chooses to revert to the default items this set will be used 
    return [NSArray arrayWithObjects:	@"Save Document Item Identifier", NSToolbarPrintItemIdentifier, NSToolbarFlexibleSpaceItemIdentifier, @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier", NSToolbarFlexibleSpaceItemIdentifier, 
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarSeparatorItemIdentifier, @"Inspector", nil];
}

- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    // Required delegate method:  Returns the list of all allowed items by identifier.  By default, the toolbar 
    // does not assume any items are allowed, even the separator.  So, every allowed item must be explicitly listed   
    // The set of allowed items is used to construct the customization palette 
    return [NSArray arrayWithObjects:  @"Identify Baseline Item Identifier", @"Identify Peaks Item Identifier", @"Identify Compounds Item Identifier",  @"Save Document Item Identifier", NSToolbarPrintItemIdentifier, @"Inspector",
        NSToolbarShowColorsItemIdentifier, NSToolbarShowFontsItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier, NSToolbarSpaceItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
}

- (void) toolbarWillAddItem: (NSNotification *) notif {
    // Optional delegate method:  Before an new item is added to the toolbar, this notification is posted.
    // This is the best place to notice a new item is going into the toolbar.  For instance, if you need to 
    // cache a reference to the toolbar item or need to set up some initial state, this is the best place 
    // to do it.  The notification object is the toolbar to which the item is being added.  The item being 
    // added is found by referencing the @"item" key in the userInfo 
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey: @"item"];
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		[addedItem setToolTip:NSLocalizedString(@"Print Your Document",@"")];
		//	[addedItem setTarget: self];
    }
}  

- (void) toolbarDidRemoveItem: (NSNotification *) notif {
    // Optional delegate method:  After an item is removed from a toolbar, this notification is sent.   This allows 
    // the chance to tear down information related to the item that may have been cached.   The notification object
    // is the toolbar from which the item is being removed.  The item being added is found by referencing the @"item"
    // key in the userInfo 
	//    NSToolbarItem *removedItem = [[notif userInfo] objectForKey: @"item"];
	
}

- (BOOL) validateToolbarItem: (NSToolbarItem *) toolbarItem {
    // Optional method:  This message is sent to us since we are the target of some toolbar item actions 
    // (for example:  of the save items action) 
    BOOL enable = NO;
    if ([[toolbarItem itemIdentifier] isEqual: @"Save Document Item Identifier"]) {
		// We will return YES (ie  the button is enabled) only when the document is dirty and needs saving 
		enable = [[self document] isDocumentEdited];
		enable = YES;
    } else if ([[toolbarItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Baseline Item Identifier"]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Peaks Item Identifier"]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Identify Compounds Item Identifier"]) {
		enable = YES;
    }else if ([[toolbarItem itemIdentifier] isEqual: @"Inspector"]) {
		enable = YES;
    }
    return enable;
}
#pragma mark -

- (BOOL)windowShouldClose:(id)sender
{
    return NO;
}
@end
