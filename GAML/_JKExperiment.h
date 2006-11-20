// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKExperiment.h instead.

#import <CoreData/CoreData.h>



@class JKParameter;

@class JKTrace;

@class JKGAML;


@interface _JKExperiment : JKBasic {}

- (NSDate*)collectDate;
- (void)setCollectDate:(NSDate*)value_;

- (BOOL)validateCollectDate:(id*)value_ error:(NSError**)error_;

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (void)addTracesObject:(JKTrace*)value_;
- (void)removeTracesObject:(JKTrace*)value_;
- (NSMutableSet*)tracesSet;



- (JKGAML*)gaml;
- (void)setGaml:(JKGAML*)value_;
- (BOOL)validateGaml:(id*)value_ error:(NSError**)error_;


@end
