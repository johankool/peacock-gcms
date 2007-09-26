//
//  JKDataModelProxy.m
//  Peacock
//
//  Created by Johan Kool on 22-6-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
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

- (void)dealloc {
    [peaks release];
    [baseline release];
    [metadata release];
    [super dealloc];
}
idAccessor(peaks, setPeaks)
idAccessor(baseline, setBaseline)
idAccessor(metadata, setMetadata)

@end
