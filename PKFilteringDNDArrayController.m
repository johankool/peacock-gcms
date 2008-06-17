//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKFilteringDNDArrayController.h"

NSString *CopiedRowsType = @"ENTRY_TYPE";
NSString *MovedRowsType = @"ENTRY_TYPE";

@implementation PKFilteringDNDArrayController

- (void)awakeFromNib{
    // register for drag and drop
    [tableView registerForDraggedTypes:
	[NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", MovedRowsType, nil]];
}

#pragma mark Tableview drag and drop support etc.

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard {    
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", MovedRowsType, nil];
    [pboard declareTypes:typesArray owner:self];

    NSMutableData *data;
    NSKeyedArchiver *archiver;
        
    // add rows array for local move
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:rowIndexes forKey:@"rowIndexes"];
    [archiver finishEncoding];
    [pboard setData:data forType:MovedRowsType];
    [archiver release];
 	
    data = [NSMutableData data];
    archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:[[self arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] forKey:@"JKLibraryEntryTableViewDataType"];
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
        NSData *data = [[info draggingPasteboard] dataForType:MovedRowsType];
        NSKeyedUnarchiver *unarchiver;
        unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSIndexSet  *indexSet = [unarchiver decodeObjectForKey:@"rowIndexes"];
        [unarchiver finishDecoding];
        [unarchiver release];
                  
        [self moveObjectsInArrangedObjectsFromIndexes:indexSet toIndex:row];
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
    NSNumber *idx;
    for (idx in rows) {
        PKLogDebug([idx description]);
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

@synthesize tableView;
@end
