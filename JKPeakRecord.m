//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKPeakRecord.h"

#import "JKChromatogram.h"
#import "JKGCMSDocument.h"
#import "JKLibraryEntry.h"
#import "JKSearchResult.h"
#import "JKSpectrum.h"

@implementation JKPeakRecord

# pragma mark INITIALIZATION
+ (void)initialize{
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"library"];
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"deltaRetentionIndex"];
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"score"];
    NSArray *startEndArray = [NSArray arrayWithObjects:@"start", @"end", @"baselineLeft", @"baselineRight", nil];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"startTime"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"endTime"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"top"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"topTime"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"retentionIndex"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"surface"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"height"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"spectrum"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"combinedSpectrum"];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"JKPeakRecord: %@ (top: %f)", [self label], [[self topTime] floatValue]];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		searchResults = [[NSMutableArray alloc] init];
		label = @"";
        symbol = @"";
        identified = NO;
        confirmed = NO;
    }
    return self;	
}

#pragma mark ACTIONS

- (BOOL)confirm{
	if ([self identified]) {
//		// Register to undo stack
//		NSUndoManager *undo = [[self document] undoManager];
//		[[undo prepareWithInvocationTarget:self] undoConfirmWithDictionary:[self dictionaryWithValuesForKeys:[NSArray arrayWithObjects:@"confirmed",@"identifiedSearchResult", @"",nil]];
		
		[self setConfirmed:YES];
		[searchResults removeObject:identifiedSearchResult];
		[[self document] redistributedSearchResults:self];
		[searchResults removeAllObjects];
		[searchResults addObject:identifiedSearchResult];
		return YES;		
	} else {
        [self setIdentified:YES];
        [self setConfirmed:YES];
		return NO;
	}
}

- (void)discard{
	[self setIdentified:NO];
	[self setConfirmed:NO];
	[self setLabel:@""];
	[self setSymbol:@""];
	[self setIdentifiedSearchResult:nil];
}

- (BOOL)identifyAs:(id)searchResult{
	[self willChangeValueForKey:@"libraryHit"];
	[self setIdentifiedSearchResult:searchResult];
	// Initial default settings after identification, but can be customized by user later on
	[self setLabel:[searchResult valueForKeyPath:@"libraryHit.name"]];
	[self setSymbol:[searchResult valueForKeyPath:@"libraryHit.symbol"]];
	[self setIdentified:YES];
	[self setConfirmed:NO];
	
	if (![searchResults containsObject:searchResult]) {
		[self willChangeValueForKey:@"searchResultCount"];
		[searchResults insertObject:searchResult atIndex:[searchResults count]];
		[self didChangeValueForKey:@"searchResultCount"];
	}
	[self didChangeValueForKey:@"libraryHit"];
	return YES;
}

- (void)addSearchResult:(id)searchResult{
	if (![searchResults containsObject:searchResult]) {
		[searchResults insertObject:searchResult atIndex:[searchResults count]];
		NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO] autorelease];
		[searchResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
		
		if ([[[searchResults objectAtIndex:0] valueForKey:@"score"] floatValue] >= [[[self document] markAsIdentifiedThreshold] floatValue]) {
			[self identifyAs:[searchResults objectAtIndex:0]];
		}
	}	
}

- (NSUndoManager *)undoManager {
    return [[self document] undoManager];
}

#pragma mark CALCULATED ACCESSORS

- (NSNumber *)deltaRetentionIndex {
	float value = 0.0;
	if (([[self libraryHit] retentionIndex] == nil) | ([[[self libraryHit] retentionIndex] floatValue] == 0.0)) {
		return [NSNumber numberWithFloat:0.0];
	}
	value = [[[self libraryHit] retentionIndex] floatValue] - [[self retentionIndex] floatValue];
    return [NSNumber numberWithFloat:value];
}

- (int)top {
    int top;
    int j;
    float *totalIntensity = [[self chromatogram] totalIntensity];
    top = start;
    for (j=start; j <= end; j++) {
        if (totalIntensity[j] > totalIntensity[top]) {
            top = j;
        }
    }
    return top;
}

- (NSNumber *)topTime {
    float *time = [[self chromatogram] time];
    float topTime;
    int top;
    top = [self top];
    topTime = time[top];
    return [NSNumber numberWithFloat:topTime];
}

- (NSNumber *)retentionIndex {
    float retentionIndex = [[self topTime] floatValue] * [[[self document] retentionIndexSlope] floatValue] + [[[self document] retentionIndexRemainder] floatValue];
    return [NSNumber numberWithFloat:retentionIndex];
}

- (NSNumber *)surface {
    NSAssert(start < end, @"surface: start scan should be before end scan of peak");
    int j;
    float time1, time2, height1, height2;
    float surface = 0.0;
    float *time = [[self chromatogram] time];
    float *totalIntensity = [[self chromatogram] totalIntensity];

    float baselineAtStart = [[self baselineLeft] floatValue];
    float baselineAtEnd = [[self baselineRight] floatValue];
    
    // Calculations needed for height and width
    float a = baselineAtEnd-baselineAtStart;
    float b = time[end]-time[start];
    
    for (j=start; j < end; j++) {
        time1 = time[j];//[[self chromatogram] timeForScan:j];
        time2 = time[j+1];//[[self chromatogram] timeForScan:j+1];
        
        height1 = totalIntensity[j]-(baselineAtStart + (a/b)*(time1-time[start]) );
        height2 = totalIntensity[j+1]-(baselineAtStart + (a/b)*(time2-time[start]) );
        
        if (height1 > height2) {
            surface = surface + (height2 * (time2-time1)) + ((height1-height2) * (time2-time1) * 0.5);
        } else {
            surface = surface + (height1 * (time2-time1)) + ((height2-height1) * (time2-time1) * 0.5);					
        }
    }
    
    return [NSNumber numberWithFloat:surface];
}

- (NSNumber *)normalizedSurface {
    float surface = [[self surface] floatValue];
    float largestPeakSurface = [[self chromatogram] largestPeakSurface];
    return [NSNumber numberWithFloat:surface/largestPeakSurface];
}


- (NSNumber *)height {
    int top = [self top];
    float *time = [[self chromatogram] time];
    float *totalIntensity = [[self chromatogram] totalIntensity];    
    float baselineAtStart = [[self baselineLeft] floatValue];
    float baselineAtEnd = [[self baselineRight] floatValue];
    
    // Calculations needed for height and width
    float a = baselineAtEnd-baselineAtStart;
    float b = time[end] - time[start];
     
    float height = totalIntensity[top]-(baselineAtStart + (a/b)*(time[top]-time[start]) );
    
    return [NSNumber numberWithFloat:height];
}

- (NSNumber *)normalizedHeight {
    float height = [[self height] floatValue];
    float highestPeakHeight = [[self chromatogram] highestPeakHeight];
    return [NSNumber numberWithFloat:height/highestPeakHeight];
}


- (JKSpectrum *)spectrum {
    JKSpectrum *spectrum = [[self document] spectrumForScan:[self top]];
    if (![[self label] isEqualToString:@""]) {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Spectrum for Peak '%@' (#%d)",@""),[self label], [self peakID]]];        
    } else {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Spectrum for Peak #%d",@""), [self peakID]]];        
    }
    return spectrum;
}

- (JKSpectrum *)combinedSpectrum {
    JKSpectrum *spectrum = [[[self document] spectrumForScan:[self top]] spectrumBySubtractingSpectrum:[[[self document] spectrumForScan:[self start]] spectrumByAveragingWithSpectrum:[[self document] spectrumForScan:[self end]]]];
    if (![[self label] isEqualToString:@""]) {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Combined Spectrum for Peak '%@' (#%d)",@""),[self label], [self peakID]]];        
    } else {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Combined Spectrum for Peak #%d",@""), [self peakID]]];        
    }
    return spectrum;
}



#pragma mark ACCESSORS

- (void)setPeakID:(int)inValue {
	peakID = inValue;
}
- (int)peakID {
    return peakID;
}

- (void)setChromatogram:(JKChromatogram *)inValue {
	// Weak link
	chromatogram = inValue;
}
- (JKChromatogram *)chromatogram {
    return chromatogram;
}

- (JKGCMSDocument *)document {
    return [[self chromatogram] document];
}

- (NSNumber *)score {
	return [identifiedSearchResult score];
}


- (void)setLabel:(NSString *)inValue {
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setLabel:)
                                        object:label];
    [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Label",@"Change Peak Label")];
                                                
	[inValue retain];
	[label autorelease];
	label = inValue;
}

- (NSString *)label {
    return label;
}

- (NSString *)model {
    return [[self chromatogram] model];
}

- (void)setSymbol:(NSString *)inValue {
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setSymbol:)
                                        object:symbol];
    [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Symbol",@"Change Peak Symbol")];
    
	[inValue retain];
	[symbol autorelease];
	symbol = inValue;
}

- (NSString *)symbol {
    return symbol;
} 

- (void)setBaselineLeft:(NSNumber *)inValue {
	[inValue retain];
	[baselineLeft autorelease];
	baselineLeft = inValue;
}

- (NSNumber *)baselineLeft{
    return baselineLeft;
}

- (void)setBaselineRight:(NSNumber *)inValue {
	[inValue retain];
	[baselineRight autorelease];
	baselineRight = inValue;
}

- (NSNumber *)baselineRight {
    return baselineRight;
}

- (void)setStart:(int)inValue {
	start = inValue;
}

- (int)start {
    return start;
}

- (NSNumber *)startTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:start]];
}

- (void)setEnd:(int)inValue {
	end = inValue;
}

- (int)end {
    return end;
}

- (NSNumber *)endTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:end]];
}

- (void)setIdentified:(BOOL)inValue {
	identified = inValue;
}

- (BOOL)identified {
    return identified;
}

- (void)setConfirmed:(BOOL)inValue {
	confirmed = inValue;
}

- (BOOL)confirmed {
    return confirmed;
}

- (NSString *)library {
	return [[NSFileManager defaultManager] displayNameAtPath:[[identifiedSearchResult library] fullPath]];
}

- (JKLibraryEntry *)libraryHit {
	return [identifiedSearchResult libraryHit];
}

- (void)setIdentifiedSearchResult:(id)inValue{
	[inValue retain];
	[identifiedSearchResult autorelease];
	identifiedSearchResult = inValue;
	
}
- (id)identifiedSearchResult{
	return identifiedSearchResult;
}

// Mutable To-Many relationship searchResults
- (NSMutableArray *)searchResults {
	return searchResults;
}

- (void)setSearchResults:(NSMutableArray *)inValue {
    [inValue retain];
    [searchResults release];
    searchResults = inValue;
}

- (int)countOfSearchResults {
    return [[self searchResults] count];
}

- (NSDictionary *)objectInSearchResultsAtIndex:(int)index {
    return [[self searchResults] objectAtIndex:index];
}

- (void)getSearchResult:(NSDictionary **)someSearchResults range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [searchResults getObjects:someSearchResults range:inRange];
}

- (void)insertObject:(NSDictionary *)aSearchResult inSearchResultsAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Search Result",@"")];
	}
	
	// Add aSearchResult to the array searchResults
	[searchResults insertObject:aSearchResult atIndex:index];
}

- (void)removeObjectFromSearchResultsAtIndex:(int)index
{
	NSDictionary *aSearchResult = [searchResults objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aSearchResult inSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Search Result",@"")];
	}
	
	// Remove the peak from the array
	[searchResults removeObjectAtIndex:index];
}

- (void)replaceObjectInSearchResultsAtIndex:(int)index withObject:(NSDictionary *)aSearchResult
{
	NSDictionary *replacedSearchResult = [searchResults objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedSearchResult];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Search Result",@"")];
	}
	
	// Replace the peak from the array
	[searchResults replaceObjectAtIndex:index withObject:aSearchResult];
}

- (BOOL)validateSearchResult:(NSDictionary **)aSearchResult error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end searchResults



#pragma mark NSCODING

- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeInt:5 forKey:@"version"];
		[coder encodeObject:chromatogram forKey:@"chromatogram"];
		[coder encodeInt:peakID forKey:@"peakID"];
		[coder encodeInt:start forKey:@"start"];
        [coder encodeInt:end forKey:@"end"];
		[coder encodeObject:baselineLeft forKey:@"baselineLeft"];
        [coder encodeObject:baselineRight forKey:@"baselineRight"];
        [coder encodeObject:label forKey:@"label"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeBool:identified forKey:@"identified"];
		[coder encodeBool:confirmed forKey:@"confirmed"];
		[coder encodeObject:identifiedSearchResult forKey:@"identifiedSearchResult"];
		[coder encodeObject:searchResults forKey:@"searchResults"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		int version = [coder decodeIntForKey:@"version"];
        if (version >= 5) {
            chromatogram = [coder decodeObjectForKey:@"chromatogram"];            
            peakID = [coder decodeIntForKey:@"peakID"];
            start = [coder decodeIntForKey:@"start"];
            end = [coder decodeIntForKey:@"end"];
            baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
            baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
        } else {
            chromatogram = [[[coder decodeObjectForKey:@"document"] chromatograms] objectAtIndex:0];
            // Support for reading in old file-format
            if (chromatogram == nil) {
                _needsUpdating = YES;
                _libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain];
                _score = [[coder decodeObjectForKey:@"score"] retain];
            }
            peakID = [[coder decodeObjectForKey:@"peakID"] intValue];
            start = [[coder decodeObjectForKey:@"start"] intValue];
            end = [[coder decodeObjectForKey:@"end"] intValue];
            // Support for reading in old file-format
            if (version < 3) {
                baselineLeft = [[coder decodeObjectForKey:@"baselineL"] retain];
                baselineRight = [[coder decodeObjectForKey:@"baselineR"] retain];
            } else {
                baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
                baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
            }
        }
        label = [[coder decodeObjectForKey:@"label"] retain];
		symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
		confirmed = [coder decodeBoolForKey:@"confirmed"];
		identifiedSearchResult = [[coder decodeObjectForKey:@"identifiedSearchResult"] retain];
		searchResults = [[coder decodeObjectForKey:@"searchResults"] retain];
	} 
    return self;
}

- (void)updateForNewEncoding {
    if (_needsUpdating) {
        // A bit of a hack really
        JKGCMSDocument *document = [[NSDocumentController sharedDocumentController] currentDocument];
        NSAssert(document != nil, @"updateForNewEncoding - No document found");
        chromatogram = [[document chromatograms] objectAtIndex:0];

        searchResults = [[NSMutableArray alloc] init];

        if (identified && ((_score != nil) && (_libraryHit != nil))) {
            NSMutableDictionary *searchResult = [[NSMutableDictionary alloc] init];
			[searchResult setValue:_score forKey:@"score"];
			[searchResult setValue:_libraryHit forKey:@"libraryHit"];

            [self setIdentifiedSearchResult:searchResult];
            // Initial default settings after identification, but can be customized by user later on
            [self setSymbol:[searchResult valueForKeyPath:@"libraryHit.symbol"]];
            
            if (![searchResults containsObject:searchResult]) {
                [searchResults insertObject:searchResult atIndex:[searchResults count]];
            }            
			[searchResult release];
        }
    }
}

@end
