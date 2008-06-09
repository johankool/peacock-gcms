//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKPanelController.h"

#import "PKGCMSDocument.h"
// #import "JKStatisticsDocument.h"
#import "PKGraphView.h"
#import "netcdf.h"
#import "PKFontNameToDisplayNameTransformer.h"

static PKPanelController *theSharedController;

@implementation PKPanelController

+ (PKPanelController *) sharedController {
    if (theSharedController == nil) {
		
        theSharedController = [[PKPanelController alloc] initWithWindowNibName: @"PKPanel"];
		 
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
				   selector: @selector(documentActivateNotification:)
					   name: @"JKGCMSDocument_DocumentActivateNotification"
					 object: nil];
        
        [center addObserver: theSharedController
				   selector: @selector(documentDeactivateNotification:)
					   name: @"JKGCMSDocument_DocumentDeactivateNotification"
					 object: nil];
        
        [center addObserver: theSharedController
				   selector: @selector(plotViewDidBecomeFirstResponderNotification:)
					   name: MyGraphView_DidBecomeFirstResponderNotification
					 object: nil];

        [center addObserver: theSharedController
				   selector: @selector(plotViewDidResignFirstResponderNotification:)
					   name: MyGraphView_DidResignFirstResponderNotification
					 object: nil];
        
        // Create and register font name value transformer
        NSValueTransformer *transformer = [[PKFontNameToDisplayNameTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"FontNameToDisplayNameTransformer"];
        
    }
	
    return (theSharedController);
	
} 

- (void)dealloc {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self
					  name: nil
					object: nil];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
	
    [self setShouldCascadeWindows: NO];
    [self setWindowFrameAutosaveName: @"PKPanelWindow"];
	
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
	
   
//	// Bind libraryPopUpButton manually
//	[libraryPopUpButton bind:@"fileAlias" toObject:inspectedDocumentController withKeyPath:@"selection.libraryAlias" options:nil];

	// Set an initial state
	[toolbar setSelectedItemIdentifier:@"info"];
	[self changePanes:self];
    
}

#pragma mark IBACTIONS

- (void)changeTextFont:(id)sender{
	/*
	 The user wants to change the  font selection, so update the default font
     */
    if ([sender state] == NSOffState) {
        return;
    }

	NSFont *font;
    
    if (sender == labelFontButton) {
        font = [inspectedGraphView labelFont];
        [axesLabelFontButton setState:NSOffState];
        [legendFontButton setState:NSOffState];
    } else if (sender == legendFontButton) {
        font = [inspectedGraphView legendFont];        
        [labelFontButton setState:NSOffState];
        [axesLabelFontButton setState:NSOffState];
    } else if (sender == axesLabelFontButton) {
        font = [inspectedGraphView axesLabelFont];        
        [legendFontButton setState:NSOffState];
        [labelFontButton setState:NSOffState];
    } else {
        [NSException raise:@"Unknown Font" format:@"It is not clear what font you are trying to change. Contact the Peacock developer about this problem."];
    }

	[[NSFontManager sharedFontManager] setSelectedFont:font 
											isMultiple:NO];
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
	
	// Set window as firstResponder so we get changeFont: messages
    [[self window] makeFirstResponder:[self window]];
}

- (void)changeFont:(id)sender{
	/*
	 This is the message the font panel sends when a new font is selected
	 */
	// Get selected font
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *selectedFont = [fontManager selectedFont];
	if (selectedFont == nil)
	{
		selectedFont = [NSFont systemFontOfSize:[NSFont systemFontSize]];
	}
	NSFont *panelFont = [fontManager convertFont:selectedFont];
	
    if ([labelFontButton state] == NSOnState) {
        [inspectedGraphView setLabelFont:panelFont];
    } else if ([axesLabelFontButton state] == NSOnState) {
        [inspectedGraphView setAxesLabelFont:panelFont];
    } else if ([legendFontButton state] == NSOnState) {
        [inspectedGraphView setLegendFont:panelFont];
    } else {
//        [NSException raise:@"Unknown Font" format:@"It is not clear what font you are trying to change. Contact the Peacock developer about this problem."];
    }
}


#pragma mark NOTIFICATIONS

- (void)documentActivateNotification:(NSNotification *)aNotification {
	if ([[aNotification object] isKindOfClass:[PKGCMSDocument class]]) {
		if ([aNotification object] != inspectedDocument) {
			[self setInspectedDocument:[aNotification object]];
			[infoTableView reloadData];
		}
    } else if ([[aNotification object] isKindOfClass:[NSWindow class]]) {
        if ([[[aNotification object] document] isKindOfClass:[PKGCMSDocument class]]) { 
            if ([[aNotification object] document] != inspectedDocument) {
                [self setInspectedDocument:[[aNotification object] document]];
                [infoTableView reloadData];
            }
        }
        if ([[[aNotification object] firstResponder] isKindOfClass:[PKGraphView class]]) {
            [self setInspectedGraphView:[[aNotification object] firstResponder]];
        }
    }  else  {
		[self setInspectedDocument:nil];
        [self setInspectedGraphView:nil];
	}

    [legendFontButton setState:NSOffState];
    [labelFontButton setState:NSOffState];
    [axesLabelFontButton setState:NSOffState];
    [self changePanes:self];
}

- (void)documentDeactivateNotification: (NSNotification *) aNotification {
    [self setInspectedGraphView:nil];
	[self setInspectedDocument:nil];	
    [self changePanes:self];
} 

- (void)plotViewDidBecomeFirstResponderNotification:(NSNotification *)aNotification {
	if ([[aNotification object] isKindOfClass:[PKGraphView class]]) {
		if ([aNotification object] != inspectedGraphView) {
			[self setInspectedGraphView:[aNotification object]];
		}        
	} else {
		[self setInspectedGraphView:nil];
	}
    [self changePanes:self];
}

- (void)plotViewDidResignFirstResponderNotification:(NSNotification *)aNotification {
	[self setInspectedGraphView:nil];
    [self changePanes:self];
}
 
- (IBAction)showInspector:(id)sender {
	if (![[self window] isVisible]) {
        [[self window] orderFront:self];
    } else {
        [[self window] orderOut:self];
    }
}

- (IBAction)resetToDefaultValues:(id)sender {
	[[self inspectedDocument] resetToDefaultValues];
}

// Info tableView
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView ==  infoTableView) {
		if([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[PKGCMSDocument class]]) {
            return [(PKGCMSDocument *)[self inspectedDocument] numberOfRowsInTableView:tableView];
 //       } else if ([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[JKStatisticsDocument class]]) {
//            return [(JKStatisticsDocument *)[[self inspectedDocument] statisticsWindowController] numberOfRowsInTableView:tableView];
		} else {
			return -1;
		}
    } 
    return -1;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row {
    if (tableView == infoTableView) {
		if([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[PKGCMSDocument class]]) {
            return [(PKGCMSDocument *)[self inspectedDocument] tableView:tableView objectValueForTableColumn:tableColumn row:row];
 //       } else if ([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[JKStatisticsDocument class]]) {
//           return [(JKStatisticsDocument *)[[self inspectedDocument] statisticsWindowController] tableView:tableView objectValueForTableColumn:tableColumn row:row];
		} 
    } 

//    [NSException raise:NSInvalidArgumentException format:@"Exception raised in PKPanelController -tableView:objectValueForTableColumn:row: - tableView not known"];
    return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (aTableView == infoTableView) {
		if([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[PKGCMSDocument class]]) {
            return [(PKGCMSDocument *)[self inspectedDocument] tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
//        } else if ([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[JKStatisticsDocument class]]) {
//            return [(JKStatisticsDocument *)[[self inspectedDocument] statisticsWindowController] tableView:aTableView setObjectValue:anObject forTableColumn:aTableColumn row:rowIndex];
		} else {
			return;
		}
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
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

- (NSToolbarItem *) toolbar: (NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdent willBeInsertedIntoToolbar:(BOOL)willBeInserted {
    // Required delegate method:  Given an item identifier, this method returns an item 
    // The toolbar will use this method to obtain toolbar items that can be displayed in the customization sheet, or in the toolbar itself 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdent] autorelease];
    NSString*		itemLabel = NSLocalizedString(itemIdent, @"String for toolbar label");//[itemsList objectForKey:itemIdent];
    [toolbarItem setLabel: itemLabel];
    [toolbarItem setPaletteLabel: itemLabel];
    [toolbarItem setToolTip: itemLabel];
    [toolbarItem setImage: [NSImage imageNamed:itemIdent]];
    
    // Tell the item what message to send when it is clicked 
    [toolbarItem setTarget: self];
    [toolbarItem setAction: @selector(changePanes:)];
    
    return toolbarItem;
}


- (IBAction)changePanes:(id)sender {
    NSRect windowFrame = [[self window] frame];
    float deltaHeight;
    if (([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"info"]) && ([self inspectedDocument])) {
        deltaHeight = [infoPanelView frame].size.height - [[[self window] contentView] frame].size.height;
        [[self window] setContentView:infoPanelView];
        [[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:YES];
    } else if (([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"processing"]) && ([self inspectedDocument] && [[self inspectedDocument] isKindOfClass:[PKGCMSDocument class]])) {
        deltaHeight = [processingPanelView frame].size.height - [[[self window] contentView] frame].size.height;
        [[self window] setContentView:processingPanelView];
        [[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:YES];
    } else if (([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"view"]) && ([self inspectedGraphView])) {
        deltaHeight = [viewPanelView frame].size.height - [[[self window] contentView] frame].size.height;
        [[self window] setContentView:viewPanelView];
        [[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:YES];
    } else if (([[[[self window] toolbar] selectedItemIdentifier] isEqualToString:@"display"]) && ([self inspectedGraphView])) {
        deltaHeight = [displayPanelView frame].size.height - [[[self window] contentView] frame].size.height;
        [[self window] setContentView:displayPanelView];
        [[self window] setFrame:NSMakeRect(windowFrame.origin.x,windowFrame.origin.y-deltaHeight,windowFrame.size.width,windowFrame.size.height+deltaHeight) display:YES animate:YES];
    } else {
        [[self window] setContentView:naPanelView];
    }		
}


- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:@"info", @"processing", @"view", @"display", nil];}

- (NSArray*) toolbarSelectableItemIdentifiers: (NSToolbar *) toolbar {
    return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray*) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

#pragma mark ACCESSORS (MACROSTYLE)

- (id)inspectedDocument {
	return inspectedDocument;
}
- (void)setInspectedDocument:(id)aInspectedDocument {
	inspectedDocument = aInspectedDocument;
}
- (id)inspectedGraphView {
	return inspectedGraphView;
}
- (void)setInspectedGraphView:(id)aInspectedGraphView {
	inspectedGraphView = aInspectedGraphView;
}

- (NSTableView *)infoTableView {
    return infoTableView;
}
//idAccessor(inspectedDocument, setInspectedDocument)
//idAccessor(inspectedGraphView, setInspectedGraphView)

@synthesize infoPanelView;
@synthesize viewPanelView;
@synthesize labelFontButton;
@synthesize infoTableView;
@synthesize libraryPopUpButton;
@synthesize axesLabelFontButton;
@synthesize processingPanelView;
@synthesize displayPanelView;
@synthesize naPanelView;
@synthesize xAxisTextField;
@synthesize titleTextField;
@synthesize subTitleTextField;
@synthesize legendFontButton;
@synthesize inspectedDocumentController;
@synthesize yAxisTextField;
@end