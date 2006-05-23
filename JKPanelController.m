//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPanelController.h"

#import "JKGCMSDocument.h"
#import "MyGraphView.h"
#import "netcdf.h"

static JKPanelController *theSharedController;

@implementation JKPanelController

+ (JKPanelController *) sharedController  
{
    if (theSharedController == nil) {
		
        theSharedController = [[JKPanelController alloc] initWithWindowNibName: @"JKPanel"];
		 
        NSNotificationCenter *center;
		center = [NSNotificationCenter defaultCenter];
        
        [center addObserver: theSharedController
				   selector: @selector(documentActivateNotification:)
					   name: NSWindowDidBecomeMainNotification
					 object: nil];
        
        [center addObserver: theSharedController
				   selector: @selector(documentDeactivateNotification:)
					   name: NSWindowDidResignMainNotification
					 object: nil];

        [center addObserver: theSharedController
				   selector: @selector(plotViewDidBecomeFirstResponderNotification:)
					   name: MyGraphView_DidBecomeFirstResponderNotification
					 object: nil];

        [center addObserver: theSharedController
				   selector: @selector(plotViewDidResignFirstResponderNotification:)
					   name: MyGraphView_DidResignFirstResponderNotification
					 object: nil];
    }
	
    return (theSharedController);
	
} 

- (void)dealloc  
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self
					  name: nil
					object: nil];
	
    [super dealloc];
}

- (void)windowDidLoad  
{
    [super windowDidLoad];
	
    [self setShouldCascadeWindows: NO];
    [self setWindowFrameAutosaveName: @"JKPanelWindow"];
	
	inspectorListForDocument = [[NSMutableDictionary alloc] init];
	[inspectorListForDocument setValue:@"Info" forKey:@"info"];
	[inspectorListForDocument setValue:@"Processing" forKey:@"processing"];
	
	inspectorListForMyGraphView = [[NSMutableDictionary alloc] init];
	[inspectorListForMyGraphView setValue:@"View" forKey:@"view"];
	[inspectorListForMyGraphView setValue:@"Display" forKey:@"display"];
	
    // Rich text in our fields! 
    [titleTextField setAllowsEditingTextAttributes:YES];
    [subTitleTextField setAllowsEditingTextAttributes:YES];
    [xAxisTextField setAllowsEditingTextAttributes:YES];
    [yAxisTextField setAllowsEditingTextAttributes:YES];
 
	
   // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"nl.johankool.Peacock.panel.toolbar"] autorelease];
    
    // Set up toolbar properties: Allow customization, give a default display mode, and remember state in user defaults 
    [toolbar setAllowsUserCustomization: NO];
    [toolbar setAutosavesConfiguration: YES];
    [toolbar setDisplayMode: NSToolbarDisplayModeIconAndLabel];
    [toolbar setSizeMode: NSToolbarSizeModeSmall];
    
    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	
	// Set an initial state
	[toolbar setSelectedItemIdentifier:@"info"];
	
	if ([[[[[NSApplication sharedApplication] orderedWindows] objectAtIndex:0] document] isKindOfClass:[JKGCMSDocument class]]) {
		[self setInspectedDocument:[[[[NSApplication sharedApplication] orderedWindows] objectAtIndex:0] document]];
		[[self window] setContentView:infoPanelView];
		[infoTableView reloadData];
    } else {
		[[self window] setContentView:naPanelView];
	}
	
	// Bind libraryPopUpButton manually
	[libraryPopUpButton bind:@"fileAlias" toObject:inspectedDocumentController withKeyPath:@"selection.libraryAlias" options:nil];

}


#pragma mark NOTIFICATIONS

- (void)documentActivateNotification:(NSNotification *)aNotification  
{
	if ([[[aNotification object] document] isKindOfClass:[JKGCMSDocument class]]) {
		if ([[aNotification object] document] != inspectedDocument) {
			[self setInspectedDocument:[[aNotification object] document]];
			[infoTableView reloadData];
			if ([[[aNotification object] firstResponder] isKindOfClass:[MyGraphView class]]) {
				[self setInspectedGraphView:[[aNotification object] firstResponder]];
			} else {
				[self setInspectedGraphView:nil];
			}
		}

		NSRect windowFrame = [[self window] frame];
		float deltaHeight;

		if ([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"info"]) {
			deltaHeight = [infoPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:infoPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"processing"]) {
			deltaHeight = [processingPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:processingPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"view"]) {
			deltaHeight = [viewPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:viewPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"display"]) {
			deltaHeight = [displayPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:displayPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else {
			[[self window] setContentView:naPanelView];
		}		
		
    }  else {
		[[self window] setContentView:naPanelView];
		[self setInspectedDocument:nil];
	}
}

- (void)documentDeactivateNotification: (NSNotification *) aNotification  
{
	[[self window] setContentView:naPanelView];
	[self setInspectedDocument:nil];	
} 

- (void)plotViewDidBecomeFirstResponderNotification:(NSNotification *)aNotification 
{
	if ([[aNotification object] isKindOfClass:[MyGraphView class]]) {
		if ([aNotification object] != inspectedGraphView) {
			[self setInspectedGraphView:[aNotification object]];
		}
	} else {
		[self setInspectedGraphView:nil];
	}
}

- (void)plotViewDidResignFirstResponderNotification:(NSNotification *)aNotification 
{
	[self setInspectedGraphView:nil];
}
 
- (IBAction)showInspector:(id)sender  
{
	if (![[self window] isVisible]) {
        [[self window] orderFront:self];
    } else {
        [[self window] orderOut:self];
    }
}

- (IBAction)resetToDefaultValues:(id)sender  
{
	[[self inspectedDocument] resetToDefaultValues];
}

// Info tableView
- (int)numberOfRowsInTableView:(NSTableView *)tableView  
{
    int count, dummy, ncid;
    if (tableView ==  infoTableView) {
		if([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[JKGCMSDocument class]]) {
			ncid = [(JKGCMSDocument *)[self inspectedDocument] ncid];
			dummy =  nc_inq_natts(ncid, &count);
			if (dummy == NC_NOERR) return count;
			return -1;			
		} else {
			return -1;
		}
    } 
	//[NSException raise:NSInvalidArgumentException format:@"Exception raised in JKPanelController -numberOfRowsInTableView: - tableView not known"];
    return -1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row  
{
    int dummy;
    NSMutableString *nameString, *keyString;
    
    if (tableView == infoTableView) {
        int ncid = [(JKGCMSDocument *)[self inspectedDocument] ncid];
        char name[256];
        char value[256];
        
        dummy =  nc_inq_attname (ncid,NC_GLOBAL, row, (void *) &name);
        dummy =  nc_get_att_text(ncid,NC_GLOBAL, name, (void *) &value);
        
        nameString = [NSMutableString stringWithCString:name];
        keyString = [NSMutableString stringWithCString:value];

        if ([[tableColumn identifier] isEqualToString:@"name"]) {
            // We need to replace "_" with " "
            dummy = [nameString replaceOccurrencesOfString:@"_" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [nameString length])];

            return [nameString capitalizedString];
        } else if ([[tableColumn identifier] isEqualToString:@"value"]) {
            /*
             NSCalendarDate *date;
            if ([nameString rangeOfString:@"time_stamp"].location > 0) {
                JKLogDebug(@"date");
                date = [NSCalendarDate dateWithString:keyString calendarFormat:@"%Y%m%d%H%M%S%z"];
                keyString = "2323";
                return keyString;
            }
             */
             return keyString;
        } else {
            [NSException raise:NSInvalidArgumentException format:@"Exception raised in JKPanelController -tableView:objectValueForTableColumn:row: - tableColumn identifier not known"];
            return nil;
        }        
    } 

    [NSException raise:NSInvalidArgumentException format:@"Exception raised in JKPanelController -tableView:objectValueForTableColumn:row: - tableView not known"];
    return nil;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem  
{
	if ([anItem action] == @selector(showWindow:)) {
		if ([[self window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Inspector",@"Menutitle when inspector is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Inspector",@"Menutitle when inspector is not visible")];
		}			
		return YES;
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

#pragma mark TOOLBAR

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted  
{
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel = NSLocalizedString(itemIdent, @"String for toolbar label");//[itemsList objectForKey:itemIdent];
//    if( (itemLabel = [itemsList objectForKey:itemIdent]) != nil )
//    {
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
//    {
//		JKLogDebug([toolbarItem description]);
//        // itemIdent refered to a toolbar item that is not provide or supported by us or cocoa 
//        // Returning nil will inform the toolbar this kind of item is not supported 
//        toolbarItem = nil;
//    }
    
    return toolbarItem;
}


- (IBAction)changePanes:(id)sender  
{
	if ([self inspectedDocument]) {
		NSRect windowFrame = [[self window] frame];
		float deltaHeight;
		if ([[sender itemIdentifier] isEqualToString:@"info"]) {
			deltaHeight = [infoPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:infoPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[sender itemIdentifier] isEqualToString:@"processing"]) {
			deltaHeight = [processingPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:processingPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[sender itemIdentifier] isEqualToString:@"view"]) {
			deltaHeight = [viewPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:viewPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else if ([[sender itemIdentifier] isEqualToString:@"display"]) {
			deltaHeight = [displayPanelView frame].size.height - [[[self window] contentView] frame].size.height;
			[[self window] setContentView:displayPanelView];
			[[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:NO];
		} else {
			[[self window] setContentView:naPanelView];
		}		
	} else {
		[[self window] setContentView:naPanelView];
	}
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar  
{
     return [[inspectorListForDocument allKeys] arrayByAddingObjectsFromArray:[inspectorListForMyGraphView allKeys]];
}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar  
{
     return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar  
{
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

#pragma mark ACCESSORS (MACROSTYLE)
idAccessor(inspectedDocument, setInspectedDocument);
idAccessor(inspectedGraphView, setInspectedGraphView);

@end
