// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKBasic.m instead.

#import "_JKBasic.h"

@implementation _JKBasic



	
- (void)addParametersObject:(JKParameter*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"parameters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"parameters"] addObject:value_];
    [self didChangeValueForKey:@"parameters" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeParametersObject:(JKParameter*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"parameters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"parameters"] removeObject:value_];
	[self didChangeValueForKey:@"parameters" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)parametersSet {
	return [self mutableSetValueForKey:@"parameters"];
}
	

@end
