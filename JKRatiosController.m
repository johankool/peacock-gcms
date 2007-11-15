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
#import "JKRatio.h"

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

- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
    if ([typeName isEqualToString:@"public.text"]) {
        NSMutableString *outString = [[NSMutableString alloc] init];
        JKGCMSDocument* document;
        
        // File name
        [outString appendString:@"Filename"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document displayName]];
        }
        [outString appendString:@"\n"];
        
        // Sample code
        [outString appendString:@"Code"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document sampleCode]];
        }
        [outString appendString:@"\n"];
        
        // Sample description
        [outString appendString:@"Description"];
        for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
            [outString appendFormat:@"\t%@", [document sampleDescription]];
        }
        [outString appendString:@"\n"];
        
        // Values
        JKRatio *ratio;
        NSString *format = @"\t%@";
        for (ratio in [ratiosController arrangedObjects]) {
            [outString appendFormat:@"%@", [ratio name]];
            for (document in [[PKDocumentController sharedDocumentController] managedDocuments]) {
                [outString appendFormat:format, [ratio valueForKey:[document uuid]]];
            }
            [outString appendString:@"\n"];
        }
        
        return [outString writeToURL:absoluteURL atomically:YES encoding:NSUTF8StringEncoding error:outError];
    }
    
    if (outError != NULL)
        *outError = [[[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                code:NSFileWriteUnknownError userInfo:nil] autorelease];
    
    return NO;
}

- (IBAction)export:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:NSLocalizedString(@"Choose a location for exporting the current ratios.", @"")];
    NSArray *docs = [[PKDocumentController sharedDocumentController] managedDocuments];
    NSString *fileName;
    NSString *firstDoc;
    NSString *lastDoc;
    if ([docs count] == 0) {
        NSBeep();
        return;
    } else if ([docs count] == 1) {
        firstDoc = [[docs objectAtIndex:0] displayName];
        
        fileName = [NSString stringWithFormat:NSLocalizedString(@"Exported Ratios for %@.txt", @""), firstDoc];        
    } else {
        firstDoc = [[docs objectAtIndex:0] displayName];
        lastDoc = [[docs lastObject] displayName];
        
        fileName = [NSString stringWithFormat:NSLocalizedString(@"Exported Ratios for %@ to %@.txt", @""), firstDoc, lastDoc];
    }
    
    [sp beginSheetForDirectory:nil file:fileName modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)savePanelDidEnd:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if (returnCode == NSOKButton) {
        NSError *error = [[[NSError alloc] init] autorelease];
        if (![self writeToURL:[sheet URL] ofType:@"public.text" error:&error]) {
            [self presentError:error];
        }
    }
}

- (IBAction)reset:(id)sender {
   [[(JKAppDelegate *)[NSApp delegate] summarizer] setupRatios];
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

@synthesize tableView;
@synthesize ratiosController;
@end
