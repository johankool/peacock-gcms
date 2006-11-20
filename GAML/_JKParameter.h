// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to JKParameter.h instead.

#import <CoreData/CoreData.h>



@class JKBasic;


@interface _JKParameter : NSManagedObject {}

- (NSString*)value;
- (void)setValue:(NSString*)value_;

- (BOOL)validateValue:(id*)value_ error:(NSError**)error_;

- (NSString*)name;
- (void)setName:(NSString*)value_;

- (BOOL)validateName:(id*)value_ error:(NSError**)error_;

- (NSString*)group;
- (void)setGroup:(NSString*)value_;

- (BOOL)validateGroup:(id*)value_ error:(NSError**)error_;

- (NSString*)label;
- (void)setLabel:(NSString*)value_;

- (BOOL)validateLabel:(id*)value_ error:(NSError**)error_;



- (JKBasic*)container;
- (void)setContainer:(JKBasic*)value_;
- (BOOL)validateContainer:(id*)value_ error:(NSError**)error_;


@end
