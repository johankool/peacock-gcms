//
//  JKStatisticsPrintView.m
//  Peacock
//
//  Created by Johan Kool on 29-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKStatisticsPrintView.h"

#import "JKStatisticsDocument.h"
#import "JKCombinedPeak.h"
#import "JKStatisticsWindowController.h"

@implementation JKStatisticsPrintView

#pragma mark Initialization & deallocation
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (id)initWithDocument:(JKStatisticsDocument *)aDocument 
{
    self = [self initWithFrame:NSMakeRect(0.0f,0.0f,1000000.0f,1000000.0f)];  
    if (self) {
        document = aDocument;
        chromImage = [[NSImage alloc] initWithSize:NSMakeSize(100.0f,100.0f)];
        loadingsImage = [[NSImage alloc] initWithSize:NSMakeSize(100.0f,100.0f)];
        scoresImage = [[NSImage alloc] initWithSize:NSMakeSize(100.0f,100.0f)];
        peakTable = [[NSAttributedString alloc] init];        
    }
    return self;
}

- (void)dealloc
{
    [peakTable release];
    [chromImage release];
    [loadingsImage release];
    [scoresImage release];
    [super dealloc];
}
#pragma mark -

#pragma mark Printing
// Return the number of pages available for printing
- (BOOL)knowsPageRange:(NSRangePointer)range {
    NSObject *prefs = [[NSUserDefaultsController sharedUserDefaultsController] values];
    int numberOfPages = 0;
    
    // If we should print chromatogram
    if ([[prefs valueForKey:@"printStatisticsChromatogram"] boolValue]) {
        numberOfPages++;        
    }
    
    // If we should print spectrum
    if ([[prefs valueForKey:@"printStatisticsLoadings"] boolValue]) {
        numberOfPages++;        
    }

    // If we should print spectrum
    if ([[prefs valueForKey:@"printStatisticsScores"] boolValue]) {
        numberOfPages++;        
    }
    
    // If we should print peaktable
    if ([[prefs valueForKey:@"printStatisticsPeakTable"] boolValue]) {
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
    if ([[prefs valueForKey:@"printStatisticsChromatogram"] boolValue]) {
        if (page == 1) {
            // Return rect for chromatogram
            return [self rectForChromatogram];
        }
    } else {
        page++;
    }
    
    // If we should print spectrum
    if ([[prefs valueForKey:@"printStatisticsLoadings"] boolValue]) {
        if (page == 2) {
            // Return rect for spectrum
            return [self rectForLoadings];
        }
    } else {
        page++;
    }
    
    // If we should print spectrum
    if ([[prefs valueForKey:@"printStatisticsScores"] boolValue]) {
        if (page == 3) {
            // Return rect for spectrum
            return [self rectForScores];
        }
    } else {
        page++;
    }
    
    // If we should print peaktable
    if ([[prefs valueForKey:@"printStatisticsPeakTable"] boolValue]) {
        if (page >= 4) {
            // Return rect for peaktable
            return [self rectForPeakTable:page-4];
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

- (NSRect)rectForLoadings
{
    float height = [self calculatePrintHeight];
    return NSMakeRect(0.0f,height,[self calculatePrintWidth],height);
}
- (NSRect)rectForScores
{
    float height = [self calculatePrintHeight];
    return NSMakeRect(0.0f,height*2,[self calculatePrintWidth],height);
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
/*###197 [cc] warning: initialization from distinct Objective-C type%%%*/
/*###197 [cc] warning: initialization from distinct Objective-C type%%%*/
    NSView *chromView = [[document statisticsWindowController] altGraphView];
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
    
    // Drawing loadings
/*###213 [cc] warning: initialization from distinct Objective-C type%%%*/
/*###213 [cc] warning: initialization from distinct Objective-C type%%%*/
    NSView *loadingsView = [[document statisticsWindowController] loadingsGraphView];
    NSRect loadingsRect = [self rectForLoadings];
    loadingsRect.origin.y = 0.0f;
    oldRect = [loadingsView frame];
    [loadingsView setFrame:loadingsRect];
    NSData *loadingsData = [loadingsView dataWithPDFInsideRect:[loadingsView frame]];
    pdfRep = [NSPDFImageRep imageRepWithData:loadingsData]; 
    
    // Create a new image to hold the PDF representation.
    NSRect loadingsBounds = [loadingsView bounds];
    [loadingsImage setSize:loadingsBounds.size];
    [loadingsImage addRepresentation:pdfRep]; 
   
    // Set the oldRect back
    [loadingsView setFrame:oldRect];    

    // Drawing scores
/*###230 [cc] warning: initialization from distinct Objective-C type%%%*/
/*###230 [cc] warning: initialization from distinct Objective-C type%%%*/
    NSView *scoresView = [[document statisticsWindowController] scoresGraphView];
    NSRect scoresRect = [self rectForScores];
    scoresRect.origin.y = 0.0f;
    oldRect = [scoresView frame];
    [scoresView setFrame:scoresRect];
    NSData *scoresData = [scoresView dataWithPDFInsideRect:[scoresView frame]];
    pdfRep = [NSPDFImageRep imageRepWithData:scoresData]; 
    
    // Create a new image to hold the PDF representation.
    NSRect scoresBounds = [scoresView bounds];
    [scoresImage setSize:scoresBounds.size];
    [scoresImage addRepresentation:pdfRep]; 
    
    // Set the oldRect back
    [scoresView setFrame:oldRect];    
    
    // Collecting the peak table only once makes sense too...
    NSEnumerator *peakEnum = [[[document statisticsWindowController] combinedPeaks] objectEnumerator];
    JKCombinedPeak *peak;
    NSMutableString *string = [NSMutableString string];
    [string setString:@"<table>"];
    [string appendFormat:@"<caption>Combined Peak List for \"%@\"</caption>", [document displayName]];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
    [string appendString:@"<col />"];
//    [string appendString:@"<col />"];
//    [string appendString:@"<col />"];
//    [string appendString:@"<col />"];
    [string appendString:@"<thead>"];
    [string appendString:@"<tr>"];
    [string appendString:@"<th>ID</th>"];
    [string appendString:@"<th>Label</th>"];
//    [string appendString:@"<th>Score</th>"];
    [string appendString:@"<th>Model</th>"];
//    [string appendString:@"<th>Identified</th>"];
//    [string appendString:@"<th>Confirmed</th>"];
    [string appendString:@"</tr>"];
    [string appendString:@"</thead><tbody>"];
    
    while ((peak = [peakEnum nextObject]) != nil) {
        [string appendString:@"<tr>"];
        [string appendFormat:@"<td align=\"left\">%d.</td>", [peak symbol]];
        [string appendFormat:@"<td>%@</td>", [peak label]];
//        [string appendFormat:@"<td align=\"right\">%@</td>", [peak score]];
        [string appendFormat:@"<td align=\"center\">%@</td>", [peak model]];
//        [string appendFormat:@"<td align=\"center\">%d</td>", [peak identified]];
//        [string appendFormat:@"<td align=\"center\">%d</td>", [peak confirmed]];
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
    
    // Drawing loadings
    NSRect loadingsRect = [self rectForLoadings];
    NSRect fromLoadingsRect = loadingsRect;
    fromLoadingsRect.origin.y = 0.0f;
    if (NSIntersectsRect(loadingsRect,rect)) 
        [loadingsImage drawInRect:loadingsRect fromRect:fromLoadingsRect operation:NSCompositeSourceOver fraction:1.0f];

    // Drawing scores
    NSRect scoresRect = [self rectForScores];
    NSRect fromScoresRect = scoresRect;
    fromScoresRect.origin.y = 0.0f;
    if (NSIntersectsRect(scoresRect,rect)) 
        [scoresImage drawInRect:scoresRect fromRect:fromScoresRect operation:NSCompositeSourceOver fraction:1.0f];
    
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
@end
