//
//  BooleanToStringTransformer.m
//  Peacock
//
//  Created by Johan Kool on 4-5-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKBooleanToStringTransformer.h"

@implementation PKBooleanToStringTransformer

+ (Class)transformedValueClass {
    return [NSNumber class];
}

+ (BOOL)allowsReverseTransformation {
    return NO;
}

- (id)transformedValue:(id)aValue {
    if (!aValue) {
        return @"-";
    } else if ([aValue intValue] == 0) {
    	return NSLocalizedString(@"No", @"");
    } else if ([aValue intValue] == 1) {
     	return NSLocalizedString(@"Yes", @"");
    } else {
        return @"-";
    }
}

@end
