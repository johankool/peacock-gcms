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

@end
