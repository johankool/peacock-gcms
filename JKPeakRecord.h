//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKGCMSDocument;
@class JKSpectrum;
@class JKLibraryEntry;

@interface JKPeakRecord : NSObject <NSCoding> {
    NSNumber *peakID;
	JKGCMSDocument *document;
	
	// Set during peak identification
	// number = actual scan number
    NSNumber *start;
    NSNumber *end;
    NSNumber *top;
 
	// number = total intensity units (defaults to arbitrary)
    NSNumber *height;
    NSNumber *baselineLeft;
	NSNumber *baselineRight;

	// number = time axis units (defaults to seconds)
	NSNumber *topTime;
    NSNumber *baselineLeftTime;
    NSNumber *baselineRightTime;

	// number = retention index
	NSNumber *retentionIndex;

	// number = total intensity units * time axis units
    NSNumber *surface;

	// relative to highest/largest peak
	NSNumber *normalizedSurface;
	NSNumber *normalizedHeight;
	
	// Non-normalized representative spectrum for peak
	JKSpectrum *spectrum;
	
	// Set during search
	NSMutableArray *searchResults;
	 
	// Set during compound identification
	NSString *label;
	NSString *symbol;
	BOOL identified;
	BOOL confirmed;
	id identifiedSearchResult;
//	NSNumber *score;
//	NSString *library;
//	JKLibraryEntry *libraryHit;
}

#pragma mark ACTIONS

- (BOOL)confirm;
- (void)discard;
- (BOOL)identifyAs:(id)searchResult;
- (void)addSearchResult:(id)searchResult;

#pragma mark CALCULATED ACCESSORS

//- (NSNumber *)normalizedSurface;
//- (NSNumber *)normalizedHeight;
- (NSNumber *)deltaRetentionIndex;

#pragma mark ACCESSORS

- (void)setPeakID:(NSNumber *)inValue;
- (NSNumber *)peakID;
- (void)setDocument:(JKGCMSDocument *)inValue;
- (JKGCMSDocument *)document;

- (void)setStart:(NSNumber *)inValue;
- (NSNumber *)start;
- (void)setEnd:(NSNumber *)inValue;
- (NSNumber *)end;
- (void)setTop:(NSNumber *)inValue;
- (NSNumber *)top;

- (void)setHeight:(NSNumber *)inValue;
- (NSNumber *)height;
- (void)setBaselineLeft:(NSNumber *)inValue;
- (NSNumber *)baselineLeft;
- (void)setBaselineRight:(NSNumber *)inValue;
- (NSNumber *)baselineRight;

- (void)setTopTime:(NSNumber *)inValue;
- (NSNumber *)topTime;
- (void)setBaselineLeftTime:(NSNumber *)inValue;
- (NSNumber *)baselineLeftTime;
- (void)setBaselineRightTime:(NSNumber *)inValue;
- (NSNumber *)baselineRightTime;

- (void)setRetentionIndex:(NSNumber *)inValue;
- (NSNumber *)retentionIndex;

- (void)setSurface:(NSNumber *)inValue;
- (NSNumber *)surface;

- (void)setNormalizedHeight:(NSNumber *)inValue;
- (NSNumber *)normalizedHeight;
- (void)setNormalizedSurface:(NSNumber *)inValue;
- (NSNumber *)normalizedSurface;

- (void)setSpectrum:(JKSpectrum *)inValue;
- (JKSpectrum *)spectrum;

- (NSMutableArray *)searchResults;
- (void)setSearchResults:(NSMutableArray *)inValue;
- (void)insertObject:(NSDictionary *)searchResult inSearchResultsAtIndex:(int)index;
- (void)removeObjectFromSearchResultsAtIndex:(int)index;


- (JKLibraryEntry *)libraryHit;
- (void)setLabel:(NSString *)inValue;
- (NSString *)label;
- (void)setSymbol:(NSString *)inValue;
- (NSString *)symbol;
- (void)setIdentified:(BOOL)inValue;
- (BOOL)identified;
- (void)setConfirmed:(BOOL)inValue;
- (BOOL)confirmed;
//- (void)setScore:(NSNumber *)inValue;
- (NSNumber *)score;
//- (void)setLibrary:(NSString *)inValue;
- (NSString *)library;
- (void)setIdentifiedSearchResult:(id)inValue;
- (id)identifiedSearchResult;

@end
