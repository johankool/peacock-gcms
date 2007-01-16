//
//  NSTableView+Copying.m
//  Peacock
//
//  Created by Johan Kool on 22-11-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "NSTableView+Copying.h"


@implementation NSTableView (Copying)

- (IBAction)copy:(id)sender {
    NSArray *myPboardTypes;
    NSMutableString *outString = [NSMutableString stringWithString:@""];
    if ([[self dataSource] respondsToSelector:@selector(numberOfRowsInTableView:)]) {
        int numberOfRows = [[self dataSource] numberOfRowsInTableView:self];
        int i;
        NSEnumerator *columns;
        NSTableColumn *column;
        for (i=0;i<numberOfRows;i++) {
            columns = [[self tableColumns] objectEnumerator];
            
            while ((column = [columns nextObject]) != nil) {
                id object = [[self dataSource] tableView:self objectValueForTableColumn:column row:i];
                
                [outString appendString:object];
                [outString appendString:@"\t"];
            }
            [outString appendString:@"\n"];
        }
//        NSLog(outString);

        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        //Declare types of data you'll be putting onto the pasteboard
        myPboardTypes = [NSArray arrayWithObjects:NSTabularTextPboardType,NSStringPboardType,nil];
        [pb declareTypes:myPboardTypes owner:self];
        [pb setString:outString forType:NSTabularTextPboardType];
        [pb setString:outString forType:NSStringPboardType];
        
    } else if  ([[self dataSource] respondsToSelector:@selector(arrangedObjects)]) {
        NSEnumerator *rows;
        NSTableColumn *column;
        NSEnumerator *columns;
        id row;
        rows = [[[self dataSource] arrangedObjects] objectEnumerator];
        
        while ((row = [rows nextObject]) != nil) {
            columns = [[self tableColumns] objectEnumerator];
            
            while ((column = [columns nextObject]) != nil) {
                id object = [row valueForKey:[column identifier]];
                if (![object isKindOfClass:[NSString class]])
                    object= [object stringValue];
                if (object)
                    [outString appendString:object];
                [outString appendString:@"\t"];
            }
            [outString appendString:@"\n"];
        }
//        NSLog(outString);
        
        NSPasteboard *pb = [NSPasteboard generalPasteboard];
        //Declare types of data you'll be putting onto the pasteboard
        myPboardTypes = [NSArray arrayWithObjects:NSTabularTextPboardType,NSStringPboardType,nil];
        [pb declareTypes:myPboardTypes owner:self];
        [pb setString:outString forType:NSTabularTextPboardType];
        [pb setString:outString forType:NSStringPboardType];
        
    } else {
        NSBeep();
    }
}

- (IBAction)reloadData:(id)sender {
    [self reloadData];
}
@end
