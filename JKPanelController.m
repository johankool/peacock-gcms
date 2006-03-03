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
					   name: JKMainDocument_DocumentActivateNotification
					 object: nil];
        
        [center addObserver: theSharedController
				   selector: @selector(documentDeactivateNotification:)
					   name: JKMainDocument_DocumentDeactivateNotification
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
	[inspectorListForMyGraphView setObject:@"Dataseries" forKey:@"dataSeries"];
	[inspectorListForMyGraphView setObject:@"Text" forKey:@"text"];
	[inspectorListForMyGraphView setObject:@"Font & Color" forKey:@"fontcolor"];
	
    [self setDocument: [self document]];
    [self setInspectedPlotView: [self inspectedPlotView]];

    // Rich text in our fields! 
    [titleTextField setAllowsEditingTextAttributes:YES];
    [subTitleTextField setAllowsEditingTextAttributes:YES];
    [xAxisTextField setAllowsEditingTextAttributes:YES];
    [yAxisTextField setAllowsEditingTextAttributes:YES];
 
   // Create a new toolbar instance, and attach it to our document window 
    NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier: @"nl.vu.geo.kool.Peacock.panel.toolbar"] autorelease];
    
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
//	NSMutableDictionary *mutDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:NSToolbarDisplayModeIconOnly, @"displayMode", YES, @"isVisible", nil];
//	if (document) {
//		if (inspectedPlotView) {
//			[inspectorListForDocument allKeys];
//		}
//	}
	if (object == nil) {
		return;
	}
	JKLogDebug([object description]);
    if ([object isKindOfClass:[MyGraphView class]] && [[self window] isVisible]) {
        [self setInspectedPlotView:object];
//        [templatePullDownMenu setHidden:NO];
        
        [objectController willChangeValueForKey:@"Content"];
        [objectController setContent:object];
        [objectController didChangeValueForKey:@"Content"];
		[infoTableView reloadData];
        [self willChangeValueForKey:@"sampleCode"];
        [self didChangeValueForKey:@"sampleCode"];
        [self willChangeValueForKey:@"sampleDescription"];
        [self didChangeValueForKey:@"sampleDescription"];
		
    } else if ([object isKindOfClass:[JKMainDocument class]] && [[self window] isVisible]) {
        [self setInspectedPlotView:object];
//        [templatePullDownMenu setHidden:NO];
        
        [objectController willChangeValueForKey:@"Content"];
        [objectController setContent:object];
        [objectController didChangeValueForKey:@"Content"];
		[infoTableView reloadData];
        [self willChangeValueForKey:@"sampleCode"];
        [self didChangeValueForKey:@"sampleCode"];
        [self willChangeValueForKey:@"sampleDescription"];
        [self didChangeValueForKey:@"sampleDescription"];
		
		
    } else {
        [self disableInspector:object];
    }
}

-(void)disableInspector:(id)object {
//   [templatePullDownMenu setHidden:YES];
}

- (void) setDocument: (NSDocument *) document
{
    [super setDocument:document];

	[self setupInspector:document];

//    NSScrollView *view;
//    view = [document valueForKey: @"layerViewScrollView"];
//	
//    [pannerView setScrollView: view];
	
} // setDocument

-(void)windowDidBecomeMain:(NSNotification *)aNotification {
    [self setupInspector:[[aNotification object] firstResponder]];
}

-(void)windowDidResignMain:(NSNotification *)aNotification {
    [self disableInspector:[[aNotification object] firstResponder]];
}


- (void) documentActivateNotification: (NSNotification *) notification {
    NSDocument *document = [notification object];
    [self setDocument: document];
}


- (void) documentDeactivateNotification: (NSNotification *) notification
{
    [self setDocument: nil];
	
} 
-(void)plotViewDidBecomeFirstResponderNotification:(NSNotification *)aNotification{
    [self setupInspector:[aNotification object]];
}

-(void)plotViewDidResignFirstResponderNotification:(NSNotification *)aNotification{
    [self disableInspector:[aNotification object]];
}

//-(void)showInspector {
//    [panelWindow orderFront:self];
//}
 
-(IBAction)showInspector:(id)sender
{
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
    if ((tableView ==  infoTableView) && [[objectController content] isKindOfClass:[MyGraphView class]]) {
		ncid = [[(JKMainDocument *)[self document] dataModel] ncid];
        dummy =  nc_inq_natts(ncid, &count);
        JKLogDebug(@"%d", count);
        if (dummy == NC_NOERR) return count;
        return -1;
    } 
    
//    [NSException raise:NSInvalidArgumentException format:@"Exception raised in JKPanelController -numberOfRowsInTableView: - tableView not known"];
    return -1;
}

-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    int dummy;
    NSMutableString *nameString, *keyString;
    
    if (tableView == infoTableView) {
        int ncid = [[(JKMainDocument *)[self document] dataModel] ncid];
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
//
//-(IBAction)addTemplate:(id)sender {
//    [self showSaveSheet:[self window]];
//}
//
//-(void)showSaveSheet: (NSWindow *)window
//    // User has asked to see the custom display. Display it.
//{
//    if (!saveSheet)
//        [NSBundle loadNibNamed: @"MyCustomSheet" owner: self];
//    
//    [NSApp beginSheet: saveSheet        
//       modalForWindow: window
//        modalDelegate: nil
//       didEndSelector: nil
//          contextInfo: nil];
//    
//    [NSApp runModalForWindow: saveSheet];
//    
//    // Sheet is up here.
//    [NSApp endSheet: saveSheet];
//    [saveSheet orderOut: self];
//}
//
//-(IBAction)removeTemplate:(id)sender {
//    [self showDeleteSheet:[self window]];
//}
//
//-(void)showDeleteSheet: (NSWindow *)window
//    // User has asked to see the custom display. Display it.
//{
//    if (!deleteSheet)
//        [NSBundle loadNibNamed: @"MyCustomSheet" owner: self];
//    
//    [NSApp beginSheet: deleteSheet        
//       modalForWindow: window
//        modalDelegate: nil
//       didEndSelector: nil
//          contextInfo: nil];
//    
//    [NSApp runModalForWindow: deleteSheet];
//    
//    // Sheet is up here.
//    [NSApp endSheet: deleteSheet];
//    [deleteSheet orderOut: self];
//}

-(NSString *)sampleCode {
	return [[[(JKMainDocument *)[self document] dataModel] metadata] valueForKey:@"sampleCode"];
}
-(void)setSampleCode:(NSString *)inString {
	[[[(JKMainDocument *)[self document] dataModel] metadata] setValue:inString forKey:@"sampleCode"];
}
-(NSString *)sampleDescription {
	return [[[(JKMainDocument *)[self document] dataModel] metadata] valueForKey:@"sampleDescription"];
}
-(void)setSampleDescription:(NSString *)inString {
	[[[(JKMainDocument *)[self document] dataModel] metadata] setValue:inString forKey:@"sampleDescription"];
}

idAccessor(inspectedPlotView, setInspectedPlotView)

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


-(void) setupToolbar {
	JKLogEnteringMethod();
}

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


-(IBAction)	changePanes: (id)sender
{
	if ([[sender itemIdentifier] isEqualToString:@"info"]) {
		[[self window] setContentView:infoPanelView];
	} else if ([[sender itemIdentifier] isEqualToString:@"view"]) {
		[[self window] setContentView:viewPanelView];
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


@end
