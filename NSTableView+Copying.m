//
//  NSTableView+Copying.m
//  Peacock
//
//  Created by Johan Kool on 22-11-06.
//  Copyright 2006-2008 Johan Kool.
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
        columns = [[self tableColumns] objectEnumerator];
        
        while ((column = [columns nextObject]) != nil) {
            [outString appendString:[[column headerCell] stringValue]];
            [outString appendString:@"\t"];
        }
        [outString appendString:@"\n"];
        for (i=0;i<numberOfRows;i++) {
            columns = [[self tableColumns] objectEnumerator];
            
            while ((column = [columns nextObject]) != nil) {
                id object = [[self dataSource] tableView:self objectValueForTableColumn:column row:i];
                
                [outString appendString:object];
                [outString appendString:@"\t"];
            }
            [outString appendString:@"\n"];
        }
        PKLogDebug(outString);

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
        columns = [[self tableColumns] objectEnumerator];
        
        while ((column = [columns nextObject]) != nil) {
            [outString appendString:[[column headerCell] stringValue]];
            [outString appendString:@"\t"];
        }
        [outString appendString:@"\n"];

        id row;
        rows = [[[self dataSource] arrangedObjects] objectEnumerator];
        while ((row = [rows nextObject]) != nil) {
            columns = [[self tableColumns] objectEnumerator];
            
            while ((column = [columns nextObject]) != nil) {
                id object = [row valueForKeyPath:[column identifier]];
                if (![object isKindOfClass:[NSString class]])
                    object= [object stringValue];
                if (object)
                    [outString appendString:object];
                [outString appendString:@"\t"];
            }
            [outString appendString:@"\n"];
        }
        PKLogDebug(outString);
        
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
