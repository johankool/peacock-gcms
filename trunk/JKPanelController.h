//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class PKGraphView;

@interface JKPanelController : NSWindowController {
	
	IBOutlet NSView *infoPanelView;
	IBOutlet NSView *processingPanelView;
	IBOutlet NSView *viewPanelView;
	IBOutlet NSView *displayPanelView;
	IBOutlet NSView *naPanelView;
	
    // Info Panel
    IBOutlet NSTableView *infoTableView;

	// Processing Panel
	IBOutlet NSPopUpButton *libraryPopUpButton;
	
    // Display Panel
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *subTitleTextField;
	IBOutlet NSTextField *xAxisTextField;
	IBOutlet NSTextField *yAxisTextField;
	IBOutlet NSButton *labelFontButton;
    IBOutlet NSButton *legendFontButton;
    IBOutlet NSButton *axesLabelFontButton;
    
	IBOutlet NSObjectController *inspectedDocumentController;
    PKGraphView *inspectedGraphView;
	NSDocument *inspectedDocument;
    
} 

#pragma mark INITIALIZATION

+ (JKPanelController *) sharedController;

#pragma mark IBACTIONS
- (void)changeTextFont:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)resetToDefaultValues:(id)sender;
- (IBAction)changePanes:(id)sender;

#pragma mark ACCESSORS
idAccessor_h(inspectedGraphView, setInspectedGraphView)
idAccessor_h(inspectedDocument, setInspectedDocument)
- (NSTableView *)infoTableView ;

#pragma mark MENU VALIDATION
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@property (retain) NSTextField *yAxisTextField;
@property (retain) NSButton *legendFontButton;
@property (retain) NSView *viewPanelView;
@property (retain,getter=infoTableView) NSTableView *infoTableView;
@property (retain) NSTextField *titleTextField;
@property (retain) NSView *infoPanelView;
@property (retain) NSPopUpButton *libraryPopUpButton;
@property (retain) NSView *naPanelView;
@property (retain) NSTextField *xAxisTextField;
@property (retain) NSButton *labelFontButton;
@property (retain) NSView *processingPanelView;
@property (retain) NSView *displayPanelView;
@property (retain) NSTextField *subTitleTextField;
@property (retain) NSButton *axesLabelFontButton;
@property (retain) NSObjectController *inspectedDocumentController;
@end
