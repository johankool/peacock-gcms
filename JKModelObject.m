//
//  JKModelObject.m
//  Peacock
//
//  Created by Johan Kool on 22-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKModelObject.h"


@implementation JKModelObject

#pragma mark Initialization & deallocation
- (id) init
{
	if ((self = [super init]) != nil) {
		[self setContainer:nil];
	}
	return self;
}
- (void) dealloc {
    [self setContainer:nil];
    [super dealloc];
}
#pragma mark -

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
	[super init];
    [self setContainer:[decoder decodeObjectForKey:@"container"]];
	return self;
}
- (void)encodeWithCoder:(NSCoder *)encoder 
{
    if ([container respondsToSelector:@selector(encodeWithCoder:)])
        [encoder encodeObject:container forKey:@"container"];
}
#pragma mark -

#pragma mark Undo
- (NSUndoManager *)undoManager
{
    if (container) {
        return [container undoManager];
    } else {
        return nil;
    }
}
#pragma mark -

#pragma mark Document
- (NSDocument *)document
{
    id object = self;
    while ([object container]) {
        object = [object container];
        if ([object isKindOfClass:[NSDocument class]]) {
            return object;
        }
    }
    return nil;
}
#pragma mark -

#pragma mark Accessors
#pragma mark (weakly referenced)
- (id)container
{
        return container;
}
- (void)setContainer:(id)aContainer
{
    container = aContainer;
}

@end
