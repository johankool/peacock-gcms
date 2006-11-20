// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKXData.m instead.

#import "_JKXData.h"

@implementation _JKXData


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





- (NSString*)byteOrder {
	[self willAccessValueForKey:@"byteOrder"];
	NSString *result = [self primitiveValueForKey:@"byteOrder"];
	[self didAccessValueForKey:@"byteOrder"];
	return result;
}

- (void)setByteOrder:(NSString*)value_ {
    [self willChangeValueForKey:@"byteOrder"];
    [self setPrimitiveValue:value_ forKey:@"byteOrder"];
    [self didChangeValueForKey:@"byteOrder"];
}

- (BOOL)validateByteOrder:(id*)value_ error:(NSError**)error_ {
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





- (NSData*)values {
	[self willAccessValueForKey:@"values"];
	NSData *result = [self primitiveValueForKey:@"values"];
	[self didAccessValueForKey:@"values"];
	return result;
}

- (void)setValues:(NSData*)value_ {
    [self willChangeValueForKey:@"values"];
    [self setPrimitiveValue:value_ forKey:@"values"];
    [self didChangeValueForKey:@"values"];
}

- (BOOL)validateValues:(id*)value_ error:(NSError**)error_ {
	return YES;
}





- (NSString*)format {
	[self willAccessValueForKey:@"format"];
	NSString *result = [self primitiveValueForKey:@"format"];
	[self didAccessValueForKey:@"format"];
	return result;
}

- (void)setFormat:(NSString*)value_ {
    [self willChangeValueForKey:@"format"];
    [self setPrimitiveValue:value_ forKey:@"format"];
    [self didChangeValueForKey:@"format"];
}

- (BOOL)validateFormat:(id*)value_ error:(NSError**)error_ {
	return YES;
}






	
- (void)addYDataObject:(JKYData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"yData" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [[self primitiveValueForKey:@"yData"] addObject:value_];
    [self didChangeValueForKey:@"yData" withSetMutation:NSKeyValueUnionSetMutation usingObjects:changedObjects];
    [changedObjects release];
}

- (void)removeYDataObject:(JKYData*)value_ {
	NSSet *changedObjects = [[NSSet alloc] initWithObjects:&value_ count:1];
	[self willChangeValueForKey:@"yData" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[[self primitiveValueForKey:@"yData"] removeObject:value_];
	[self didChangeValueForKey:@"yData" withSetMutation:NSKeyValueMinusSetMutation usingObjects:changedObjects];
	[changedObjects release];
}

- (NSMutableSet*)yDataSet {
	return [self mutableSetValueForKey:@"yData"];
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
