//
//  JKSummaryController.m
//  Peacock
//
//  Created by Johan Kool on 01-10-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKSummaryController.h"

#import "JKGCMSDocument.h"
#import "JKSummarizer.h"

@implementation JKSummaryController
- (id)init {
    self = [super initWithWindowNibName:@"JKSummary"];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
        indexOfKeyForValue = 0;
        keys = [[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"topTime", @"key", NSLocalizedString(@"Top Time", @""), @"localized", nil], 
            						     [NSDictionary dictionaryWithObjectsAndKeys:@"surface", @"key", NSLocalizedString(@"Surface", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"retentionIndex", @"key", NSLocalizedString(@"Retention Index", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"model", @"key", NSLocalizedString(@"Model", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"height", @"key", NSLocalizedString(@"Height", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"score", @"key", NSLocalizedString(@"Score", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"symbol", @"key", NSLocalizedString(@"Symbol", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"deltaRetentionIndex", @"key", NSLocalizedString(@"Delta Retention Index", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"top", @"key", NSLocalizedString(@"Top Scan", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"start", @"key", NSLocalizedString(@"Start Scan", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"end", @"key", NSLocalizedString(@"End Scan", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"width", @"key", NSLocalizedString(@"width", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"library", @"key", NSLocalizedString(@"Library", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineLeft", @"key", NSLocalizedString(@"baselineLeft", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"baselineRight", @"key", NSLocalizedString(@"baselineRight", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"peakID", @"key", NSLocalizedString(@"Peak Number", @""), @"localized", nil], 
            [NSDictionary dictionaryWithObjectsAndKeys:@"uuid", @"key", NSLocalizedString(@"uuid", @""), @"localized", nil], 
            nil] retain];
            
    }
    return self;
}

- (void)windowDidLoad
{
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleClickAction:)];
    [combinedPeaksController bind:@"contentArray" toObject:[[NSApp delegate] summarizer] withKeyPath:@"combinedPeaks" options:nil];
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    id document = [aNotification object];
    NSLog(@"Document loaded notification received for %@", [document description]);
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
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
    [formatter setPositiveFormat:@"#0.0"];
    [formatter setLocalizesFormat:YES];
    [[tableColumn dataCell] setFormatter:formatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
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
        }
    }
    
}

- (NSString *)keyForValue
{
    return [[keys objectAtIndex:indexOfKeyForValue] valueForKey:@"key"];
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
	NSError *error = [[[NSError alloc] init] autorelease];
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
    } else if ([sender clickedRow] == -1) {
        // A column was double clicked
        // Bring forward the associated file
        JKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[NSDocumentController sharedDocumentController] showDocument:document];
    } else {
        // A cell was double clicked
        // Bring forwars associated file and
        // select associated peak
        JKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[NSDocumentController sharedDocumentController] showDocument:document];
        
        JKCombinedPeak *combinedPeak = [[combinedPeaksController arrangedObjects] objectAtIndex:[sender clickedRow]];
        JKPeakRecord *peak = [combinedPeak valueForKey:[document uuid]];
        if (peak) {
            if (![[[[document mainWindowController] chromatogramsController] selectedObjects] containsObject:[document chromatogramForModel:[peak model]]]) {
                if ([[[[document mainWindowController] chromatogramsController] selectedObjects] count] > 1) {
                    [[[document mainWindowController] chromatogramsController] addSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                } else {             
                    [[[document mainWindowController] chromatogramsController] setSelectedObjects:[NSArray arrayWithObject:[document chromatogramForModel:[peak model]]]];
                }
            }
            [[[document mainWindowController] peakController] setSelectedObjects:[NSArray arrayWithObject:peak]];
        } else {
            [[[document mainWindowController] peakController] setSelectedObjects:nil];
            NSBeep();
        }
 	}
}

@end
