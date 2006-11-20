// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKCoordinates.h instead.

#import <CoreData/CoreData.h>



@class JKTrace;

@class JKParameter;


@interface _JKCoordinates : JKBasic {}

- (NSString*)linkid;
- (void)setLinkid:(NSString*)value_;

- (BOOL)validateLinkid:(id*)value_ error:(NSError**)error_;

- (NSString*)linkref;
- (void)setLinkref:(NSString*)value_;

- (BOOL)validateLinkref:(id*)value_ error:(NSError**)error_;

- (NSString*)valueorder;
- (void)setValueorder:(NSString*)value_;

- (BOOL)validateValueorder:(id*)value_ error:(NSError**)error_;

- (NSString*)units;
- (void)setUnits:(NSString*)value_;

- (BOOL)validateUnits:(id*)value_ error:(NSError**)error_;

- (NSString*)label;
- (void)setLabel:(NSString*)value_;

- (BOOL)validateLabel:(id*)value_ error:(NSError**)error_;



- (JKTrace*)trace;
- (void)setTrace:(JKTrace*)value_;
- (BOOL)validateTrace:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;


@end
