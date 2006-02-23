//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@interface FilteringDNDArrayController : NSArrayController
{
    IBOutlet NSTableView *tableView;
}

#pragma mark Tableview drag and drop support etc.

- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
    
- (NSDragOperation)tableView:(NSTableView*)tv validateDrop:(id <NSDraggingInfo>)info proposedRow:(int)row proposedDropOperation:(NSTableViewDropOperation)op;
    
- (BOOL)tableView:(NSTableView*)tv acceptDrop:(id <NSDraggingInfo>)info row:(int)row dropOperation:(NSTableViewDropOperation)op;

// utility methods

-(void)moveObjectsInArrangedObjectsFromIndexes:(NSIndexSet *)indexSet 
				    toIndex:(unsigned)index;

- (NSIndexSet *)indexSetFromRows:(NSArray *)rows;
- (int)rowsAboveRow:(int)row inIndexSet:(NSIndexSet *)indexSet;
@end
