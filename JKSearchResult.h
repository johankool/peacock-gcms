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
    int spectrumType; // 0 = spectrum; 1 = combinedSpectrum
}

- (NSNumber *)deltaRetentionIndex;

- (NSNumber *)score;
- (void)setScore:(NSNumber *)inValue;

- (JKLibraryEntry *)libraryHit;
- (void)setLibraryHit:(JKLibraryEntry *)libraryHit;

- (JKPeakRecord *)peak;
- (void)setPeak:(JKPeakRecord *)aPeak;

@property (assign,getter=peak,setter=setPeak:) JKPeakRecord *peak;
@property int spectrumType;
@end
