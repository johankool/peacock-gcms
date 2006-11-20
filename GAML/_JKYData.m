// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKYData.m instead.

#import "_JKYData.h"

@implementation _JKYData


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
	

	

- (JKXData*)xData {
	[self willAccessValueForKey:@"xData"];
	JKXData *result = [self primitiveValueForKey:@"xData"];
	[self didAccessValueForKey:@"xData"];
	return result;
}

- (void)setXData:(JKXData*)value_ {
	[self willChangeValueForKey:@"xData"];
	[self setPrimitiveValue:value_ forKey:@"xData"];
	[self didChangeValueForKey:@"xData"];
}

- (BOOL)validateXData:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

	

- (JKPeakTable*)peakTable {
	[self willAccessValueForKey:@"peakTable"];
	JKPeakTable *result = [self primitiveValueForKey:@"peakTable"];
	[self didAccessValueForKey:@"peakTable"];
	return result;
}

- (void)setPeakTable:(JKPeakTable*)value_ {
	[self willChangeValueForKey:@"peakTable"];
	[self setPrimitiveValue:value_ forKey:@"peakTable"];
	[self didChangeValueForKey:@"peakTable"];
}

- (BOOL)validatePeakTable:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
