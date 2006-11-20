// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKCoordinates.m instead.

#import "_JKCoordinates.h"

@implementation _JKCoordinates


- (NSString*)linkid {
	[self willAccessValueForKey:@"linkid"];
	NSString *result = [self primitiveValueForKey:@"linkid"];
	[self didAccessValueForKey:@"linkid"];
	return result;
}

- (void)setLinkid:(NSString*)value_ {
    [self willChangeValueForKey:@"linkid"];
    [self setPrimitiveValue:value_ forKey:@"linkid"];
    [self didChangeValueForKey:@"linkid"];
}

- (BOOL)validateLinkid:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)linkref {
	[self willAccessValueForKey:@"linkref"];
	NSString *result = [self primitiveValueForKey:@"linkref"];
	[self didAccessValueForKey:@"linkref"];
	return result;
}

- (void)setLinkref:(NSString*)value_ {
    [self willChangeValueForKey:@"linkref"];
    [self setPrimitiveValue:value_ forKey:@"linkref"];
    [self didChangeValueForKey:@"linkref"];
}

- (BOOL)validateLinkref:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)valueorder {
	[self willAccessValueForKey:@"valueorder"];
	NSString *result = [self primitiveValueForKey:@"valueorder"];
	[self didAccessValueForKey:@"valueorder"];
	return result;
}

- (void)setValueorder:(NSString*)value_ {
    [self willChangeValueForKey:@"valueorder"];
    [self setPrimitiveValue:value_ forKey:@"valueorder"];
    [self didChangeValueForKey:@"valueorder"];
}

- (BOOL)validateValueorder:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)units {
	[self willAccessValueForKey:@"units"];
	NSString *result = [self primitiveValueForKey:@"units"];
	[self didAccessValueForKey:@"units"];
	return result;
}

- (void)setUnits:(NSString*)value_ {
    [self willChangeValueForKey:@"units"];
    [self setPrimitiveValue:value_ forKey:@"units"];
    [self didChangeValueForKey:@"units"];
}

- (BOOL)validateUnits:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)label {
	[self willAccessValueForKey:@"label"];
	NSString *result = [self primitiveValueForKey:@"label"];
	[self didAccessValueForKey:@"label"];
	return result;
}

- (void)setLabel:(NSString*)value_ {
    [self willChangeValueForKey:@"label"];
    [self setPrimitiveValue:value_ forKey:@"label"];
    [self didChangeValueForKey:@"label"];
}

- (BOOL)validateLabel:(id*)value_ error:(NSError**)error_ {
	return YES;
}






	

- (JKTrace*)trace {
	[self willAccessValueForKey:@"trace"];
	JKTrace *result = [self primitiveValueForKey:@"trace"];
	[self didAccessValueForKey:@"trace"];
	return result;
}

- (void)setTrace:(JKTrace*)value_ {
	[self willChangeValueForKey:@"trace"];
	[self setPrimitiveValue:value_ forKey:@"trace"];
	[self didChangeValueForKey:@"trace"];
}

- (BOOL)validateTrace:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

	
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
