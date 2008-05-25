//
//  JKSearchResult.h
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKLibraryEntry;
@class PKPeakRecord;

@interface PKSearchResult : NSObject <NSCoding> {
    NSNumber *score;
    PKPeakRecord *peak;
//    JKSearchSpectra spectrumType; // 0 = spectrum; 1 = combinedSpectrum
    NSString *jcampString;
    NSURL *libraryHitURI;

    id _libraryHit;
}

- (NSNumber *)deltaRetentionIndex;
- (NSURL *)libraryHitURI;
- (id)libraryHit;
- (void)setLibraryHit:(id)libraryHit;


@property (copy) NSNumber *score;
//@property (copy) NSString *jcampString;
@property (retain) PKPeakRecord *peak;
//@property JKSearchSpectra spectrumType;

@end
