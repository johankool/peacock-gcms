//
//  JKModelObject.h
//  Peacock
//
//  Created by Johan Kool on 22-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKModelObject : NSObject <NSCoding> {
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

@end
