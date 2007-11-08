//
//  JKStatisticsPrintView.h
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKStatisticsDocument;

@interface JKStatisticsPrintView : NSView {
    JKStatisticsDocument *document;
    NSImage* chromImage;
    NSImage* loadingsImage;
    NSImage* scoresImage;
    NSAttributedString *peakTable;
}

#pragma mark Initialization & deallocation
- (id)initWithDocument:(JKStatisticsDocument *)aDocument;
#pragma mark -

#pragma mark Printing
- (void)preparePDFRepresentations;
- (NSRect)rectForChromatogram;
- (NSRect)rectForLoadings;
- (NSRect)rectForScores;
- (NSRect)rectForPeakTable:(int)page;
- (int)pagesForPeakTable;
@property (retain) JKStatisticsDocument *document;
@property (retain) NSImage* chromImage;
@property (retain) NSImage* loadingsImage;
@property (retain) NSAttributedString *peakTable;
@property (retain) NSImage* scoresImage;
@end
