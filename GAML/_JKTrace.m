// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKTrace.m instead.

#import "_JKTrace.h"

@implementation _JKTrace


- (NSString*)technique {
	[self willAccessValueForKey:@"technique"];
	NSString *result = [self primitiveValueForKey:@"technique"];
	[self didAccessValueForKey:@"technique"];
	return result;
}

- (void)setTechnique:(NSString*)value_ {
    [self willChangeValueForKey:@"technique"];
    [self setPrimitiveValue:value_ forKey:@"technique"];
    [self didChangeValueForKey:@"technique"];
}

- (BOOL)validateTechnique:(id*)value_ error:(NSError**)error_ {
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






	
- (void)addCoordinatesObject:(JKCoordinates*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"coordinates" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"coordinates"] addObject:value_];
    [self didChangeValueForKey:@"coordinates" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeCoordinatesObject:(JKCoordinates*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"coordinates" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"coordinates"] removeObject:value_];
	[self didChangeValueForKey:@"coordinates" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)coordinatesSet {
	return [self mutableSetValueForKey:@"coordinates"];
}
	

	
- (void)addXDataObject:(JKData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"xData" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"xData"] addObject:value_];
    [self didChangeValueForKey:@"xData" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeXDataObject:(JKData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"xData" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"xData"] removeObject:value_];
	[self didChangeValueForKey:@"xData" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)xDataSet {
	return [self mutableSetValueForKey:@"xData"];
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
	

	

- (JKExperiment*)experiment {
	[self willAccessValueForKey:@"experiment"];
	JKExperiment *result = [self primitiveValueForKey:@"experiment"];
	[self didAccessValueForKey:@"experiment"];
	return result;
}

- (void)setExperiment:(JKExperiment*)value_ {
	[self willChangeValueForKey:@"experiment"];
	[self setPrimitiveValue:value_ forKey:@"experiment"];
	[self didChangeValueForKey:@"experiment"];
}

- (BOOL)validateExperiment:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
