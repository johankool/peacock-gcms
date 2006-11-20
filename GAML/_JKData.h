// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKData.h instead.

#import <CoreData/CoreData.h>



@class JKTrace;

@class JKParameter;


@interface _JKData : JKBasic {}

- (NSString*)units;
- (void)setUnits:(NSString*)value_;

- (BOOL)validateUnits:(id*)value_ error:(NSError**)error_;

- (NSString*)byteOrder;
- (void)setByteOrder:(NSString*)value_;

- (BOOL)validateByteOrder:(id*)value_ error:(NSError**)error_;

- (NSData*)values;
- (void)setValues:(NSData*)value_;

- (BOOL)validateValues:(id*)value_ error:(NSError**)error_;

- (NSString*)label;
- (void)setLabel:(NSString*)value_;

- (BOOL)validateLabel:(id*)value_ error:(NSError**)error_;

- (NSString*)format;
- (void)setFormat:(NSString*)value_;

- (BOOL)validateFormat:(id*)value_ error:(NSError**)error_;



- (JKTrace*)trace;
- (void)setTrace:(JKTrace*)value_;
- (BOOL)validateTrace:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;


@end
