//
//  PKDocumentController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocumentController.h"
#import "PKGCMSDocument.h"
#import "RBSplitView.h"

@implementation PKDocumentController
- (id) init {
    self = [super init];
    if (self != nil) {
        managedDocuments = [[NSMutableArray alloc] init];
        _specials = [[NSArray alloc] initWithObjects:@"Summary", @"Ratios", @"Graphical", nil];
   }
    return self;
}

- (void)awakeFromNib {
    [documentTableView expandItem:managedDocuments];
    [documentTableView expandItem:_specials];
    [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:[_specials objectAtIndex:0]]] byExtendingSelection:NO];
    
    // Drag and drop
	[documentTableView registerForDraggedTypes:[NSArray arrayWithObjects:@"PKDocumentEntryType", nil]];

}

- (void)dealloc
{
    [_specials release];
    [managedDocuments release];
    [super dealloc];
}

- (void)addDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[PKGCMSDocument class]]) {
        NSTabViewItem *newTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:document];
	    NSWindow *documentWindow = [[(PKGCMSDocument *)document mainWindowController] window];
        [newTabViewItem setView:[documentWindow contentView]];
        [newTabViewItem setLabel:[document displayName]];
        [documentTabView addTabViewItem:newTabViewItem];
        [documentTabView selectTabViewItemWithIdentifier:document];
        [managedDocuments addObject:document];
        [documentTableView reloadItem:managedDocuments reloadChildren:YES];
        [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:document]] byExtendingSelection:NO];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:@"JKGCMSDocument_DocumentActivateNotification" object:document];
     }
    [super addDocument:document];
}

- (void)removeDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[PKGCMSDocument class]]) {
        [managedDocuments removeObject:document];
        [documentTabView removeTabViewItem:[documentTabView tabViewItemAtIndex:[documentTabView indexOfTabViewItemWithIdentifier:document]]];
        [documentTableView reloadItem:managedDocuments reloadChildren:YES];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center postNotificationName:@"JKGCMSDocument_DocumentDeactivateNotification" object:document];
    }
	[super removeDocument:document];
}

- (void)showDocument:(NSDocument *)document
{
    if ([document isKindOfClass:[PKGCMSDocument class]]) {
        [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:document]] byExtendingSelection:NO];
    }    
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (!item) {
        return 2;
    }
    if (item == _specials) {
        return [_specials count];
    }
    
    if (item == managedDocuments) {
        return [managedDocuments count];
    }
    
    return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == _specials) {
        return YES;
    }
    
    if (item == managedDocuments) {
        return YES;
    }
    
    return NO;
}

//- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item {
//    if (item == _specials) {
//        return NO;
//    }
//        
//    return YES;    
//}
//
//- (void)outlineView:(NSOutlineView *)theOutlineView willDisplayOutlineCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item {
//     if (item == _specials) {
//        [cell setTransparent:YES];
//     } else {
//         [cell setTransparent:NO];
//     }
//} 

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    if (item == _specials) {
        return YES;
    }
    
    if (item == managedDocuments) {
        return YES;
    }

    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    if (item == _specials) {
        return NO;
    }
    
    if (item == managedDocuments) {
        return NO;
    }
    
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == _specials) {
        return [_specials objectAtIndex:index];
    }
    
    if (item == managedDocuments) {
        return [managedDocuments objectAtIndex:index];
    }
    
    if (!item) {
        if (index == 0) {
            return _specials;
        } else if (index == 1) {
            return managedDocuments;
        }
    }
    return nil;    
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:@"name"]) {
        if (item == _specials) {
            return NSLocalizedString(@"OVERVIEW", @"");
        }
        
        if (item == managedDocuments) {
            return NSLocalizedString(@"MEASUREMENTS", @"");
        }
        
        if ([item isKindOfClass:[NSString class]]) {
            return item;
        }
        
        if ([item isKindOfClass:[PKGCMSDocument class]]) {
            return [NSString stringWithFormat:@"%@ - %@ - %@", [item displayName], [item valueForKey:@"sampleCode"], [item valueForKey:@"sampleDescription"]];  
        }
        
        return @"";
    } else  {
        return @"";
    }
}

- (NSString *)outlineView:(NSOutlineView *)ov toolTipForCell:(NSCell *)cell rect:(NSRectPointer)rect tableColumn:(NSTableColumn *)tc item:(id)item mouseLocation:(NSPoint)mouseLocation {
    if (item == [_specials objectAtIndex:0]) {
         return NSLocalizedString(@"Overview of all peaks in the open documents in tabular format.", @"");
    }
    
    if (item == [_specials objectAtIndex:1]) {
         return NSLocalizedString(@"Overview of ratios.", @"");
    }
    
    if ([item isKindOfClass:[PKGCMSDocument class]]) {
        return [item fileName];  
    }
    
    return nil;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidResignMainNotification object:window];
    if ([documentTableView numberOfSelectedRows] > 1) {
        [documentTabView selectTabViewItemWithIdentifier:@"multiple"];
    } 
    id item = [documentTableView itemAtRow:[documentTableView selectedRow]];
    if ([item isKindOfClass:[NSString class]]) {
        [documentTabView selectTabViewItemWithIdentifier:[item lowercaseString]];
    } else if ([item isKindOfClass:[PKGCMSDocument class]]){
        [documentTabView selectTabViewItemWithIdentifier:item];     
        [[NSNotificationCenter defaultCenter] postNotificationName:NSWindowDidBecomeMainNotification object:window];
    }
}


- (BOOL)outlineView:(NSOutlineView *)outlineView writeItems:(NSArray *)items toPasteboard:(NSPasteboard *)pboard {
    if (outlineView == documentTableView) {
        if ([items count] < 1) {
            return NO;
        }
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        for (id item in items) {
            if (![[self managedDocuments] containsObject:item]) {
                return NO;
            } else {
                [indexes addIndex:[[self managedDocuments] indexOfObject:item]];
            }
        }
                
        // declare our own pasteboard types
        [pboard declareTypes:[NSArray arrayWithObject:@"PKDocumentEntryType"] owner:self];
        
        NSMutableData *data = [NSMutableData data];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:indexes forKey:@"PKDocumentEntryType"];
        [archiver finishEncoding];
        [archiver release];
        
        [pboard setData:data forType:@"PKDocumentEntryType"];
        
        return YES;
    }
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if (item == managedDocuments && index >= 0 && index < [managedDocuments count]) {
        return NSDragOperationMove;
    }
    return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
    if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:@"PKDocumentEntryType"]]) {
        NSData *data = [[info draggingPasteboard] dataForType:@"PKDocumentEntryType"];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSIndexSet *indexes = [unarchiver decodeObjectForKey:@"PKDocumentEntryType"];
        [unarchiver finishDecoding];
        [unarchiver release];
        
        NSArray *movedObjects = [managedDocuments objectsAtIndexes:indexes];
        [managedDocuments removeObjectsAtIndexes:indexes];
        
        for (id movedObject in movedObjects) {
            [managedDocuments insertObject:movedObject atIndex:index];
            index++;
        }
        
        id currentSelection = [outlineView itemAtRow:[outlineView selectedRow]];
        [outlineView reloadItem:managedDocuments reloadChildren:YES];
        [outlineView selectRow:[outlineView rowForItem:currentSelection] byExtendingSelection:NO];

        return YES;
    }
    return NO;
}

//- (NSRect)splitView:(RBSplitView*)sender cursorRect:(NSRect)rect forDivider:(unsigned int)divider {
//    JKLogEnteringMethod();
//  //  return [splitterView frame];
//}

- (unsigned int)splitView:(RBSplitView*)sender dividerForPoint:(NSPoint)point inSubview:(RBSplitSubview*)subview {
    JKLogEnteringMethod();
    if (NSPointInRect(point, [splitterView frame])) {
        return 1;
    }
        return NSNotFound;
}

- (NSRect)splitView:(NSSplitView *)splitView additionalEffectiveRectOfDividerAtIndex:(NSInteger)dividerIndex {
    return [splitterView frame];
}

- (IBAction)showSummary:(id)sender {
    [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:[_specials objectAtIndex:0]]] byExtendingSelection:NO];
}

- (IBAction)showRatios:(id)sender {
    [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:[_specials objectAtIndex:1]]] byExtendingSelection:NO];
}

- (IBAction)showGraphical:(id)sender {
    [documentTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[documentTableView rowForItem:[_specials objectAtIndex:2]]] byExtendingSelection:NO];
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
        if ([[[documentTabView selectedTabViewItem] identifier] isKindOfClass:[NSString class]]) {
            [NSApp terminate:self];
         } else {
            PKGCMSDocument *doc = [[documentTabView selectedTabViewItem] identifier];
            [doc canCloseDocumentWithDelegate:self shouldCloseSelector:@selector(document:shouldClose:contextInfo:) contextInfo:nil];
         }
    }
}

- (void)document:(PKGCMSDocument *)doc shouldClose:(BOOL)shouldClose contextInfo:(void *)contextInfo {
    if (shouldClose) {
        int index = [managedDocuments indexOfObject:doc] - 1;
        [managedDocuments removeObject:doc];

        [[doc mainWindowController] setWindow:nil];
        [doc close];
        
        [[self window] makeKeyAndOrderFront:self];
//        NSWindow *tempWindow = [[NSWindow alloc] init];
//        [[doc mainWindowController] setShouldCloseDocument:YES];
//        [doc close];
//        [tempWindow release];
          
        [documentTableView reloadItem:managedDocuments reloadChildren:YES];

        if (index >= [managedDocuments count]) {
            index = [managedDocuments count]-1;
        }
        
        if (index < 0 && [managedDocuments count] > 0) {
            index = 0;
        } 
        
        if ([managedDocuments count] == 0) {
            [documentTableView selectRow:[documentTableView rowForItem:[_specials objectAtIndex:0]] byExtendingSelection:NO];
        } else {
            [documentTableView selectRow:[documentTableView rowForItem:[managedDocuments objectAtIndex:index]] byExtendingSelection:NO];
        }
    }
}

@synthesize window;
@synthesize documentTableView;
@synthesize documentTabView;
@end
