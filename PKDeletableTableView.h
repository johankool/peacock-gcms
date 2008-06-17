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

@interface PKDeletableTableView : NSTableView {
	NSArrayController	*tableContentController;
	NSString * tableContentKey;
    BOOL allowsRowDeletion;
    BOOL allowsColumnHiding;
    NSMutableDictionary *columnVisibility;
    
    IBOutlet NSTableView *leftSideTableView;
    IBOutlet NSTableView *rightSideTableView;
}
/*
#pragma mark Row deletion
- (BOOL)allowsRowDeletion;
- (void)setAllowsRowDeletion:(BOOL)boolValue;
#pragma mark -

#pragma mark Column Hiding
- (BOOL)allowsColumnHiding;
- (void)setAllowsColumnHiding:(BOOL)boolValue;

- (void)hideColumnWithIdentifier:(id)identifier;
- (void)showColumnWithIdentifier:(id)identifier;
- (void)toggleColumnWithIdentifier:(id)identifier;

- (BOOL)visibleColumnWithIdentifier:(id)identifier;
*/
@property (retain) NSTableView *rightSideTableView;
@property (retain) NSString * tableContentKey;
@property BOOL allowsColumnHiding;
@property (retain) NSMutableDictionary *columnVisibility;
@property (retain) NSArrayController	*tableContentController;
@property (retain) NSTableView *leftSideTableView;
@property BOOL allowsRowDeletion;
@end
