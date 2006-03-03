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
    IBOutlet  NSTabView *plotViewTabView;
    
    IBOutlet NSWindow *saveSheet, *deleteSheet;
} 
+ (JKPanelController *) sharedController;

-(void)setupInspector:(id)object;
-(void)disableInspector:(id)object;
-(void)plotViewDidBecomeFirstResponderNotification:(NSNotification *)aNotification;
-(void)plotViewDidResignFirstResponderNotification:(NSNotification *)aNotification;
-(void)windowDidResignMain:(NSNotification *)aNotification;
-(void)windowDidBecomeMain:(NSNotification *)aNotification;

-(IBAction)showInspector:(id)sender;

// Template
//-(void)templatePullDownMenuAction:(id)sender;
//-(IBAction)addTemplate:(id)sender;
//-(IBAction)removeTemplate:(id)sender;
//-(void)showSaveSheet: (NSWindow *)window;
//-(void)showDeleteSheet: (NSWindow *)window;
//
//-(int)numberOfRowsInTableView:(NSTableView *)tableView;
//-(id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)row;

idAccessor_h(inspectedPlotView, setInspectedPlotView)

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;
@end
