// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKExperiment.m instead.

#import "_JKExperiment.h"

@implementation _JKExperiment


- (NSDate*)collectDate {
	[self willAccessValueForKey:@"collectDate"];
	NSDate *result = [self primitiveValueForKey:@"collectDate"];
	[self didAccessValueForKey:@"collectDate"];
	return result;
}

- (void)setCollectDate:(NSDate*)value_ {
    [self willChangeValueForKey:@"collectDate"];
    [self setPrimitiveValue:value_ forKey:@"collectDate"];
    [self didChangeValueForKey:@"collectDate"];
}

- (BOOL)validateCollectDate:(id*)value_ error:(NSError**)error_ {
	return YES;
}





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
	

	
- (void)addTracesObject:(JKTrace*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"traces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"traces"] addObject:value_];
    [self didChangeValueForKey:@"traces" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeTracesObject:(JKTrace*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"traces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"traces"] removeObject:value_];
	[self didChangeValueForKey:@"traces" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)tracesSet {
	return [self mutableSetValueForKey:@"traces"];
}
	

	

- (JKGAML*)gaml {
	[self willAccessValueForKey:@"gaml"];
	JKGAML *result = [self primitiveValueForKey:@"gaml"];
	[self didAccessValueForKey:@"gaml"];
	return result;
}

- (void)setGaml:(JKGAML*)value_ {
	[self willChangeValueForKey:@"gaml"];
	[self setPrimitiveValue:value_ forKey:@"gaml"];
	[self didChangeValueForKey:@"gaml"];
}

- (BOOL)validateGaml:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
