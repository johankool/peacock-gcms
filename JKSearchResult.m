//
//  JKSearchResult.m
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKSearchResult.h"

#import "JKLibraryEntry.h"
#import "PKPeak.h"
#import "JKLibrary.h"

@implementation JKSearchResult

- (id)init {
    self = [super init];
    if (self != nil) {
        score = [[NSNumber alloc] init];
        libraryHit = [[JKLibraryEntry alloc] init];
        spectrumType = 0;
    }
    return self;
}

- (void)dealloc {
    [score release];
    [libraryHit release];
    [super dealloc];
}


- (NSNumber *)deltaRetentionIndex {
    return [NSNumber numberWithFloat:[[peak retentionIndex] floatValue] - [[libraryHit retentionIndex] floatValue]];
}

- (NSNumber *)score {
	return score;
}
- (void)setScore:(NSNumber *)aScore {
	[score autorelease];
	score = [aScore retain];
}

- (JKLibraryEntry *)libraryHit {
	return libraryHit;
}
- (void)setLibraryHit:(JKLibraryEntry *)aLibraryHit {
	[libraryHit autorelease];
	libraryHit = [aLibraryHit retain];
}

- (PKPeak *)peak {
	return peak;
}
- (void)setPeak:(PKPeak *)aPeak {
	peak = aPeak;
}


#pragma mark Encoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:score forKey:@"score"]; 
		[coder encodeObject:libraryHit forKey:@"libraryHit"]; 
		[coder encodeConditionalObject:peak forKey:@"peak"];         
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
		score = [[coder decodeObjectForKey:@"score"] retain]; 
		libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain]; 
		peak = [coder decodeObjectForKey:@"peak"];
    } 
    return self;
}

@synthesize spectrumType;
@end
