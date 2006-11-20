// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKGAML.m instead.

#import "_JKGAML.h"

@implementation _JKGAML


- (NSString*)name {
	[self willAccessValueForKey:@"name"];
	NSString *result = [self primitiveValueForKey:@"name"];
	[self didAccessValueForKey:@"name"];
	return result;
}

- (void)setName:(NSString*)value_ {
    [self willChangeValueForKey:@"name"];
    [self setPrimitiveValue:value_ forKey:@"name"];
    [self didChangeValueForKey:@"name"];
}

- (BOOL)validateName:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)version {
	[self willAccessValueForKey:@"version"];
	NSString *result = [self primitiveValueForKey:@"version"];
	[self didAccessValueForKey:@"version"];
	return result;
}

- (void)setVersion:(NSString*)value_ {
    [self willChangeValueForKey:@"version"];
    [self setPrimitiveValue:value_ forKey:@"version"];
    [self didChangeValueForKey:@"version"];
}

- (BOOL)validateVersion:(id*)value_ error:(NSError**)error_ {
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
	

	
- (void)addExperimentsObject:(JKExperiment*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"experiments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"experiments"] addObject:value_];
    [self didChangeValueForKey:@"experiments" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeExperimentsObject:(JKExperiment*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"experiments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"experiments"] removeObject:value_];
	[self didChangeValueForKey:@"experiments" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)experimentsSet {
	return [self mutableSetValueForKey:@"experiments"];
}
	

@end
