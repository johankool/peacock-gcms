//
//  JKGCMSPrintView.h
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKGCMSDocument;

@interface PKGCMSPrintView : NSView {
    PKGCMSDocument *document;
    NSImage* chromImage;
    NSImage* spectrumImage;
    NSAttributedString *peakTable;
}

#pragma mark Initialization & deallocation
- (id)initWithDocument:(PKGCMSDocument *)aDocument;
#pragma mark -

#pragma mark Printing
- (void)preparePDFRepresentations;
- (NSRect)rectForChromatogram;
- (NSRect)rectForSpectrum;
- (NSRect)rectForPeakTable:(int)page;
- (int)pagesForPeakTable;
@property (retain) NSAttributedString *peakTable;
@property (retain) PKGCMSDocument *document;
@property (retain) NSImage* chromImage;
@property (retain) NSImage* spectrumImage;
@end
