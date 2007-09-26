//
//  JKGCMSPrintView.h
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGCMSDocument;

@interface JKGCMSPrintView : NSView {
    JKGCMSDocument *document;
    NSImage* chromImage;
    NSImage* spectrumImage;
    NSAttributedString *peakTable;
}

#pragma mark Initialization & deallocation
- (id)initWithDocument:(JKGCMSDocument *)aDocument;
#pragma mark -

#pragma mark Printing
- (void)preparePDFRepresentations;
- (NSRect)rectForChromatogram;
- (NSRect)rectForSpectrum;
- (NSRect)rectForPeakTable:(int)page;
- (int)pagesForPeakTable;
@property (retain) NSImage* spectrumImage;
@property (retain) NSAttributedString *peakTable;
@property (retain) JKGCMSDocument *document;
@property (retain) NSImage* chromImage;
@end
