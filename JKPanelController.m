//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPanelController.h"
#import "netcdf.h"
#import "MyGraphView.h"
#import "JKMainDocument.h"
#import "JKDataModel.h"

static JKPanelController *theSharedController;


@implementation JKPanelController

+ (JKPanelController *) sharedController {
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

-(void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self
					  name: nil
					object: nil];
	
    [super dealloc];
}

-(void)windowDidLoad {
    [super windowDidLoad];
	
    [self setShouldCascadeWindows: NO];
    [self setWindowFrameAutosaveName: @"JKPanelWindow"];
	
	inspectorListForDocument = [[NSMutableDictionary alloc] init];
	[inspectorListForDocument setObject:@"Info" forKey:@"info"];
	
	inspectorListForMyGraphView = [[NSMutableDictionary alloc] init];
	[inspectorListForMyGraphView setObject:@"View" forKey:@"view"];
	[inspectorListForMyGraphView setObject:@"Options" forKey:@"options"];
	[inspectorListForMyGraphView setObject:@"Dataseries" forKey:@"dataSeries"];
	[inspectorListForMyGraphView setObject:@"Text" forKey:@"text"];
	[inspectorListForMyGraphView setObject:@"Font & Color" forKey:@"fontcolor"];
	
    [self setInspectedDocument: [self inspectedDocument]];
    [self setInspectedPlotView: [self inspectedPlotView]];

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
    [toolbar setDisplayMode: NSToolbarDisplayModeIconOnly];
    [toolbar setSizeMode: NSToolbarSizeModeSmall];
    
    // We are the delegate
    [toolbar setDelegate: self];
	
    // Attach the toolbar to the document window 
    [[self window] setToolbar: toolbar];
	
	// Set an initial state
	[toolbar setSelectedItemIdentifier:@"info"];
	[[self window] setContentView:infoPanelView];
}

-(void)setupInspector:(id)object {
	if (object == nil) {
		return;
	}
    if ([object isKindOfClass:[MyGraphView class]] && [[self window] isVisible]) {
        [self setInspectedPlotView:object];
        
        [objectController willChangeValueForKey:@"Content"];
        [objectController setContent:object];
        [objectController didChangeValueForKey:@"Content"];
    } else if ([object isKindOfClass:[JKMainDocument class]] && [[self window] isVisible]) {
		[infoTableView reloadData];
    } else {		
        [self disableInspector:object];
    }
}

-(void)disableInspector:(id)object {
	[objectController willChangeValueForKey:@"Content"];
	[objectController setContent:nil];
	[objectController didChangeValueForKey:@"Content"];
	[self setInspectedPlotView:nil];
	[infoTableView reloadData];
}

-(NSDocument *)inspectedDocument {
	return inspectedDocument;
}

- (void)setInspectedDocument: (NSDocument *) document {
	[document retain];
	[inspectedDocument autorelease];
	inspectedDocument = document;

	[self setupInspector:document];	
}

#pragma mark NOTIFICATIONS

-(void)windowDidBecomeMain:(NSNotification *)aNotification {
    [self setupInspector:[[aNotification object] firstResponder]];
}

-(void)windowDidResignMain:(NSNotification *)aNotification {
    [self disableInspector:[[aNotification object] firstResponder]];
}

-(void)documentActivateNotification: (NSNotification *) notification {
	NSWindow *window = [notification object];
    NSDocument *document = [[window windowController] document];
	[self setInspectedDocument:document];
}

-(void)documentDeactivateNotification: (NSNotification *) notification {
    [self setInspectedDocument:nil];	
} 

-(void)plotViewDidBecomeFirstResponderNotification:(NSNotification *)aNotification{
    [self setupInspector:[aNotification object]];
}

-(void)plotViewDidResignFirstResponderNotification:(NSNotification *)aNotification{
    [self disableInspector:[aNotification object]];
}
 
-(IBAction)showInspector:(id)sender {
	if (![[self window] isVisible]) {
        [[self window] orderFront:self];
    } else {
        [[self window] orderOut:self];
    }
}

-(void)templatePullDownMenuAction:(id)sender {
    JKLogDebug(@"%@, tag %d", [sender titleOfSelectedItem], [[sender selectedItem] tag]);
}


    // Template


// Info tableView
-(int)numberOfRowsInTableView:(NSTableView *)tableView {
    int count, dummy, ncid;
    if (tableView ==  infoTableView) {
		if([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[JKMainDocument class]]) {
			ncid = [[(JKMainDocument *)[self inspectedDocument] dataModel] ncid];
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

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    int dummy;
    NSMutableString *nameString, *keyString;
    
    if (tableView == infoTableView) {
        int ncid = [[(JKMainDocument *)[self inspectedDocument] dataModel] ncid];
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


idAccessor(inspectedPlotView, setInspectedPlotView);

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	if ([anItem action] == @selector(showInspector:)) {
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

-(NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
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


-(IBAction)changePanes:(id)sender {
	if ([[sender itemIdentifier] isEqualToString:@"info"]) {
		[[self window] setContentView:infoPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"view"]) {
		[[self window] setContentView:viewPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"options"]) {
		[[self window] setContentView:optionsPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"dataSeries"]) {
		[[self window] setContentView:dataSeriesPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"text"]) {
		[[self window] setContentView:textPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"fontcolor"]) {
		[[self window] setContentView:fontcolorPanelView];
	} else {
		JKLogError(@"Unknown pane.");
	}
}


-(NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
     return [[inspectorListForDocument allKeys] arrayByAddingObjectsFromArray:[inspectorListForMyGraphView allKeys]];
}

-(NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar {
     return [self toolbarDefaultItemIdentifiers:toolbar];
}

-(NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

#pragma mark ACCESSORS (MACROSTYLE)
//idAccessor_h(inspectedDocument, setInspectedDocument);

@end
