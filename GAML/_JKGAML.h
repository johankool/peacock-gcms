// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKGAML.h instead.

#import <CoreData/CoreData.h>



@class JKParameter;

@class JKExperiment;


@interface _JKGAML : JKBasic {}

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

- (NSString*)version;
- (void)setVersion:(NSString*)value_;

- (BOOL)validateVersion:(id*)value_ error:(NSError**)error_;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (void)addExperimentsObject:(JKExperiment*)value_;
- (void)removeExperimentsObject:(JKExperiment*)value_;
- (NSMutableSet*)experimentsSet;


@end
