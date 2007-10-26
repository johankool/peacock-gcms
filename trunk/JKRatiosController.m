//
//  JKRatiosController.m
//  Peacock
//
//  Created by Johan Kool on 10/11/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKRatiosController.h"

#import "JKAppDelegate.h"
#import "JKGCMSDocument.h"
#import "JKSummarizer.h"
#import "PKDocumentController.h"

@implementation JKRatiosController
- (id)init {
    self = [super initWithWindowNibName:@"JKRatios"];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
    }
    return self;
}

- (void)windowDidLoad
{
    [tableView setTarget:self];
    [tableView setDoubleAction:@selector(doubleClickAction:)];
    [ratiosController bind:@"contentArray" toObject:[(JKAppDelegate *)[NSApp delegate] summarizer] withKeyPath:@"ratios" options:nil];
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    id document = [aNotification object];
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
    NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@",[(JKGCMSDocument *)document uuid]];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    [tableColumn bind:@"value" toObject:ratiosController withKeyPath:keyPath options:nil];
    [[tableColumn dataCell] setFont:[NSFont systemFontOfSize:[NSFont systemFontSizeForControlSize:NSSmallControlSize]]];
    NSNumberFormatter *formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setFormatterBehavior:NSNumberFormatterDecimalStyle];
    [formatter setPositiveFormat:@"#0.00"];
    [formatter setNegativeFormat:@"-#0.00"];
    [formatter setLocalizesFormat:YES];
    [[tableColumn dataCell] setFormatter:formatter];
    [[tableColumn dataCell] setAlignment:NSRightTextAlignment];
    [tableColumn setEditable:NO];
    [tableView addTableColumn:tableColumn];
    [tableColumn release];    
}

- (IBAction)doubleClickAction:(id)sender {
	if (([sender clickedRow] == -1) && ([sender clickedColumn] == -1)) {
		return;
	} else if ([sender clickedColumn] == 0) {
		return;
    } else {
        // Bring forwars associated file 
        JKGCMSDocument *document = [[[tableView tableColumns] objectAtIndex:[sender clickedColumn]] identifier];
        [[PKDocumentController sharedDocumentController] showDocument:document];     
  	}
}

@end
