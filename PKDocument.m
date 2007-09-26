//
//  PKDocument.m
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKDocument.h"

#import "PKGCMSMeasurement.h"
#import "PKMainWindowController.h"

@implementation PKDocument

- (id) init
{
    self = [super init];
    if (self != nil) {
        measurements = [[NSMutableArray alloc] init];
        summaries = [[NSMutableArray alloc] init];
        measurementsMetadataKeys = [[NSMutableArray alloc] init];
  }
    return self;
}

#pragma mark Window Management
- (void)makeWindowControllers 
{
    if (!mainWindowController) {
        mainWindowController = [[PKMainWindowController alloc] init];
    }
 	[self addWindowController:mainWindowController];
}

#pragma mark -


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    return YES;
}

- (BOOL)addMeasurementWithFilePath:(NSString *)filePath atIndex:(int)index
{
    PKGCMSMeasurement *newMeasurement = [[PKGCMSMeasurement alloc] initWithFilePath:filePath];
    [newMeasurement setContainer:self];
    [self insertValue:newMeasurement atIndex:0 inPropertyWithKey:@"measurements"];
    return YES;
}

@synthesize measurements;
@synthesize summaries;
@synthesize metadata;
@synthesize measurementsMetadataKeys;

@end
