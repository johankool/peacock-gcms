// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKParameter.m instead.

#import "_JKParameter.h"

@implementation _JKParameter


- (NSString*)value {
	[self willAccessValueForKey:@"value"];
	NSString *result = [self primitiveValueForKey:@"value"];
	[self didAccessValueForKey:@"value"];
	return result;
}

- (void)setValue:(NSString*)value_ {
    [self willChangeValueForKey:@"value"];
    [self setPrimitiveValue:value_ forKey:@"value"];
    [self didChangeValueForKey:@"value"];
}

- (BOOL)validateValue:(id*)value_ error:(NSError**)error_ {
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






	

- (JKBasic*)container {
	[self willAccessValueForKey:@"container"];
	JKBasic *result = [self primitiveValueForKey:@"container"];
	[self didAccessValueForKey:@"container"];
	return result;
}

- (void)setContainer:(JKBasic*)value_ {
	[self willChangeValueForKey:@"container"];
	[self setPrimitiveValue:value_ forKey:@"container"];
	[self didChangeValueForKey:@"container"];
}

- (BOOL)validateContainer:(id*)value_ error:(NSError**)error_ {
	return YES;
}

	

@end
