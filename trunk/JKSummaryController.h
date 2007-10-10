//
//  JKSummaryController.h
//  Peacock
//
//  Created by Johan Kool on 01-10-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGCMSDocument;
@class JKSummarizer;

@interface JKSummaryController : NSWindowController {
    IBOutlet NSTableView *tableView;
    IBOutlet NSArrayController *combinedPeaksController;
    int indexOfKeyForValue;
    NSArray *keys;
 }

- (void)addTableColumForDocument:(JKGCMSDocument *)document;

@end
