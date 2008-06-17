//
//  JKSummaryController.h
//  Peacock
//
//  Created by Johan Kool on 01-10-07.
//  Copyright 2007-2008 Johan Kool.
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

@class PKGCMSDocument;
@class PKSummarizer;
@class JKSynchroScrollView;

@interface PKSummaryController : NSWindowController {
    IBOutlet NSTableView *tableView;
 //   IBOutlet NSTableView *compoundTableView;
//    IBOutlet JKSynchroScrollView *tableScrollView;
//    IBOutlet JKSynchroScrollView *compoundScrollView;
    IBOutlet NSArrayController *combinedPeaksController;
    int indexOfKeyForValue;
    NSArray *keys;
    int indexOfSortKey;
    BOOL sortDirection;
    NSArray *sortKeys;
 }

- (void)addTableColumForDocument:(PKGCMSDocument *)document;
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
