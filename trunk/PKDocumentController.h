//
//  PKDocumentController.h
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKDocumentController : NSDocumentController {
    IBOutlet NSWindow *window;
	IBOutlet NSTabView *documentTabView;
    IBOutlet NSOutlineView *documentTableView;
    NSMutableArray *managedDocuments;
    NSArray *_specials;
}

- (NSWindow *)window;
- (NSArray *)managedDocuments;
- (void)showDocument:(NSDocument *)document;

- (IBAction)showSummary:(id)sender;
- (IBAction)showRatios:(id)sender;
- (IBAction)showGraphical:(id)sender;

@property (retain) NSTabView *documentTabView;
@property (retain,getter=window) NSWindow *window;
@property (retain) NSTableView *documentTableView;
@end
