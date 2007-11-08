//
//  JKRatiosController.h
//  Peacock
//
//  Created by Johan Kool on 10/11/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGCMSDocument;

@interface JKRatiosController : NSWindowController {
    IBOutlet NSTableView *tableView;
    IBOutlet NSArrayController *ratiosController;
}

- (void)addTableColumForDocument:(JKGCMSDocument *)document;

@property (retain) NSTableView *tableView;
@property (retain) NSArrayController *ratiosController;
@end
