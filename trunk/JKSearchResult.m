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

@implementation JKSearchResult

- (id)init {
    self = [super init];
    if (self != nil) {
 //       score = [[NSNumber alloc] init];
       libraryHit = nil;
        spectrumType = 0;
    }
    return self;
}

- (void)dealloc {
//    [score release];
//    [libraryHit release];
    [super dealloc];
}


- (NSNumber *)deltaRetentionIndex {
    return [NSNumber numberWithFloat:[[peak retentionIndex] floatValue] - [[libraryHit retentionIndex] floatValue]];
}

//- (NSNumber *)score {
//	return score;
//}
//- (void)setScore:(NSNumber *)aScore {
//	[score autorelease];
//	score = [aScore retain];
//}
//
- (JKLibraryEntry *)libraryHit {
	return libraryHit;
}
//- (void)setLibraryHit:(JKLibraryEntry *)aLibraryHit {
//	[libraryHit autorelease];
//	libraryHit = [aLibraryHit retain];
//}
//
//- (JKPeakRecord *)peak {
//	return peak;
//}
//- (void)setPeak:(JKPeakRecord *)aPeak {
//	peak = aPeak;
//}


#pragma mark Encoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:score forKey:@"score"]; 
		[coder encodeObject:libraryHit forKey:@"libraryHit"]; 
		[coder encodeConditionalObject:peak forKey:@"peak"];         
//        [coder encodeInt:2 forKey:@"version"];
//		[coder encodeObject:score forKey:@"score"]; 
//		[coder encodeObject:libraryHit forKey:@"libraryHit"]; 
//		[coder encodeObject:libraryHitURI forKey:@"libraryHitURI"]; 
//		[coder encodeConditionalObject:peak forKey:@"peak"];         
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        int version = [coder decodeIntForKey:@"version"];
        if (version < 2) {
            score = [[coder decodeObjectForKey:@"score"] retain]; 
            libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain]; 
            peak = [coder decodeObjectForKey:@"peak"]; 
//            libraryHitURI = nil;
//         } else {
//            score = [[coder decodeObjectForKey:@"score"] retain]; 
//            libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain]; 
//            peak = [coder decodeObjectForKey:@"peak"];
//            libraryHitURI = [[coder decodeObjectForKey:@"libraryHitURI"] retain];
        }
//        if (libraryHitURI) {
//            NSManagedObjectContext *moc = [[[NSApp delegate] library] managedObjectContext];
//            NSManagedObjectID *mid = [[moc persistentStoreCoordinator] managedObjectIDForURIRepresentation:libraryHitURI];
//            if (mid) {
//                libraryHit = [moc objectRegisteredForID:mid];
//                if (libraryHit) {
//                    [self setLibraryHit:libraryHit];
//                }
//            }            
//        } else {
//            // Try to find it?
//
//        }
    } 
    return self;
}
@synthesize score;
@synthesize libraryHit;
@synthesize peak;
@synthesize spectrumType;
@end
