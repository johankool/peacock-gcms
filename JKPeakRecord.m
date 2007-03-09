//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKPeakRecord.h"

#import "BDAlias.h"
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
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"normalizedSurface"];
	[self setKeys:startEndArray triggerChangeNotificationsForDependentKey:@"normalizedHeight"];
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
		[self setConfirmed:YES];
        
		[searchResults removeObject:identifiedSearchResult];
		[[self document] redistributedSearchResults:self];
		[searchResults removeAllObjects];
		[searchResults addObject:identifiedSearchResult];
		return YES;		
    } else if ([searchResults count] > 0) {
        [self identifyAs:[searchResults objectAtIndex:0]];
        [self setIdentified:YES];
        [self setConfirmed:YES];
        
		[searchResults removeObject:identifiedSearchResult];
		[[self document] redistributedSearchResults:self];
		[searchResults removeAllObjects];
		[searchResults addObject:identifiedSearchResult];
        return YES;
	} else {
        // Allow this to mark a peak as confirmed with having the proper library entry
        [self setIdentified:YES];
        [self setConfirmed:YES];
        JKLogWarning(@"Peak with label '%@' was confirmed without being identified first.", [self label]);
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

- (NSNumber *)startRetentionIndex {
    float retentionIndex = [[self startTime] floatValue] * [[[self document] retentionIndexSlope] floatValue] + [[[self document] retentionIndexRemainder] floatValue];
    return [NSNumber numberWithFloat:retentionIndex];
}

- (NSNumber *)endRetentionIndex {
    float retentionIndex = [[self endTime] floatValue] * [[[self document] retentionIndexSlope] floatValue] + [[[self document] retentionIndexRemainder] floatValue];
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
    [spectrum setPeak:self];
    return spectrum;
}

- (JKSpectrum *)combinedSpectrum {
    JKSpectrum *spectrum = [[[self document] spectrumForScan:[self top]] spectrumBySubtractingSpectrum:[[[self document] spectrumForScan:[self start]] spectrumByAveragingWithSpectrum:[[self document] spectrumForScan:[self end]]]];
    if ((![[self label] isEqualToString:@""]) && ([self label])) {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Combined Spectrum for Peak '%@' (#%d)",@""),[self label], [self peakID]]];        
    } else {
        [spectrum setModel:[NSString stringWithFormat:NSLocalizedString(@"Combined Spectrum for Peak #%d",@""), [self peakID]]];        
    }
    [spectrum setPeak:self];
    return spectrum;
}

- (NSNumber *)width {
    return [NSNumber numberWithInt:end-start];
}


#pragma mark ACCESSORS

- (void)setPeakID:(int)inValue {
    [[[self undoManager] prepareWithInvocationTarget:self] setPeakID:peakID];
	if (![[self undoManager] isUndoing]) {
        [[self undoManager] setActionName:NSLocalizedString(@"Change Peak ID",@"Change Peak ID")];
    }
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
    if (identifiedSearchResult) {
        return [identifiedSearchResult score];
    } else if ([searchResults count] > 0){
        return [[searchResults objectAtIndex:0] score];
    } else {
        return nil;
    }
}


- (void)setLabel:(NSString *)inValue {
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setLabel:)
                                        object:label];
    if (![[self undoManager] isUndoing]) {
        [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Label",@"Change Peak Label")];
    }
    
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
    if (![[self undoManager] isUndoing]) {
        [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Symbol",@"Change Peak Symbol")];
    }
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

- (NSNumber *)baselineLeft {
    return baselineLeft;
}

- (BOOL)validateBaselineLeft:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        // trap this in setNilValueForKey
        // alternative might be to create new NSNumber with value 0 here
        return YES;
    }
    float *intensities = [[self chromatogram] totalIntensity];
    if ([*ioValue floatValue] > intensities[start]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to big error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be smaller than the value of the intensity at scan %d. Enter a value smaller than or equal to %g.",@"baseline to big error"),[self start],intensities[start]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:5
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue floatValue] < 0.0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be larger than or equal to 0.",@"baseline to small error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:6
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setBaselineRight:(NSNumber *)inValue {
	[inValue retain];
	[baselineRight autorelease];
	baselineRight = inValue;
}

- (NSNumber *)baselineRight {
    return baselineRight;
}

- (BOOL)validateBaselineRight:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        // trap this in setNilValueForKey
        // alternative might be to create new NSNumber with value 0 here
        return YES;
    }
    float *intensities = [[self chromatogram] totalIntensity];
    if ([*ioValue floatValue] > intensities[end]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to big error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be smaller than the value of the intensity at scan %d. Enter a value smaller than or equal to %g.",@"baseline to big error"),[self end],intensities[end]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:7
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue floatValue] < 0.0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be larger than or equal to 0.",@"baseline to small error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:8
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setStart:(int)inValue {
	start = inValue;
}

- (int)start {
    return start;
}

- (BOOL)validateStart:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        // trap this in setNilValueForKey
        // alternative might be to create new NSNumber with value 0 here
        return YES;
    }
    if ([*ioValue intValue] >= [self end]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for start scan",@"start to big error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for start scan should be smaller than the value for the end scan. Enter a value smaller than %d.",@"start to big error"),[self end]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:1
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue intValue] < 0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for start scan",@"start to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for start scan should be larger than or equal to 0.",@"start to small error"),[self end]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:2
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
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

- (BOOL)validateEnd:(id *)ioValue error:(NSError **)outError {
    if (*ioValue == nil) {
        // trap this in setNilValueForKey
        // alternative might be to create new NSNumber with value 0 here
        return YES;
    }
    if ([*ioValue intValue] <= [self start]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for end scan",@"end to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for end scan should be higher than the value for the start scan. Enter a value higher than %d.",@"end to small error"),[self start]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:3
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue intValue] >= [[self chromatogram] numberOfPoints]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for end scan",@"end to big error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for end scan should be smaller than the number of scans in the chromatogram. Enter a value smaller than %d.",@"end to small error"),[[self chromatogram] numberOfPoints]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock Peak domain"
                                                     code:4
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
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
    if ([coder allowsKeyedCoding]) {
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
    if ([coder allowsKeyedCoding]) {
		int version = [coder decodeIntForKey:@"version"];
//        JKLogDebug(@"peak version %d", version);
        switch (version) {
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
                chromatogram = [[[[(NSKeyedArchiver *)coder delegate] chromatograms] objectAtIndex:0] retain];
                NSAssert(chromatogram, @"peak should have chromatogram");
                [chromatogram insertObject:self inPeaksAtIndex:[[chromatogram peaks] count]];
                peakID = [[coder decodeObjectForKey:@"peakID"] intValue];
                start = [[coder decodeObjectForKey:@"start"] intValue];
                end = [[coder decodeObjectForKey:@"end"] intValue];
                 
                searchResults = [[NSMutableArray alloc] init];
                NSArray *oldSearchResults = [coder decodeObjectForKey:@"searchResults"];
                NSEnumerator *resultsEnum = [oldSearchResults objectEnumerator];
                NSDictionary *result;

                while ((result = [resultsEnum nextObject]) != nil) {
                	JKSearchResult *newResult = [[JKSearchResult alloc] init];
                    [newResult setPeak:self];
                    [newResult setScore:[result valueForKey:@"score"]];
                    [newResult setLibraryHit:[result valueForKey:@"libraryHit"]];
                    [newResult setLibrary:nil];
                    [searchResults addObject:newResult];
                }
                if (([searchResults count] > 0) && ([coder decodeBoolForKey:@"identified"]))
                    identifiedSearchResult = [searchResults objectAtIndex:0];

                break;
            case 5:
            default:
                chromatogram = [[coder decodeObjectForKey:@"chromatogram"] retain];            
                peakID = [coder decodeIntForKey:@"peakID"];
                start = [coder decodeIntForKey:@"start"];
                end = [coder decodeIntForKey:@"end"];
                identifiedSearchResult = [[coder decodeObjectForKey:@"identifiedSearchResult"] retain];
                searchResults = [[coder decodeObjectForKey:@"searchResults"] retain];
                break;
        }
        switch (version) {
            case 0:
            case 1:
            case 2:
                baselineLeft = [[coder decodeObjectForKey:@"baselineL"] retain];
                baselineRight = [[coder decodeObjectForKey:@"baselineR"] retain];
                break;
            case 3:
            case 4:
            case 5:
            default:
                baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
                baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
                break;
        }
        label = [[coder decodeObjectForKey:@"label"] retain];
		symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
		confirmed = [coder decodeBoolForKey:@"confirmed"];        
	} 
    return self;
}

@end
