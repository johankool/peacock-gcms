//
//  JKRatiosController.h
//  Peacock
//
//  Created by Johan Kool on 10/11/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKGCMSDocument;

@interface PKRatiosController : NSWindowController {
    IBOutlet NSTableView *tableView;
    IBOutlet NSArrayController *ratiosController;
}
- (IBAction)export:(id)sender;
- (IBAction)reset:(id)sender;

- (void)addTableColumForDocument:(PKGCMSDocument *)document;

@property (retain) NSTableView *tableView;
@property (retain) NSArrayController *ratiosController;
@end
