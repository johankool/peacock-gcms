// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKBaseline.m instead.

#import "_JKBaseline.h"

@implementation _JKBaseline


- (NSNumber*)startXvalue {
	[self willAccessValueForKey:@"startXvalue"];
	NSNumber *result = [self primitiveValueForKey:@"startXvalue"];
	[self didAccessValueForKey:@"startXvalue"];
	return result;
}

- (void)setStartXvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"startXvalue"];
    [self setPrimitiveValue:value_ forKey:@"startXvalue"];
    [self didChangeValueForKey:@"startXvalue"];
}

- (BOOL)validateStartXvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)startXvalueValue {
	return [[self startXvalue] doubleValue];
}

- (void)setStartXvalueValue:(double)value_ {
	[self setStartXvalue:[NSNumber numberWithDouble:value_]];
}





- (NSNumber*)endYvalue {
	[self willAccessValueForKey:@"endYvalue"];
	NSNumber *result = [self primitiveValueForKey:@"endYvalue"];
	[self didAccessValueForKey:@"endYvalue"];
	return result;
}

- (void)setEndYvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"endYvalue"];
    [self setPrimitiveValue:value_ forKey:@"endYvalue"];
    [self didChangeValueForKey:@"endYvalue"];
}

- (BOOL)validateEndYvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)endYvalueValue {
	return [[self endYvalue] doubleValue];
}

- (void)setEndYvalueValue:(double)value_ {
	[self setEndYvalue:[NSNumber numberWithDouble:value_]];
}





- (NSNumber*)endXvalue {
	[self willAccessValueForKey:@"endXvalue"];
	NSNumber *result = [self primitiveValueForKey:@"endXvalue"];
	[self didAccessValueForKey:@"endXvalue"];
	return result;
}

- (void)setEndXvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"endXvalue"];
    [self setPrimitiveValue:value_ forKey:@"endXvalue"];
    [self didChangeValueForKey:@"endXvalue"];
}

- (BOOL)validateEndXvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)endXvalueValue {
	return [[self endXvalue] doubleValue];
}

- (void)setEndXvalueValue:(double)value_ {
	[self setEndXvalue:[NSNumber numberWithDouble:value_]];
}





- (NSNumber*)startYvalue {
	[self willAccessValueForKey:@"startYvalue"];
	NSNumber *result = [self primitiveValueForKey:@"startYvalue"];
	[self didAccessValueForKey:@"startYvalue"];
	return result;
}

- (void)setStartYvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"startYvalue"];
    [self setPrimitiveValue:value_ forKey:@"startYvalue"];
    [self didChangeValueForKey:@"startYvalue"];
}

- (BOOL)validateStartYvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)startYvalueValue {
	return [[self startYvalue] doubleValue];
}

- (void)setStartYvalueValue:(double)value_ {
	[self setStartYvalue:[NSNumber numberWithDouble:value_]];
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
	

	

- (JKPeak*)peak {
	[self willAccessValueForKey:@"peak"];
	JKPeak *result = [self primitiveValueForKey:@"peak"];
	[self didAccessValueForKey:@"peak"];
	return result;
}

- (void)setPeak:(JKPeak*)value_ {
	[self willChangeValueForKey:@"peak"];
	[self setPrimitiveValue:value_ forKey:@"peak"];
	[self didChangeValueForKey:@"peak"];
}

- (BOOL)validatePeak:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
