//
//  PKMeasurement.m
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKMeasurement.h"

#import "PKDocument.h"
#import "jk_statistics.h"

@implementation PKMeasurement
- (id)init
{
	self = [super init];
    if (self != nil) {
        uniqueID = GetUUID();
        [self setLabel:NSLocalizedString(@"Untitled Measurement",@"")];
   	}
    return self;
}

- (id)valueForUndefinedKey:(NSString *)key 
{
    if ([[(PKDocument *)[self container] measurementsMetadataKeys] containsObject:key]) {
        return [metadata valueForKey:key];
    }
    return [super valueForKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
    if ([[(PKDocument *)[self container] measurementsMetadataKeys] containsObject:key]) {
        [metadata setValue:value forKey:key];
        return;
    }
    [super setValue:value forUndefinedKey:key];
}

#pragma mark Property synthesization
@synthesize uniqueID;
@synthesize label;
@synthesize metadata;

@end
