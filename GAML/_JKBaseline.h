// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKBaseline.h instead.

#import <CoreData/CoreData.h>



@class JKParameter;

@class JKPeak;


@interface _JKBaseline : JKBasic {}

- (NSNumber*)startXvalue;
- (void)setStartXvalue:(NSNumber*)value_;

- (double)startXvalueValue;
- (void)setStartXvalueValue:(double)value_;

- (BOOL)validateStartXvalue:(id*)value_ error:(NSError**)error_;

- (NSNumber*)endYvalue;
- (void)setEndYvalue:(NSNumber*)value_;

- (double)endYvalueValue;
- (void)setEndYvalueValue:(double)value_;

- (BOOL)validateEndYvalue:(id*)value_ error:(NSError**)error_;

- (NSNumber*)endXvalue;
- (void)setEndXvalue:(NSNumber*)value_;

- (double)endXvalueValue;
- (void)setEndXvalueValue:(double)value_;

- (BOOL)validateEndXvalue:(id*)value_ error:(NSError**)error_;

- (NSNumber*)startYvalue;
- (void)setStartYvalue:(NSNumber*)value_;

- (double)startYvalueValue;
- (void)setStartYvalueValue:(double)value_;

- (BOOL)validateStartYvalue:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (JKPeak*)peak;
- (void)setPeak:(JKPeak*)value_;
- (BOOL)validatePeak:(id*)value_ error:(NSError**)error_;


@end
