// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKPeak.m instead.

#import "_JKPeak.h"

@implementation _JKPeak


- (NSNumber*)peakXvalue {
	[self willAccessValueForKey:@"peakXvalue"];
	NSNumber *result = [self primitiveValueForKey:@"peakXvalue"];
	[self didAccessValueForKey:@"peakXvalue"];
	return result;
}

- (void)setPeakXvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"peakXvalue"];
    [self setPrimitiveValue:value_ forKey:@"peakXvalue"];
    [self didChangeValueForKey:@"peakXvalue"];
}

- (BOOL)validatePeakXvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)peakXvalueValue {
	return [[self peakXvalue] doubleValue];
}

- (void)setPeakXvalueValue:(double)value_ {
	[self setPeakXvalue:[NSNumber numberWithDouble:value_]];
}





- (NSString*)group {
	[self willAccessValueForKey:@"group"];
	NSString *result = [self primitiveValueForKey:@"group"];
	[self didAccessValueForKey:@"group"];
	return result;
}

- (void)setGroup:(NSString*)value_ {
    [self willChangeValueForKey:@"group"];
    [self setPrimitiveValue:value_ forKey:@"group"];
    [self didChangeValueForKey:@"group"];
}

- (BOOL)validateGroup:(id*)value_ error:(NSError**)error_ {
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





- (NSNumber*)number {
	[self willAccessValueForKey:@"number"];
	NSNumber *result = [self primitiveValueForKey:@"number"];
	[self didAccessValueForKey:@"number"];
	return result;
}

- (void)setNumber:(NSNumber*)value_ {
    [self willChangeValueForKey:@"number"];
    [self setPrimitiveValue:value_ forKey:@"number"];
    [self didChangeValueForKey:@"number"];
}

- (BOOL)validateNumber:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (long)numberValue {
	return [[self number] longValue];
}

- (void)setNumberValue:(long)value_ {
	[self setNumber:[NSNumber numberWithLong:value_]];
}





- (NSNumber*)peakYvalue {
	[self willAccessValueForKey:@"peakYvalue"];
	NSNumber *result = [self primitiveValueForKey:@"peakYvalue"];
	[self didAccessValueForKey:@"peakYvalue"];
	return result;
}

- (void)setPeakYvalue:(NSNumber*)value_ {
    [self willChangeValueForKey:@"peakYvalue"];
    [self setPrimitiveValue:value_ forKey:@"peakYvalue"];
    [self didChangeValueForKey:@"peakYvalue"];
}

- (BOOL)validatePeakYvalue:(id*)value_ error:(NSError**)error_ {
	return YES;
}



- (double)peakYvalueValue {
	return [[self peakYvalue] doubleValue];
}

- (void)setPeakYvalueValue:(double)value_ {
	[self setPeakYvalue:[NSNumber numberWithDouble:value_]];
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
	

	

- (JKBaseline*)baseline {
	[self willAccessValueForKey:@"baseline"];
	JKBaseline *result = [self primitiveValueForKey:@"baseline"];
	[self didAccessValueForKey:@"baseline"];
	return result;
}

- (void)setBaseline:(JKBaseline*)value_ {
	[self willChangeValueForKey:@"baseline"];
	[self setPrimitiveValue:value_ forKey:@"baseline"];
	[self didChangeValueForKey:@"baseline"];
}

- (BOOL)validateBaseline:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
