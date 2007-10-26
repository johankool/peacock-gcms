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
    IBOutlet NSTableView *documentTableView;
    NSMutableArray *managedDocuments;
    
    NSCell *separatorCell;
	NSCell *defaultCell;
	
	NSImage *libraryImage;
	NSImage *playlistImage;
    
}
- (int)numberOfSummaries;
- (NSWindow *)window;
- (NSArray *)managedDocuments;
- (void)showDocument:(NSDocument *)document;
@end
