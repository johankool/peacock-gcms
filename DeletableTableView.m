//
// Original source is courtesy of Vince DeMarco at Apple
// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-March/011104.html

#import "DeletableTableView.h"

@implementation DeletableTableView

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *keyString = [theEvent charactersIgnoringModifiers];
	unichar   keyChar = [keyString characterAtIndex:0];

	switch (keyChar)
	{
		case 0177: // Delete Key
		case NSDeleteFunctionKey:
		case NSDeleteCharFunctionKey:
			if ( [self selectedRow] >= 0
				&& [[self dataSource] respondsToSelector:@selector(deleteSelectedRowsInTableView:)])
			{
				[[self dataSource] deleteSelectedRowsInTableView:self];
			}
			break;
		default:
			[super keyDown:theEvent];
	}
}

@end

