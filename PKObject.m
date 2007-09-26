//
//  PKObject.m
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKObject.h"


@implementation PKObject
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


- (NSArray *)children 
{
    [NSException raise:NSLocalizedString(@"Method not implemented", @"Title of exception thrown when a method is not implemented") format:NSLocalizedString(@"The -children method is not implemented by a subclass of PKObject.", @"Exception explanation")];
    return nil;
}

- (id)childAtIndex:(int)index
{
    return [[self children] objectAtIndex:index];
}
- (int)countOfChildren 
{
    [NSException raise:NSLocalizedString(@"Method not implemented", @"Title of exception thrown when a method is not implemented") format:NSLocalizedString(@"The -countOfChildren method is not implemented by a subclass of PKObject.", @"Exception explanation")];
    return 0;
}

- (BOOL)isLeaf 
{
    [NSException raise:NSLocalizedString(@"Method not implemented", @"Title of exception thrown when a method is not implemented") format:NSLocalizedString(@"The -isLeaf method is not implemented by a subclass of PKObject.", @"Exception explanation")];    
    return NO;
}
@end
