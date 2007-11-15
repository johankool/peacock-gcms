//
//  PKDocumentController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocumentController.h"
#import "JKGCMSDocument.h"
#import "JKSeparatorCell.h"
#import "JKImageTextCell.h"

@implementation PKDocumentController
- (id) init {
    self = [super init];
    if (self != nil) {
        managedDocuments = [[NSMutableArray alloc] init];
        separatorCell = [[JKSeparatorCell alloc] init];
        defaultCell = [[JKImageTextCell alloc] initTextCell:@"Default title"];
        
        libraryImage = [NSImage imageNamed:@"Library"];
        playlistImage = [NSImage imageNamed:@"Playlist"];
        
    }
    return self;
}

- (void)dealloc
{
    [managedDocuments release];
    [super dealloc];
}

- (void)addDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:document];
	    NSWindow *documentWindow = [[(JKGCMSDocument *)document mainWindowController] window];
        [newTabViewItem setView:[documentWindow contentView]];
        [newTabViewItem setLabel:[document displayName]];
        [documentTabView addTabViewItem:newTabViewItem];
        [documentTabView selectTabViewItemWithIdentifier:document];
        [managedDocuments addObject:document];
        [documentTableView reloadData];
        [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[managedDocuments indexOfObject:document]+[self numberOfSummaries]+1] byExtendingSelection:NO];
     }
    [super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        [managedDocuments removeObject:document];
        [documentTabView removeTabViewItem:[documentTabView tabViewItemAtIndex:[documentTabView indexOfTabViewItemWithIdentifier:document]]];
        [documentTableView reloadData];
    }
	[super removeDocument:document];
}

- (void)showDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[JKGCMSDocument class]]) {
        [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[managedDocuments indexOfObject:document]+[self numberOfSummaries]+1] byExtendingSelection:NO];
    }    
}

- (int)numberOfSummaries
{
    return 2;
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [managedDocuments count] + [self numberOfSummaries] + 1;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
    if ([[aTableColumn identifier] isEqualToString:@"name"]) {
        if (rowIndex < [self numberOfSummaries]+1) {
            switch (rowIndex) {
            case 0:
                return @"Summary";
                break;
            case 1:
                return @"Ratios";
                break;
            case 2:
                return @"";
                break;
            default:
                break;
            }
        }
        return [[managedDocuments objectAtIndex:rowIndex-[self numberOfSummaries]-1] displayName];
    } else  {
        if (rowIndex < [self numberOfSummaries]+1) {
            return @"";
        }
        return [[[managedDocuments objectAtIndex:rowIndex-[self numberOfSummaries]-1] metadata] valueForKey:[aTableColumn identifier]];        
    }
}

- (NSString *)tableView:(NSTableView *)aTableView toolTipForCell:(NSCell *)aCell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)aTableColumn row:(int)row mouseLocation:(NSPoint)mouseLocation
{
    if (row < [self numberOfSummaries]+1) {
        switch (row) {
            case 0:
                return @"Overview of all peaks in the open documents in tabular format.";
                break;
            case 1:
                return @"Overview of ratios.";
                break;
            default:
                break;
        }
    }
    return [[managedDocuments objectAtIndex:row-[self numberOfSummaries]-1] fileName];  
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:window];
    if ([documentTableView numberOfSelectedRows] > 1) {
        [documentTabView selectTabViewItemWithIdentifier:@"multiple"];
    } else if ([documentTableView selectedRow] < [self numberOfSummaries]) {
        switch ([documentTableView selectedRow]) {
            case 0:
                [documentTabView selectTabViewItemWithIdentifier:@"summary"];
                break;
            case 1:
                [documentTabView selectTabViewItemWithIdentifier:@"ratios"];
                break;
            default:
                break;
        }     
    } else {
        [documentTabView selectTabViewItemWithIdentifier:[managedDocuments objectAtIndex:[documentTableView selectedRow]-[self numberOfSummaries]-1]];     
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeMainNotification object:window];
    }
}

- (void) awakeFromNib {
	// don't forget this super call
//    [super awakeFromNib]; // causes crash??!
	separatorCell = [[JKSeparatorCell alloc] init];
	defaultCell = [[JKImageTextCell alloc] initTextCell:@"Default title"];
	
	libraryImage = [NSImage imageNamed:@"table"];
	playlistImage = [NSImage imageNamed:@"peacock_document"];

}

- (float) heightFor:(NSTableView *)tableView row:(int)row {
	if (row == [self numberOfSummaries]) { // separator
		return JK_SEPARATOR_CELL_HEIGHT;
	}
	
	return [tableView rowHeight];
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(int)row {
	return row != [self numberOfSummaries];
}

- (id) tableColumn:(NSTableColumn *)column inTableView:(NSTableView *)tableView dataCellForRow:(int)row {
	if (row < [self numberOfSummaries]) {
		[defaultCell setImage:libraryImage];
	} else {
		[defaultCell setImage:playlistImage];
	}
	
	if (row == [self numberOfSummaries]) { // separator
		return separatorCell;
	}
	
	return defaultCell;
}

- (NSWindow *)window
{
    return window;
}

- (NSArray *)managedDocuments
{
    return managedDocuments;
}


-(IBAction)performClose:(id)sender
{
    if (![[self window] isMainWindow]) {
    	[[NSApp mainWindow] performSelector:@selector(performClose:) withObject:self];
    } else {
        if ([documentTableView selectedRow] > [self numberOfSummaries]) {
            JKGCMSDocument *doc = [[documentTabView selectedTabViewItem] identifier];
            [doc canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:nil];
         } else {
             [NSApp terminate:self];
         }
    }
}

- (void)document:(JKGCMSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
    if (shouldClose) {
        [documentTableView selectRow:0 byExtendingSelection:NO];
        [managedDocuments removeObject:doc];
        [documentTableView reloadData];
        NSWindow *tempWindow = [[NSWindow alloc] init];
        [[doc mainWindowController] setWindow:tempWindow];
        [[doc mainWindowController] setShouldCloseDocument:YES];
        [tempWindow close];
        [tempWindow release];
    }
}

@synthesize libraryImage;
@synthesize playlistImage;
@synthesize window;
@synthesize separatorCell;
@synthesize documentTableView;
@synthesize defaultCell;
@synthesize documentTabView;
@end
