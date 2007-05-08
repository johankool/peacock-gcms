//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//


@interface DeleteTableView : NSTableView {
	NSArrayController	*tableContentController;
	NSString * tableContentKey;
    BOOL allowsRowDeletion;
    BOOL allowsColumnHiding;
    NSMutableDictionary *columnVisibility;
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
@end
