//
//  JKGCMSPrintView.h
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
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
