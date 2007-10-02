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
    }
    return self;
}

- (void)windowDidLoad
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
    
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    NSEnumerator *enumerator = [documents objectEnumerator];
    NSDocument *document;
    
    while ((document = [enumerator nextObject])) {
        if ([document isKindOfClass:[JKGCMSDocument class]]) {
            [self addTableColumForDocument:(JKGCMSDocument *)document];
        }
    }
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    id document = [aNotification object];
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        [self addTableColumForDocument:document];
    }
}

- (void)documentUnloaded:(NSNotification *)aNotification
{
    id object = [aNotification object];
    [tableView removeTableColumn:[tableView tableColumnWithIdentifier:(JKGCMSDocument *)[object uuid]]];
}

- (void)addTableColumForDocument:(JKGCMSDocument *)document
{
    // Setup bindings for Combined peaks
    NSTableColumn *tableColumn = [[NSTableColumn alloc] init];
    [tableColumn setIdentifier:(JKGCMSDocument *)[document uuid]];
    [[tableColumn headerCell] setStringValue:[document displayName]];
    NSString *keyPath = [NSString stringWithFormat:@"arrangedObjects.%@.topTime",(JKGCMSDocument *)[document uuid]];
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

@end
