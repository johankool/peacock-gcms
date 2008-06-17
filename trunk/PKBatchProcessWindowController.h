//
//  JKBatchProcessWindowController.h
//  Peacock
//
//  Created by Johan Kool on 14-12-05.
//  Copyright 2005-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>


@interface PKBatchProcessWindowController : NSWindowController {
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
@property (retain) NSTextField *detailStatusTextField;
@property (retain) NSButton *runBatchButton;
@property (retain) NSButton *addButton;
@property (retain) NSTableView *filesTableView;
@property (getter=abortAction,setter=setAbortAction:) BOOL abortAction;
@property (retain) NSWindow *progressSheet;
@property (retain) NSProgressIndicator *fileProgressIndicator;
@property (retain) NSTextField *fileStatusTextField;
@property (retain) NSButton *stopButton;
@end
