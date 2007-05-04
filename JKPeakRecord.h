// 
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKModelObject.h"

@class JKChromatogram;
@class JKGCMSDocument;
@class JKLibraryEntry;
@class JKSearchResult;
@class JKSpectrum;

@interface JKPeakRecord : JKModelObject <NSCoding> {
    BOOL confirmed;
    BOOL identified;
//    JKChromatogram *chromatogram;
    NSMutableArray *searchResults;
    NSNumber *baselineLeft;
    NSNumber *baselineRight;
    NSString *label;
    NSString *symbol;
    JKSearchResult *identifiedSearchResult;
    int end;
    int peakID;
    int start;
    NSString *uuid;
    
    // Support for reading in old file-format
    id _libraryHit;
    id _score;
    BOOL _needsUpdating;
}

#pragma mark ACTIONS

- (BOOL)confirm;
- (void)discard;
- (BOOL)identifyAs:(JKSearchResult *)searchResult;
- (BOOL)identifyAsLibraryEntry:(JKLibraryEntry *)aLibraryEntry;
- (void)addSearchResult:(JKSearchResult *)searchResult;

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
- (JKSpectrum *)spectrum;
- (JKSpectrum *)combinedSpectrum;
- (NSNumber *)score;
- (NSString *)library;
- (JKLibraryEntry *)libraryHit;
- (JKGCMSDocument *)document;
- (NSString *)model;

#pragma mark ACCESSORS
- (NSString *)uuid;
- (void)setPeakID:(int)inValue;
- (int)peakID;
- (void)setChromatogram:(JKChromatogram *)inValue;
- (JKChromatogram *)chromatogram;

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
- (NSDictionary *)objectInSearchResultsAtIndex:(int)index;
- (void)getSearchResult:(NSDictionary **)someSearchResults range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aSearchResult inSearchResultsAtIndex:(int)index;
- (void)removeObjectFromSearchResultsAtIndex:(int)index;
- (void)replaceObjectInSearchResultsAtIndex:(int)index withObject:(NSDictionary *)aSearchResult;
- (BOOL)validateSearchResult:(NSDictionary **)aSearchResult error:(NSError **)outError;

- (void)setLabel:(NSString *)inValue;
- (NSString *)label;
- (void)setSymbol:(NSString *)inValue;
- (NSString *)symbol;
- (void)setIdentified:(BOOL)inValue;
- (BOOL)identified;
- (void)setConfirmed:(BOOL)inValue;
- (BOOL)confirmed;

- (void)setIdentifiedSearchResult:(id)inValue;
- (id)identifiedSearchResult;

//#pragma mark Support for older formats
//- (void)updateForNewEncoding;
@end
