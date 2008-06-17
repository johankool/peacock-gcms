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

#import "PKDeletableTableView.h"
	
@implementation PKDeletableTableView

- (void)bind:(NSString *)binding toObject:(id)observable
	withKeyPath:(NSString *)keyPath options:(NSDictionary *)options
{	
	if ( [binding isEqualToString:@"content"] )
	{
		tableContentController = observable;
		[tableContentKey release];
		tableContentKey = [keyPath copy];
	}
	[super bind:binding toObject:observable withKeyPath:keyPath options:options];
}


- (void)keyDown:(NSEvent *)event{
	unichar key = [[event charactersIgnoringModifiers] characterAtIndex:0];
    
	// get flags and strip the lower 16 (device dependant) bits
	unsigned int flags = ( [event modifierFlags] & 0x00FF );
    
	if ((key == NSDeleteCharacter) && (flags == 0))
	{ 
		if ([self selectedRow] == -1)
		{
			NSBeep();
		}
		else
		{
            NSEnumerator *enumerator = [[tableContentController selectedObjects] objectEnumerator];
            id object;

            while ((object = [enumerator nextObject]) != nil) {
                if ([object respondsToSelector:@selector(selfDeconstruct)]) {
                    [object performSelector:@selector(selfDeconstruct)];
                }
            }
			[tableContentController removeObjectsAtArrangedObjectIndexes:
				[self selectedRowIndexes]];
		}
	}
	else if ((key == NSLeftArrowFunctionKey) && (flags == 0))
	{ 
		if (leftSideTableView)
		{
            if ([leftSideTableView isHiddenOrHasHiddenAncestor]) {
                [super keyDown:event];
                return;
            }
            [[leftSideTableView window] makeFirstResponder:leftSideTableView];
            if (([leftSideTableView selectedRow] == -1) && ([leftSideTableView numberOfRows] > 0)) {
                [leftSideTableView selectRow:0 byExtendingSelection:NO];
            }
		}
		else
		{
            [super keyDown:event];
		}
	}
	else if ((key == NSRightArrowFunctionKey) && (flags == 0))
	{ 
		if (rightSideTableView)
		{
            if ([rightSideTableView isHiddenOrHasHiddenAncestor]) {
                [super keyDown:event];
                return;
            }
            [[rightSideTableView window] makeFirstResponder:rightSideTableView];
            if (([rightSideTableView selectedRow] == -1) && ([rightSideTableView numberOfRows] > 0)) {
                [rightSideTableView selectRow:0 byExtendingSelection:NO];
            }
		}
		else
		{
            [super keyDown:event];
		}
	}
	else
	{
		[super keyDown:event]; // let somebody else handle the event 
	}
}


- (void)unbind:(NSString *)binding{
	[super unbind:binding];
	
	if ( [binding isEqualToString:@"content"] )
	{
		tableContentController = nil;
		[tableContentKey release];
		tableContentKey = nil;
	}
}
/*
#pragma mark Column Hiding

//column  identifier  visible   index
//column1 identifier1 YES       1
//column2 identifier2 YES       2
//column3 identifier3 NO        3
//column4 identifier4 YES       4
//column5 identifier5 NO        5
//column6 identifier6 YES       6


- (BOOL)allowsColumnHiding;
{
    return allowsColumnHiding
}
- (void)setAllowsColumnHiding:(BOOL)boolValue
{
    allowsColumnHiding = boolValue;
}

- (void)hideColumnWithIdentifier:(id)identifier
{
    NSTableColumn *tableColumn = [self tableColumnWithIdentifier:identifier];
    NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:tableColumn, @"tableColumn", index, @"index",  nil];
    [hiddenColumns addObject:dict];
    [self removeTableColumn:tableColumn];
}
- (void)showColumnWithIdentifier:(id)identifier;
- (void)toggleColumnWithIdentifier:(id)identifier
{
    if ([self visibleColumnWithIdentifier:identifier]) {
        [self hideColumnWithIdentifier:identifier];
    } else {
        [self showColumnWithIdentifier:identifier];        
    }
}

- (BOOL)visibleColumnWithIdentifier:(id)identifier
{
    int index = [[self tableColumns] indexOfObject:[self tableColumnWithIdentifier:identifier]];
    if (index != NSNotFound)
        return [[columnVisibility valueForKey:[NSString stringWithFormat:@"%d",index]] boolValue];
    return nil;
}

*/
@synthesize leftSideTableView;
@synthesize allowsColumnHiding;
@synthesize allowsRowDeletion;
@synthesize tableContentController;
@synthesize tableContentKey;
@synthesize columnVisibility;
@synthesize rightSideTableView;
@end
