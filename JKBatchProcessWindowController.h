//
//  JKBatchProcessWindowController.h
//  Peacock
//
//  Created by Johan Kool on 14-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKBatchProcessWindowController : NSWindowController {
	NSMutableArray *files;
	BOOL abortAction;
	
	// Batch window
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *searchOptionsButton;
	IBOutlet NSButton *runBatchButton;
	IBOutlet NSTableView *filesTableView;
	
	// Search Options sheet
	IBOutlet NSWindow *searchOptionsSheet;
	IBOutlet NSButton *doneButton;
	
	// Progress sheet
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *fileProgressIndicator;
	IBOutlet NSButton *stopButton;
	IBOutlet NSTextField *fileStatusTextField;
	IBOutlet NSTextField *detailStatusTextField;
}

#pragma mark IBACTIONS
-(IBAction)addButtonAction:(id)sender;
-(IBAction)searchOptionsButtonAction:(id)sender;
-(IBAction)runBatchButtonAction:(id)sender;
-(IBAction)searchOptionsDoneAction:(id)sender;
-(IBAction)stopButtonAction:(id)sender;

#pragma mark ACCESSORS
idAccessor_h(files, setFiles);
boolAccessor_h(abortAction, setAbortAction);
@end
