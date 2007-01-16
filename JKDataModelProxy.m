//
//  JKDataModelProxy.m
//  Peacock
//
//  Created by Johan Kool on 22-6-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKDataModelProxy.h"


@implementation JKDataModelProxy

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		peaks = [coder decodeObjectForKey:@"peaks"]; 
		baseline = [coder decodeObjectForKey:@"baseline"]; 
		metadata = [coder decodeObjectForKey:@"metadata"]; 
	} 
    return self;
}

idAccessor(peaks, setPeaks)
idAccessor(baseline, setBaseline)
idAccessor(metadata, setMetadata)

@end
