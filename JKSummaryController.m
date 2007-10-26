//
//  JKSummaryController.m
//  Peacock
//
//  Created by Johan Kool on 01-10-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKSummaryController.h"

#import "JKAppDelegate.h"
#import "JKChromatogram.h"
#import "JKCombinedPeak.h"
#import "JKGCMSDocument.h"
#import "JKMainWindowController.h"
#import "JKSummarizer.h"
#import "JKPeakRecord.h"
#import "PKDocumentController.h"

@implementation JKSummaryController
- (id)init {
    self = [super initWithWindowNibName:@"JKSummary"];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
        indexOfKeyForValue = 0;
        indexOfSortKey = 0;
        sortDirection = YES;
        keys = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"topTime", @"key", NSLocalizedString(@"Top Time", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            						     [NSDictionary dictionaryWithObjectsAndKeys:@"surface", @"key", NSLocalizedString(@"Surface", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"retentionIndex", @"key", NSLocalizedString(@"Retention Index", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"model", @"key", NSLocalizedString(@"Model", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"height", @"key", NSLocalizedString(@"Height", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"score", @"key", NSLocalizedString(@"Score", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"symbol", @"key", NSLocalizedString(@"Symbol", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"deltaRetentionIndex", @"key", NSLocalizedString(@"Delta Retention Index", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"top", @"key", NSLocalizedString(@"Top Scan", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"key", NSLocalizedString(@"Start Scan", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"end", @"key", NSLocalizedString(@"End Scan", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"width", @"key", NSLocalizedString(@"Width", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"library", @"key", NSLocalizedString(@"Library", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineLeft", @"key", NSLocalizedString(@"Baseline Left", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineRight", @"key", NSLocalizedString(@"Baseline Right", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"peakID", @"key", NSLocalizedString(@"Peak Number", @""), @"localized", [NSNumber numberWithInt:0], @"format", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"uuid", @"key", NSLocalizedString(@"Unique ID", @""), @"localized", [NSNumber numberWithInt:1], @"format", nil], 
            nil] retain];
        sortKeys = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"label", @"key", NSLocalizedString(@"Compound name", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageRetentionIndex", @"key", NSLocalizedString(@"Retention Index", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageSurface", @"key", NSLocalizedString(@"Surface", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"averageHeight", @"key", NSLocalizedString(@"Height", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"countOfPeaks", @"key", NSLocalizedString(@"Number of Peaks", @""), @"localized", nil], 
            nil] retain];
        
    }
    return self;
}

- (void)windowDidLoad
{
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleClickAction:)];
    [combinedPeaksController bind:@"contentArray" toObject:[(JKAppDelegate *)[NSApp delegate] summarizer] withKeyPath:@"combinedPeaks" options:nil];
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    id document = [aNotification object];
    JKLogDebug(@"Document loaded notification received for %@", [document description]);
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        if ([tableView columnWithIdentifier:document] == -1)
            [self addTableColumForDocument:document];
    }
}

- (void)documentUnloaded:(NSNotification *)aNotification
{
    id object = [aNotification object];
    [tableView removeTableColumn:[tableView tableColumnWithIdentifier:object]];
}

- (void)addTableColumForDocument:(JKGCMSDocument *)document
{
    // Setup bindings for Combined peaks
    NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
    [tableColumn setIdentifier:document];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.%@",[(JKGCMSDocument *)document uuid],[self keyForValue]];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    [tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
    [[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    NSNumberFormatter *formatter;
    switch ([self formatForValue]) {
    case 0:
        formatter = [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
        [formatter setPositiveFormat:@"#0.0"];
        [formatter setLocalizesFormat:YES]; 
        [[tableColumn dataCell] setFormatter:formatter];
        [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
        break;
    case 1:
    default:
        [[tableColumn dataCell] setFormatter:nil];
        [[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
         break;
    }
    [tableColumn setEditable:NO];
    [tableView addTableColumn:tableColumn];
    [tableColumn release];    
}

- (void)updateTableColumnBindings
{
    NSEnumerator *enumerator = [[tableView tableColumns] objectEnumerator];
    NSTableColumn *tableColumn;
    while ((tableColumn = [enumerator nextObject])) {
        if ([[tableColumn identifier] isKindOfClass:[JKGCMSDocument class]]) {
            NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.%@",[[tableColumn identifier] uuid],[self keyForValue]];
            [tableColumn bind:@"value" toObject:combinedPeaksController withKeyPath:keyPath options:nil];
            NSNumberFormatter *formatter;
            switch ([self formatForValue]) {
                case 0:
                    formatter = [[[NSNumberFormatter alloc] init] autorelease];
                    [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
                    [formatter setPositiveFormat:@"#0.0"];
                    [formatter setLocalizesFormat:YES]; 
                    [[tableColumn dataCell] setFormatter:formatter];
                    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
                    break;
                case 1:
                default:
                    [[tableColumn dataCell] setFormatter:nil];
                    [[tableColumn dataCell] setAlignment:NSLeftTextAlignment];
                    break;
            }
            
        }
    }
    
}

- (NSString *)keyForValue
{
    return [[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"key"];
}

- (int)formatForValue
{
    return [[[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"format"] intValue];
}

- (NSArray *)localizedKeysForValue
{
    return [keys valueForKey:@"localized"];
}

- (int)indexOfKeyForValue
{
    return indexOfKeyForValue;
}

- (void)setIndexOfKeyForValue:(int)index 
{
    indexOfKeyForValue = index;
    [self updateTableColumnBindings];
}

- (IBAction)doubleClickAction:(id)sender {
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
    } else if ([sender clickedRow] == -1) {
        // A column was double clicked
        // Bring forward the associated file
        JKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[PKDocumentController sharedDocumentController] showDocument:document];
    } else {
        // A cell was double clicked
        // Bring forwars associated file and
        // select associated peak
        JKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[PKDocumentController sharedDocumentController] showDocument:document];
        
        JKCombinedPeak *combinedPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]];
        JKPeakRecord *peak = [combinedPeak valueForKey:[document uuid]];
        NSArrayController *chromatogramsController = [[document mainWindowController] chromatogramsController];
        if (peak) {
            if (![[chromatogramsController selectedObjects] containsObject:[document chromatogramForModel:[peak model]]]) {
                if ([[chromatogramsController selectedObjects] count] > 1) {
                    [chromatogramsController addSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                } else {             
                    [chromatogramsController setSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                }
            }
            [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:peak]];
        } else {
            // Attempt to find the peak!
            [document addChromatogramForModel:[[combinedPeak libraryEntry] model]];
            JKChromatogram *chromatogram = [document chromatogramForModel:[[combinedPeak libraryEntry] model]];
            [chromatogram identifyPeaksWithForce:YES];
            [chromatogramsController setSelectedObjects:[NSArray arrayWithObject:chromatogram]];
            // Find peak closest to averageRetentionTime
            float retTime = [[combinedPeak averageRetentionIndex] floatValue];
            float smallestDifference = fabsf([[[[chromatogram peaks] objectAtIndex:0] retentionIndex] floatValue] - retTime);
            unsigned int i, iout, count = [[chromatogram peaks] count];
            if (count > 0) {
                iout = 0;
                for (i = 0; i < count; i++) {
                      JKPeakRecord *peak = [[chromatogram peaks] objectAtIndex:i];
                      if (fabsf([[peak retentionIndex] floatValue] - retTime) < smallestDifference) {
                          smallestDifference = fabsf([[peak retentionIndex] floatValue] - retTime);
                          iout = i;
                      }
                }
                [(JKPeakRecord *)[[chromatogram peaks] objectAtIndex:iout] addSearchResultForLibraryEntry:[combinedPeak libraryEntry]];
                [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:[[chromatogram peaks] objectAtIndex:iout]]];
            } else {
                JKLogError(@"No peak found in chromatogram. Check baseline and peak detection settings.");
            }
        }
 	}
}

- (IBAction)sortArrangedObjects:(id)sender
{
    [combinedPeaksController setSortDescriptors:[NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:[self sortKey] ascending:[self sortDirection]] autorelease]]];
}


- (NSString *)sortKey
{
    return [[sortKeys objectAtIndex:indexOfSortKey] valueForKey:@"key"];
}

- (NSArray *)localizedSortKeys
{
    return [sortKeys valueForKey:@"localized"];
}

- (int)indexOfSortKey
{
    return indexOfSortKey;
}


- (BOOL)sortDirection {
    return sortDirection;
}

- (void)setIndexOfSortKey:(int)index 
{
    sortDirection = (index != indexOfSortKey);
    indexOfSortKey = index;
    [self sortArrangedObjects:self];
}

@end
