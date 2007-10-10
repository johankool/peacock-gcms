//
//  PKDocumentController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocumentController.h"
#import "JKGCMSDocument.h"

@implementation PKDocumentController
- (id) init {
    self = [super init];
    if (self != nil) {
        JKLogDebug(@"init");
        managedDocuments = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [managedDocuments release];
}

- (void)addDocument:(NSDocument *)document
{
    NSLog(@"Document added %@", [document description]);
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:document];
        NSWindow *documentWindow = [[(JKGCMSDocument *)document mainWindowController] window];
        [newTabViewItem setView:[documentWindow contentView]];
        [newTabViewItem setLabel:[document displayName]];
        [documentTabView addTabViewItem:newTabViewItem];
        [documentTabView selectTabViewItemWithIdentifier:document];
        [managedDocuments addObject:document];
        [documentTableView reloadData];
     }
    [super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document
{
    NSLog(@"Document removed %@", [document description]);
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        [managedDocuments removeObject:document];
        [documentTabView removeTabViewItem:[documentTabView tabViewItemAtIndex:[documentTabView indexOfTabViewItemWithIdentifier:document]]];
        [documentTableView reloadData];
    }
	[super removeDocument:document];
}


- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [managedDocuments count]+1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if (rowIndex == 0)
        return @"Summary";
    return [[managedDocuments objectAtIndex:rowIndex-1] displayName];
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    if (row == 0)
        return @"Overview of all peaks in the open documents in tabular format. ";
    return [[managedDocuments objectAtIndex:row-1] fileName];  
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if ([documentTableView selectedRow] == 0) {
        [documentTabView selectTabViewItemWithIdentifier:@"Summary"];
    } else {
        [documentTabView selectTabViewItemWithIdentifier:[managedDocuments objectAtIndex:[documentTableView selectedRow]-1]];        
    }
}
@end
