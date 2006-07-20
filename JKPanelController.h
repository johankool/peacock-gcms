//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKPathPopUpButton;

@interface JKPanelController : NSWindowController {
	
	IBOutlet NSView *infoPanelView;
	IBOutlet NSView *processingPanelView;
	IBOutlet NSView *viewPanelView;
	IBOutlet NSView *displayPanelView;
	IBOutlet NSView *naPanelView;
	
    // Info Panel
    IBOutlet NSTableView *infoTableView;

	// Processing Panel
	IBOutlet JKPathPopUpButton *libraryPopUpButton;
	
    // Display Panel
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *subTitleTextField;
	IBOutlet NSTextField *xAxisTextField;
	IBOutlet NSTextField *yAxisTextField;
	    
	NSMutableDictionary*	inspectorListForDocument;		// Auto-generated from tab view's items.
	NSMutableDictionary*	inspectorListForMyGraphView;		// Auto-generated from tab view's items.

	IBOutlet NSObjectController *inspectedDocumentController;
    NSView *inspectedGraphView;
	NSDocument *inspectedDocument;
    
} 

#pragma mark INITIALIZATION

+ (JKPanelController *) sharedController;

#pragma mark IBACTIONS

- (IBAction)showInspector:(id)sender;
- (IBAction)resetToDefaultValues:(id)sender;

#pragma mark ACCESSORS

//- (NSDocument *)inspectedDocument;
//- (void)setInspectedDocument:(NSDocument *)document;
idAccessor_h(inspectedGraphView, setInspectedGraphView)
idAccessor_h(inspectedDocument, setInspectedDocument)

#pragma mark MENU VALIDATION

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end
