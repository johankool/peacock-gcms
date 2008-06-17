// 
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
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

#import "PKModelObject.h"
#import "PKTargetObjectProtocol.h"

@class PKChromatogram;
@class PKGCMSDocument;
@class PKLibraryEntry;
@class PKManagedLibraryEntry;
@class PKSearchResult;
@class PKSpectrum;

@interface PKPeakRecord : PKModelObject <NSCoding, PKTargetObjectProtocol> {
    BOOL confirmed;
    BOOL identified;
//    PKChromatogram *chromatogram;
    NSMutableArray *searchResults;
    NSNumber *baselineLeft;
    NSNumber *baselineRight;
    NSString *label;
    NSString *symbol;
    PKSearchResult *identifiedSearchResult;
    int end;
    int peakID;
    int start;
    NSString *uuid;
    BOOL flagged;
    
    // Support for reading in old file-format
    id _libraryHit;
    id _score;
    BOOL _needsUpdating;
}

#pragma mark ACTIONS

- (BOOL)confirm;
- (void)discard;
- (BOOL)identifyAsSearchResult:(PKSearchResult *)searchResult;
- (BOOL)identifyAndConfirmAsSearchResult:(PKSearchResult *)searchResult;
- (PKSearchResult *)addSearchResultForLibraryEntry:(PKManagedLibraryEntry *)aLibraryEntry;
- (PKSearchResult *)addSearchResult:(PKSearchResult *)searchResult;
- (PKLibraryEntry *)libraryEntryRepresentation;
- (BOOL)isCompound:(NSString *)compoundString;

#pragma mark CALCULATED ACCESSORS

- (NSNumber *)deltaRetentionIndex;
- (NSNumber *)startTime;
- (NSNumber *)endTime;
- (int)top;
- (NSNumber *)topTime;
- (NSNumber *)retentionIndex;
- (NSNumber *)startRetentionIndex;
- (NSNumber *)endRetentionIndex;
- (NSNumber *)height;
- (NSNumber *)normalizedHeight;
- (NSNumber *)surface;
- (NSNumber *)normalizedSurface;
- (NSNumber *)width;
- (PKSpectrum *)spectrum;
- (PKSpectrum *)combinedSpectrum;
- (NSNumber *)score;
- (NSString *)library;
- (PKLibraryEntry *)libraryHit;
- (PKGCMSDocument *)document;
- (NSString *)model;

#pragma mark ACCESSORS
- (NSString *)uuid;
- (void)setPeakID:(int)inValue;
- (int)peakID;
- (void)setChromatogram:(PKChromatogram *)inValue;
- (PKChromatogram *)chromatogram;

- (void)setStart:(int)inValue;
- (int)start;
- (void)setEnd:(int)inValue;
- (int)end;

- (void)setBaselineLeft:(NSNumber *)inValue;
- (NSNumber *)baselineLeft;
- (void)setBaselineRight:(NSNumber *)inValue;
- (NSNumber *)baselineRight;

// Value validation
- (BOOL)validateBaselineLeft:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateBaselineRight:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateStart:(id *)ioValue error:(NSError **)outError;
- (BOOL)validateEnd:(id *)ioValue error:(NSError **)outError;
                
// Mutable To-Many relationship searchResult
- (NSMutableArray *)searchResults;
- (void)setSearchResults:(NSMutableArray *)inValue;
- (int)countOfSearchResults;
- (PKSearchResult *)objectInSearchResultsAtIndex:(int)index;
- (void)getSearchResult:(PKSearchResult **)someSearchResults range:(NSRange)inRange;
- (void)insertObject:(PKSearchResult *)aSearchResult inSearchResultsAtIndex:(int)index;
- (void)removeObjectFromSearchResultsAtIndex:(int)index;
- (void)replaceObjectInSearchResultsAtIndex:(int)index withObject:(PKSearchResult *)aSearchResult;
- (BOOL)validateSearchResult:(PKSearchResult **)aSearchResult error:(NSError **)outError;

- (void)setLabel:(NSString *)inValue;
- (NSString *)label;
- (void)setSymbol:(NSString *)inValue;
- (NSString *)symbol;
- (void)setIdentified:(BOOL)inValue;
- (BOOL)identified;
- (void)setConfirmed:(BOOL)inValue;
- (BOOL)confirmed;
- (void)setFlagged:(BOOL)inValue;
- (BOOL)flagged;

- (void)setIdentifiedSearchResult:(PKSearchResult *)inValue;
- (PKSearchResult *)identifiedSearchResult;

@property (retain) id _score;
@property BOOL _needsUpdating;
@property (retain) id _libraryHit;
@property (retain,getter=uuid) NSString *uuid;
@end
