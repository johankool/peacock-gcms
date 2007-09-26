//
//  PKObject.h
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKObject : NSObject {
    id container;
}

#pragma mark Undo
- (NSUndoManager *)undoManager;
#pragma mark -

#pragma mark Document
- (NSDocument *)document;
#pragma mark -

#pragma mark Accessors
#pragma mark (weak referenced)
- (id) container;
- (void) setContainer:(id)aContainer;

@property (assign,getter=container,setter=setContainer:) id container;

- (NSArray *)children;
- (int)countOfChildren;
- (BOOL)isLeaf;

@end
