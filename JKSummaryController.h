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
    int indexOfSortKey;
    BOOL sortDirection;
    NSArray *sortKeys;
 }

- (void)addTableColumForDocument:(JKGCMSDocument *)document;
- (NSString *)keyForValue;
- (int)formatForValue;
- (BOOL)sortDirection;
- (NSString *)sortKey;
- (IBAction)export:(id)sender;

@property (getter=indexOfKeyForValue,setter=setIndexOfKeyForValue:) int indexOfKeyForValue;
@property (retain) NSArray *sortKeys;
@property (retain) NSTableView *tableView;
@property (getter=sortDirection) BOOL sortDirection;
@property (retain) NSArrayController *combinedPeaksController;
@property (retain) NSArray *keys;
@end
