//
//  JKGCMSPrintView.m
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKGCMSPrintView.h"

#import "JKGCMSDocument.h"
#import "PKPeak.h"
#import "JKMainWindowController.h"

@implementation JKGCMSPrintView

#pragma mark Initialization & deallocation
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithDocument:(JKGCMSDocument *)aDocument 
{
    self = [self initWithFrame:NSMakeRect(0.0f,0.0f,1000000.0f,1000000.0f)];  
    if (self) {
        document = aDocument;
        chromImage = [[NSImage alloc] initWithSize:NSMakeSize(100.0f,100.0f)];
        spectrumImage = [[NSImage alloc] initWithSize:NSMakeSize(100.0f,100.0f)];
        peakTable = [[NSAttributedString alloc] init];        
    }
    return self;
}

- (void)dealloc
{
    [peakTable release];
    [chromImage release];
    [spectrumImage release];
    [super dealloc];
}
#pragma mark -

#pragma mark Printing
// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {
    NSObject *prefs = [[NSUserDefaultsController sharedUserDefaultsController] values];
    int numberOfPages = 0;
    
    // If we should print chromatogram
    if ([[prefs valueForKey:@"printChromatogram"] boolValue]) {
        numberOfPages++;        
    }
    
    // If we should print spectrum
    if ([[prefs valueForKey:@"printSpectrum"] boolValue]) {
        numberOfPages++;        
    }
    
    // If we should print peaktable
    if ([[prefs valueForKey:@"printPeakList"] boolValue]) {
        // Calculate pages needed
        numberOfPages += [self pagesForPeakTable];
    }

    range->location = 1;
    range->length = numberOfPages;
    JKLogDebug(@"knowsPageRange %d", numberOfPages);
    return YES;
}

// Return the drawing rectangle for a particular page number
- (NSRect)rectForPage:(int)page {
    NSDictionary *prefs = [[NSUserDefaultsController sharedUserDefaultsController] values];
    
    // If we should print chromatogram
    if ([[prefs valueForKey:@"printChromatogram"] boolValue]) {
        if (page == 1) {
            // Return rect for chromatogram
            return [self rectForChromatogram];
        }
    } else {
        page++;
    }
    
    // If we should print spectrum
    if ([[prefs valueForKey:@"printSpectrum"] boolValue]) {
        if (page == 2) {
            // Return rect for spectrum
            return [self rectForSpectrum];
        }
    } else {
        page++;
    }
    
    // If we should print peaktable
    if ([[prefs valueForKey:@"printPeakList"] boolValue]) {
        if (page >= 3) {
            // Return rect for peaktable
            return [self rectForPeakTable:page-3];
        }
    }
    
    return NSMakeRect(0,0,10,10);
}

// Calculate the vertical size of the view that fits on a single page
- (float)calculatePrintHeight {
    // Obtain the print info object for the current operation
    NSPrintInfo *pi = [document printInfo];
    
    // Calculate the page height in points
//    NSSize paperSize = [pi paperSize];
//    float pageHeight = paperSize.height - [pi topMargin] - [pi bottomMargin];
    NSRect imageablePageBounds = [pi imageablePageBounds];
    float pageHeight = imageablePageBounds.size.height;
    
    // Convert height to the scaled view 
    float scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor]
        floatValue];
//    NSLog(@"calculatePrintHeight %g",pageHeight / scale);
    return pageHeight * scale;
}

// Calculate the horizontal size of the view that fits on a single page
- (float)calculatePrintWidth {
    // Obtain the print info object for the current operation
    NSPrintInfo *pi = [document printInfo];
    
    // Calculate the page height in points
//    NSSize paperSize = [pi paperSize];
//    float pageWidth = paperSize.width - [pi leftMargin] - [pi rightMargin];
    NSRect imageablePageBounds = [pi imageablePageBounds];
    float pageWidth = imageablePageBounds.size.width;
    
    // Convert height to the scaled view 
    float scale = [[[pi dictionary] objectForKey:NSPrintScalingFactor]
        floatValue];
//    NSLog(@"calculatePrintWidth %g",pageWidth / scale);
    return pageWidth * scale;
}

- (NSRect)rectForChromatogram
{
    return NSMakeRect(0.0f,0.0f,[self calculatePrintWidth],[self calculatePrintHeight]);
}

- (NSRect)rectForSpectrum
{
    float height = [self calculatePrintHeight];
    return NSMakeRect(0.0f,height,[self calculatePrintWidth],height);
}
- (NSRect)rectForPeakTable:(int)page
{
    float height = [self calculatePrintHeight];
    return NSMakeRect(0.0f,height*(([self pagesForPeakTable]-page)+2),[self calculatePrintWidth],height);
}
- (int)pagesForPeakTable
{
    return ceil([peakTable boundingRectWithSize:NSMakeSize([self calculatePrintWidth],0.0f) options:NSStringDrawingUsesLineFragmentOrigin].size.height/[self calculatePrintHeight]);
//    return [peakTable size].height/[self calculatePrintHeight];
}
#pragma mark -

#pragma mark Drawing
- (void)preparePDFRepresentations
{
    // Only one NSPrintOperation can be active at one point, so we need to fetch the pdf before the print operation on the document starts

    // Drawing chromatogram
    NSView *chromView = [[document mainWindowController] chromatogramView];
    NSRect chromRect = [self rectForChromatogram];
    NSRect oldRect = [chromView frame];
    [chromView setFrame:chromRect];
    NSData *chromData = [chromView dataWithPDFInsideRect:[chromView frame]];
    NSPDFImageRep* pdfRep = [NSPDFImageRep imageRepWithData:chromData]; 
    
    // Create a new image to hold the PDF representation.
    NSRect chromBounds = [chromView bounds];
    [chromImage setSize:chromBounds.size];
    [chromImage addRepresentation:pdfRep]; 
    
    // Set the oldRect back
    [chromView setFrame:oldRect];
    
    // Drawing spectrum
    NSView *spectrumView = [[document mainWindowController] spectrumView];
    NSRect spectrumRect = [self rectForSpectrum];
    spectrumRect.origin.y = 0.0f;
    oldRect = [spectrumView frame];
    [spectrumView setFrame:spectrumRect];
    NSData *spectrumData = [spectrumView dataWithPDFInsideRect:[spectrumView frame]];
    pdfRep = [NSPDFImageRep imageRepWithData:spectrumData]; 
    
    // Create a new image to hold the PDF representation.
    NSRect spectrumBounds = [spectrumView bounds];
    [spectrumImage setSize:spectrumBounds.size];
    [spectrumImage addRepresentation:pdfRep]; 
   
    // Set the oldRect back
    [spectrumView setFrame:oldRect];    
    
    // Collecting the peak table only once makes sense too...
    NSEnumerator *peakEnum = [[document peaks] objectEnumerator];
    PKPeak *peak;
    NSMutableString *string = [NSMutableString string];
    [string setString:@"<table>"];
    [string appendFormat:@"<caption>Peak List for document \"%@\"</caption>", [document displayName]];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<thead>"];
    [string appendString:@"<tr>"];
    [string appendString:@"<th>ID</th>"];
    [string appendString:@"<th>Label</th>"];
    [string appendString:@"<th>Score</th>"];
    [string appendString:@"<th>Model</th>"];
    [string appendString:@"<th>Identified</th>"];
    [string appendString:@"<th>Confirmed</th>"];
    [string appendString:@"</tr>"];
    [string appendString:@"</thead><tbody>"];
    
    while ((peak = [peakEnum nextObject]) != nil) {
        [string appendString:@"<tr>"];
        [string appendFormat:@"<td align=\"right\">%d.</td>", [peak peakID]];
        [string appendFormat:@"<td>%@</td>", [peak label]];
        [string appendFormat:@"<td align=\"right\">%@</td>", [peak score]];
        [string appendFormat:@"<td align=\"center\">%@</td>", [peak model]];
        [string appendFormat:@"<td align=\"center\">%d</td>", [peak identified]];
        [string appendFormat:@"<td align=\"center\">%d</td>", [peak confirmed]];
        [string appendString:@"</tr>"];
    }
    [string appendString:@"</tbody></table>"];
    peakTable = [[NSAttributedString alloc] initWithHTML:[string dataUsingEncoding:NSUTF8StringEncoding] documentAttributes:nil];
  
    NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:peakTable];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    int i, pagecount = [self pagesForPeakTable];
    for (i=0; i < pagecount; i++) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] init];
        [textContainer setContainerSize:NSMakeSize([self calculatePrintWidth], [self calculatePrintHeight])];
        [textContainer setLineFragmentPadding:0.0f];
        [layoutManager addTextContainer:textContainer];
        NSTextView *textView = [[NSTextView alloc] initWithFrame:[self rectForPeakTable:i] textContainer:textContainer];
        [self addSubview:textView];
        [textContainer release];
        [textView release];
    }
    [textStorage addLayoutManager:layoutManager];
    [layoutManager release];
    
}

- (void)drawRect:(NSRect)rect {
    // Drawing chromatogram
    NSRect chromRect = [self rectForChromatogram];
    if (NSIntersectsRect(chromRect,rect)) 
        [chromImage drawInRect:chromRect fromRect:chromRect operation:NSCompositeSourceOver fraction:1.0f];
    
    // Drawing spectrum
    NSRect spectrumRect = [self rectForSpectrum];
    NSRect fromSpectrumRect = spectrumRect;
    fromSpectrumRect.origin.y = 0.0f;
    if (NSIntersectsRect(spectrumRect,rect)) 
        [spectrumImage drawInRect:spectrumRect fromRect:fromSpectrumRect operation:NSCompositeSourceOver fraction:1.0f];
    
//    // Draw peaktable!
//    float height = [self calculatePrintHeight];
//    float difTableHeight = [peakTable boundingRectWithSize:NSMakeSize([self calculatePrintWidth],0.0f) options:NSStringDrawingUsesLineFragmentOrigin].size.height;
//    while (difTableHeight > height) {
//        difTableHeight = difTableHeight - height;
//    }
//    [peakTable drawWithRect:NSMakeRect(0.0f,height*3+(height-difTableHeight),[self calculatePrintWidth],0.0f)  options:NSStringDrawingUsesLineFragmentOrigin];
}
#pragma mark -

#pragma mark NSView settings
- (BOOL)isFlipped
{
    return NO;
}
@synthesize peakTable;
@synthesize chromImage;
@synthesize document;
@synthesize spectrumImage;
@end
