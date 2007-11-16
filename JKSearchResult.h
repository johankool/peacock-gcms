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
    JKPeakRecord *peak;
//    JKSearchSpectra spectrumType; // 0 = spectrum; 1 = combinedSpectrum
    NSString *jcampString;
    NSURL *libraryHitURI;

    id _libraryHit;
}

- (NSNumber *)deltaRetentionIndex;

- (id)libraryHit;
- (void)setLibraryHit:(id)libraryHit;


@property (copy) NSNumber *score;
//@property (copy) NSString *jcampString;
@property (retain) JKPeakRecord *peak;
//@property JKSearchSpectra spectrumType;

@end
