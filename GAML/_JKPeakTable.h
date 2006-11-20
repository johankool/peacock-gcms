// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKPeakTable.h instead.

#import <CoreData/CoreData.h>



@class JKYData;

@class JKParameter;

@class JKPeak;


@interface _JKPeakTable : JKBasic {}

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (JKYData*)yData;
- (void)setYData:(JKYData*)value_;
- (BOOL)validateYData:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (void)addPeaksObject:(JKPeak*)value_;
- (void)removePeaksObject:(JKPeak*)value_;
- (NSMutableSet*)peaksSet;


@end
