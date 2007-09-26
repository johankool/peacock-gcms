//
//  PKMainWindowController.m
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKMainWindowController.h"

#import "PKDocument.h"
#import "PKChromatogramView.h"

@implementation PKMainWindowController

#pragma mark Intialization & deallocation
- (id)init 
{
	self = [super initWithWindowNibName:@"PKDocument"];
    if (self != nil) {

   	}
    return self;
}

- (void)windowDidLoad
{
    // Drag and drop
    NSArray *fileDragTypes = [NSArray arrayWithObjects:NSFilenamesPboardType, nil];
	[treeView registerForDraggedTypes:fileDragTypes];
    [treeView setDelegate:self];
    [treeView setDataSource:self];
	[measurementsTableView registerForDraggedTypes:fileDragTypes];
    [measurementsTableView setDelegate:self];
    [measurementsTableView setDataSource:self];
    
    // Main tabview items
    NSTabViewItem *measurementsTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"measurements"];
    [measurementsTabViewItem setView:measurementsView];
    [mainTabView addTabViewItem:measurementsTabViewItem];
    [measurementsTabViewItem release];
    
    NSTabViewItem *measurementTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"measurement"];
    [measurementTabViewItem setView:measurementView];
    [mainTabView addTabViewItem:measurementTabViewItem];
    [measurementTabViewItem release];
    
    NSTabViewItem *chromatogramTabViewItem = [[NSTabViewItem alloc] initWithIdentifier:@"chromatogram"];
    [chromatogramTabViewItem setView:chromatogramView];
    [mainTabView addTabViewItem:chromatogramTabViewItem];
    [chromatogramTabViewItem release];
    
    [mainTabView selectTabViewItemWithIdentifier:@"measurements"];
}

- (PKDocument *)document
{
    return [super document];
}

#pragma mark Tree structure
- (NSArray *)children
{
    return tree;
}

- (int)count
{
    return [tree count];
}

- (BOOL)isLeaf
{
    return [tree count] == 0 ? YES : NO; 
}
#pragma mark -

#pragma mark OutlineView delegate methods
- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return ([outlineView levelForItem:item] == 0);
}


- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return ([outlineView levelForItem:item] != 0);
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    int row = [[treeView selectedRowIndexes] firstIndex];
    int level = [treeView levelForRow:row];
    switch (level) {
        case 0:
            [mainTabView selectTabViewItemWithIdentifier:@"measurements"];
            break;
        case 1:
            [mainTabView selectTabViewItemWithIdentifier:@"measurement"];  
            [measurementTabView selectTabViewItemWithIdentifier:@"peaks"];  
            break;
        case 2:
            [mainTabView selectTabViewItemWithIdentifier:@"measurement"];
            [measurementTabView selectTabViewItemWithIdentifier:@"spectrum"];  
            break;
        default:
            [mainTabView selectTabViewItemWithIdentifier:@"welcome"];
           break;
    }
}
#pragma mark -

#pragma mark OutlineView datasource methods
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
     return (item == nil) ? 2 : [item count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return (item == nil) ? YES : ([item count] > 0);
}

- (id)outlineView:(NSOutlineView *)outlineView
            child:(int)index
           ofItem:(id)item
{
    if (item == nil) {
        if (index == 0) {
            return [[self document] measurements];
        } else if (index == 1){
            return [[self document] summaries];
        } else {
            [NSException raise:@"Unexpected index" format:@"Index %d beyond bounds",index];
            return nil;
        }
    }
    if (item == [[self document] measurements]) {
        return [[[self document] measurements] objectAtIndex:index];
    } else if (item == [[self document] summaries]){
        return [[[self document] summaries] objectAtIndex:index];
    }
    
    return [item childAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if (item == [[self document] measurements]) {
        return NSLocalizedString(@"MEASUREMENTS", @"");
    } else if (item == [[self document] summaries]) {
        return NSLocalizedString(@"SUMMARY", @"");
    }
    if ([item respondsToSelector:@selector(label)]) {
        return [item label];
    } else {
        [NSException raise:@"Unexpected item" format:@"Item %@ not expected",item];
        return nil;
    }
 }
#pragma mark -

#pragma mark Drag 'n Drop

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)operation
{	
	if (tableView == measurementsTableView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {            
            NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            for (NSString *filePath in files) {
                [[self document] addMeasurementWithFilePath:filePath atIndex:row+1];
            }
            return YES;
        }
    } 
    return NO;    
}

- (NSDragOperation)tableView:(NSTableView*)tableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op {
	if (tableView == measurementsTableView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]){
  //          [tableView setDropRow:row dropOperation:NSTableViewDropOn];
			return op;
        }
    }
    return NSDragOperationNone;    
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(int)index
{
 	if (outlineView == treeView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]) {            
            NSArray *files = [[info draggingPasteboard] propertyListForType:NSFilenamesPboardType];
            for (NSString *filePath in files) {
                [[self document] addMeasurementWithFilePath:filePath atIndex:index+1];
            }
             return YES;
        }
    } 
    return NO;        
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(int)index
{
    if (outlineView == treeView) {
        if ([[info draggingPasteboard] availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]]){
            //          [outlineView setDropRow:row dropOperation:NSTableViewDropOn];
			return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;    
}
#pragma mark -


@end
