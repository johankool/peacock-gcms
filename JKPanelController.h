//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@interface JKPanelController : NSWindowController {
	IBOutlet NSView*		panelView;		// From this view we pick up the window to change.
	NSMutableDictionary*	inspectorListForDocument;		// Auto-generated from tab view's items.
	NSMutableDictionary*	inspectorListForMyGraphView;		// Auto-generated from tab view's items.
	
	IBOutlet NSView *infoPanelView;
	IBOutlet NSView *viewPanelView;
	IBOutlet NSView *dataSeriesPanelView;
	IBOutlet NSView *textPanelView;
	IBOutlet NSView *fontcolorPanelView;
	IBOutlet NSView *optionsPanelView;
	
    // Info Panel
    IBOutlet NSTableView *infoTableView;

    // Text Panel
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *subTitleTextField;
	IBOutlet NSTextField *xAxisTextField;
	IBOutlet NSTextField *yAxisTextField;
	
    // Template
    IBOutlet NSPopUpButton *templatePullDownMenu;
    
    NSController *appController;
    IBOutlet NSObjectController *objectController;
    
    NSView *inspectedPlotView;
	NSDocument *inspectedDocument;
    IBOutlet  NSTabView *plotViewTabView;
    
    IBOutlet NSWindow *saveSheet, *deleteSheet;
} 

#pragma mark INITIALIZATION

+ (JKPanelController *) sharedController;

#pragma mark IBACTIONS

-(IBAction)showInspector:(id)sender;

#pragma mark ACCESSORS

-(NSDocument *)inspectedDocument;
-(void)setInspectedDocument:(NSDocument *)document;
idAccessor_h(inspectedPlotView, setInspectedPlotView);

#pragma mark MENU VALIDATION

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end
