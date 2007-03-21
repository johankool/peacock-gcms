//
//  JKSearchResult.m
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKSearchResult.h"

#import "JKLibraryEntry.h"
#import "JKPeakRecord.h"
#import "JKLibrary.h"
#import "BDAlias.h"

@implementation JKSearchResult

- (id)init {
    self = [super init];
    if (self != nil) {
        score = [[NSNumber alloc] init];
        libraryHit = [[JKLibraryEntry alloc] init];
//        peak = [[JKPeakRecord alloc] init];
    }
    return self;
}

- (void)dealloc {
    [score release];
    [libraryHit release];
//    [peak release];
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

- (JKPeakRecord *)peak {
	return peak;
}
- (void)setPeak:(JKPeakRecord *)aPeak {
//	[peak autorelease];
	peak = aPeak;
}

- (BDAlias *)library {
    return library;
}
- (void)setLibrary:(BDAlias *)aLibrary {
    [library autorelease];
	library = [aLibrary retain];
}

#pragma mark Encoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:score forKey:@"score"]; 
		[coder encodeObject:libraryHit forKey:@"libraryHit"]; 
		[coder encodeConditionalObject:peak forKey:@"peak"];         
		[coder encodeObject:library forKey:@"library"];         
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
		score = [[coder decodeObjectForKey:@"score"] retain]; 
		libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain]; 
		peak = [coder decodeObjectForKey:@"peak"]; 
        
//        library = [[coder decodeObjectForKey:@"library"] retain];             
        // Sometimes BDAlias gets expanded so if we want to have the alias instead of the docuemnt we need to create it again
        id temp = [coder decodeObjectForKey:@"library"];
        if (temp) {
//            JKLogDebug(@"%@",[temp description]);
            if ([temp isKindOfClass:[BDAlias class]]) {
                library = [[coder decodeObjectForKey:@"library"] retain];             
            } else if ([temp isKindOfClass:[JKLibrary class]]) {
                library = [[BDAlias aliasWithPath:[temp fileName]] retain];
                if(!library) {
                    JKLogDebug(@"unsuccessful in creating alias"); 
                }
            } else {
                JKLogDebug(@"Something unexpected got returned");
            }            
        } else {
            //JKLogDebug(@"Nothing got returned for library?!");
        }
    } 
    return self;
}

@end
