//
//  PKWindowController.h
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKWindowController : NSWindowController {
	IBOutlet NSTabView *documentTabView;
    IBOutlet NSTableView *documentTableView;
}
- (void)setupToolbar;
@property (retain) NSTableView *documentTableView;
@property (retain) NSTabView *documentTabView;
@end
