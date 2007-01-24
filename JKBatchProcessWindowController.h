//
//  JKBatchProcessWindowController.h
//  Peacock
//
//  Created by Johan Kool on 14-12-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKBatchProcessWindowController : NSWindowController {
	NSMutableArray *files;
	BOOL abortAction;
	
	// Batch window
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *runBatchButton;
	IBOutlet NSTableView *filesTableView;
		
	// Progress sheet
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *fileProgressIndicator;
	IBOutlet NSButton *stopButton;
	IBOutlet NSTextField *fileStatusTextField;
	IBOutlet NSTextField *detailStatusTextField;
}

#pragma mark IBACTIONS
- (IBAction)addButtonAction:(id)sender;
- (IBAction)runBatchButtonAction:(id)sender;
- (IBAction)stopButtonAction:(id)sender;

#pragma mark ACCESSORS
idAccessor_h(files, setFiles)
boolAccessor_h(abortAction, setAbortAction)
@end
