//
//  JKSearchResult.h
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKLibraryEntry;
@class PKPeak;

@interface JKSearchResult : NSObject <NSCoding> {
    NSNumber *score;
    JKLibraryEntry *libraryHit;
    PKPeak *peak;
    int spectrumType; // 0 = spectrum; 1 = combinedSpectrum
}

- (NSNumber *)deltaRetentionIndex;

- (NSNumber *)score;
- (void)setScore:(NSNumber *)inValue;

- (JKLibraryEntry *)libraryHit;
- (void)setLibraryHit:(JKLibraryEntry *)libraryHit;

- (PKPeak *)peak;
- (void)setPeak:(PKPeak *)aPeak;

@property int spectrumType;
@property (assign,getter=peak,setter=setPeak:) PKPeak *peak;
@end
