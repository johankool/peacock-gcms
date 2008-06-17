//
//  JKSearchResult.h
//  Peacock
//
//  Created by Johan Kool on 24-1-07.
//  Copyright 2007-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
