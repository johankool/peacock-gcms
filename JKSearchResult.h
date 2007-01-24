//
//  JKSearchResult.h
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKLibraryEntry;
@class JKPeakRecord;

@interface JKSearchResult : NSObject <NSCoding> {
    NSNumber *score;
    JKLibraryEntry *libraryHit;
    JKPeakRecord *peak;
}

- (NSNumber *)deltaRetentionIndex;

- (NSNumber *)score;
- (void)setScore:(NSNumber *)inValue;

- (JKLibraryEntry *)libraryHit;
- (void)setLibraryHit:(JKLibraryEntry *)libraryHit;

- (JKPeakRecord *)peak;
- (void)setPeak:(JKPeakRecord *)peak;

@end
