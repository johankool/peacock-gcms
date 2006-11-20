// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKPeak.h instead.

#import <CoreData/CoreData.h>



@class JKPeakTable;

@class JKParameter;

@class JKBaseline;


@interface _JKPeak : JKBasic {}

- (NSNumber*)peakXvalue;
- (void)setPeakXvalue:(NSNumber*)value_;

- (double)peakXvalueValue;
- (void)setPeakXvalueValue:(double)value_;

- (BOOL)validatePeakXvalue:(id*)value_ error:(NSError**)error_;

- (NSString*)group;
- (void)setGroup:(NSString*)value_;

- (BOOL)validateGroup:(id*)value_ error:(NSError**)error_;

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

- (NSNumber*)number;
- (void)setNumber:(NSNumber*)value_;

- (long)numberValue;
- (void)setNumberValue:(long)value_;

- (BOOL)validateNumber:(id*)value_ error:(NSError**)error_;

- (NSNumber*)peakYvalue;
- (void)setPeakYvalue:(NSNumber*)value_;

- (double)peakYvalueValue;
- (void)setPeakYvalueValue:(double)value_;

- (BOOL)validatePeakYvalue:(id*)value_ error:(NSError**)error_;



- (JKPeakTable*)peakTable;
- (void)setPeakTable:(JKPeakTable*)value_;
- (BOOL)validatePeakTable:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (JKBaseline*)baseline;
- (void)setBaseline:(JKBaseline*)value_;
- (BOOL)validateBaseline:(id*)value_ error:(NSError**)error_;


@end
