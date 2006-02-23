//
// Based on source is courtesy of Vince DeMarco at Apple
// http://www.omnigroup.com/mailman/archive/macosx-dev/2001-March/011104.html

#import <AppKit/AppKit.h>

@interface DeletableTableView : NSTableView

@end

@interface NSObject(MyTableViewDataSource)
- (void)deleteSelectedRowsInTableView:(NSTableView *)tableView;
@end
