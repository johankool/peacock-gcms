// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKTrace.h instead.

#import <CoreData/CoreData.h>



@class JKCoordinates;

@class JKData;

@class JKParameter;

@class JKExperiment;


@interface _JKTrace : JKBasic {}

- (NSString*)technique;
- (void)setTechnique:(NSString*)value_;

- (BOOL)validateTechnique:(id*)value_ error:(NSError**)error_;

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;



- (void)addCoordinatesObject:(JKCoordinates*)value_;
- (void)removeCoordinatesObject:(JKCoordinates*)value_;
- (NSMutableSet*)coordinatesSet;



- (void)addXDataObject:(JKData*)value_;
- (void)removeXDataObject:(JKData*)value_;
- (NSMutableSet*)xDataSet;



- (void)addParametersObject:(JKParameter*)value_;
- (void)removeParametersObject:(JKParameter*)value_;
- (NSMutableSet*)parametersSet;



- (JKExperiment*)experiment;
- (void)setExperiment:(JKExperiment*)value_;
- (BOOL)validateExperiment:(id*)value_ error:(NSError**)error_;


@end
