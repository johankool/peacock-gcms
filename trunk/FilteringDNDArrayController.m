//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "FilteringDNDArrayController.h"

NSString *CopiedRowsType = @"ENTRY_TYPE";
NSString *MovedRowsType = @"ENTRY_TYPE";

@implementation FilteringDNDArrayController

- (void)awakeFromNib{
    // register for drag and drop
    [tableView registerForDraggedTypes:
		[NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", MovedRowsType, nil]];
//    [tableView setAllowsMultipleSelection:YES];
////    

}

#pragma mark Tableview drag and drop support etc.

- (BOOL)tableView:(NSTableView *)tv
		writeRows:(NSArray*)rows
	 toPasteboard:(NSPasteboard*)pboard{
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", MovedRowsType, nil];
    [pboard declareTypes:typesArray owner:self];

    // add rows array for local move
    [pboard setPropertyList:rows forType:MovedRowsType];
	
    NSMutableData *data;
    NSKeyedArchiver *archiver;
    
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[[self arrangedObjects] objectAtIndex:[[rows objectAtIndex:0] intValue]] forKey:@"JKLibraryEntryTableViewDataType"];
    [archiver finishEncoding];
    [pboard setData:data forType:@"JKLibraryEntryTableViewDataType"];
    [archiver release];
	
    return YES;
}


- (NSDragOperation)tableView:(NSTableView*)tv
				validateDrop:(id <NSDraggingInfo>)info
				 proposedRow:(int)row
	   proposedDropOperation:(NSTableViewDropOperation)op{
    
    NSDragOperation dragOp = NSDragOperationCopy;
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
	{
		dragOp =  NSDragOperationMove;
    }
    // we want to put the object at, not over,
    // the current row (contrast NSTableViewDropOn) 
    [tv setDropRow:row dropOperation:NSTableViewDropAbove];
	
    return dragOp;
}



- (BOOL)tableView:(NSTableView*)tv
	   acceptDrop:(id <NSDraggingInfo>)info
			  row:(int)row
	dropOperation:(NSTableViewDropOperation)op{
    if (row < 0)
	{
		row = 0;
	}
    
    // if drag source is self, it's a move
    if ([info draggingSource] == tableView)
   {
#warning [BUG] Also non-selected rows can be dragged, if that's the case the move will not occur
		//NSArray *rows = [[info draggingPasteboard] propertyListForType:MovedRowsType];
		//NSIndexSet  *indexSet = [self indexSetFromRows:rows];
		NSIndexSet  *indexSet = [tableView selectedRowIndexes];
                
        [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
		
		// set selected rows to those that were just moved
		// Need to work out what moved where to determine proper selection...
		int rowsAbove = [self rowsAboveRow:row inIndexSet:indexSet];
		
		NSRange range = NSMakeRange(row - rowsAbove, [indexSet count]);
		indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
		[self setSelectionIndexes:indexSet];
		
		return YES;
    }
	
//	// Can we get rows from another document?  If so, add them, then return.
//	NSArray *newRows = [[info draggingPasteboard] propertyListForType:CopiedRowsType];
//	if (newRows)
//	{
//		NSRange range = NSMakeRange(row, [newRows count]);
//		NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:range];
//		
//		[self insertObjects:newRows atArrangedObjectIndexes:indexSet];
//		// set selected rows to those that were just copied
//		[self setSelectionIndexes:indexSet];
//		return YES;
//    }
	
    return NO;
}



- (void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet 
									   toIndex:(unsigned)index{
    unsigned off1 = 0, off2 = 0;
    
    unsigned currentIndex = [indexSet firstIndex];
    while (currentIndex != NSNotFound)
   {
		unsigned i = currentIndex;
		
		if (i < index)
		{
			i -= off1++;
			[self insertObject:[[self arrangedObjects] objectAtIndex:i] atArrangedObjectIndex:index];
			[self removeObjectAtArrangedObjectIndex:i];
		}
		else
		{
			[self insertObject:[[self arrangedObjects] objectAtIndex:i] atArrangedObjectIndex:index+off2++];
			[self removeObjectAtArrangedObjectIndex:i+1];
		}
        currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
}


- (NSIndexSet *)indexSetFromRows:(NSArray *)rows{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    NSEnumerator *rowEnumerator = [rows objectEnumerator];
    NSNumber *idx;
    while ((idx = [rowEnumerator nextObject])) {
        JKLogDebug([idx description]);
		[indexSet addIndex:[idx intValue]];
    }
    return indexSet;
}


- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet{
    int currentIndex = [indexSet firstIndex];
	int i = 0;
    while (currentIndex != NSNotFound)
   {
		if (currentIndex < row) { i++; }
		currentIndex = [indexSet indexGreaterThanIndex:currentIndex];
    }
    return i;
}

@end
