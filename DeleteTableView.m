//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "DeleteTableView.h"
	
@implementation DeleteTableView

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
@end
