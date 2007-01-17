//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPeakRecord.h"

#import "JKLibraryEntry.h"
#import "JKGCMSDocument.h"

@implementation JKPeakRecord

# pragma mark INITIALIZATION
+ (void)initialize{
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"library"];
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"deltaRetentionIndex"];
	[self setKeys:[NSArray arrayWithObjects:@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"score"];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"JKPeakRecord: %@ (top: %f)", [self label], [[self topTime] floatValue]];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		searchResults = [[NSMutableArray alloc] init];
		label = @"";
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

#pragma mark ACCESSORS

- (void)setPeakID:(NSNumber *)inValue {
	[inValue retain];
	[peakID autorelease];
	peakID = inValue;
}
- (NSNumber *)peakID {
    return peakID;
}
- (void)setDocument:(JKGCMSDocument *)inValue {
	// Weak link
	document = inValue;
}
- (JKGCMSDocument *)document {
    return document;
}

- (NSNumber *)score {
	return [identifiedSearchResult objectForKey:@"score"];
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

- (void)setModel:(NSString *)inValue {
    [[self undoManager] registerUndoWithTarget:self
                                      selector:@selector(setModel:)
                                        object:label];
    [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Model",@"Change Peak Model")];
    
	[inValue retain];
	[model autorelease];
	model = inValue;
}

- (NSString *)model {
    return model;
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

//- (void)setTopTime:(NSNumber *)inValue  
//{
//	[inValue retain];
//	[topTime autorelease];
//	topTime = inValue;
//}

//- (NSNumber *)topTime  
//{
//    return topTime;
//}


- (void)setHeight:(NSNumber *)inValue {
	[inValue retain];
	[height autorelease];
	height = inValue;
}

- (NSNumber *)height {
    return height;
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

- (void)setBaselineLeftTime:(NSNumber *)inValue {
	[inValue retain];
	[baselineLeftTime autorelease];
	baselineLeftTime = inValue;
}

- (NSNumber *)baselineLeftTime{
    return baselineLeftTime;
}

- (void)setBaselineRightTime:(NSNumber *)inValue {
	[inValue retain];
	[baselineRightTime autorelease];
	baselineRightTime = inValue;
}

- (NSNumber *)baselineRightTime{
    return baselineRightTime;
}

- (void)setSurface:(NSNumber *)inValue {
	[inValue retain];
	[surface autorelease];
	surface = inValue;
}

- (NSNumber *)surface {
    return surface;
}

- (void)setTop:(NSNumber *)inValue {
	[inValue retain];
	[top autorelease];
	top = inValue;
}

- (NSNumber *)top {
    return top;
}

- (NSNumber *)topTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:[top intValue]]];
}


- (void)setStart:(NSNumber *)inValue {
	[inValue retain];
	[start autorelease];
	start = inValue;
}

- (NSNumber *)start {
    return start;
}

- (NSNumber *)startTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:[start intValue]]];
}

- (void)setEnd:(NSNumber *)inValue {
	[inValue retain];
	[end autorelease];
	end = inValue;
}

- (NSNumber *)end {
    return end;
}

- (NSNumber *)endTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:[end intValue]]];
}

- (void)setSpectrum:(JKSpectrum *)inValue {
	[inValue retain];
	[spectrum autorelease];
	spectrum = inValue;
}

- (JKSpectrum *)spectrum {
    NSAssert(spectrum != nil, @"spectrum is nil");
    return spectrum;
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
	return [identifiedSearchResult objectForKey:@"library"];
}

- (JKLibraryEntry *)libraryHit {
	return [identifiedSearchResult objectForKey:@"libraryHit"];
}

- (void)setRetentionIndex:(NSNumber *)inValue {
	[inValue retain];
	[retentionIndex autorelease];
	retentionIndex = inValue;
}

- (NSNumber *)retentionIndex {
    return retentionIndex;
}

- (void)setNormalizedHeight:(NSNumber *)inValue{
	[inValue retain];
	[normalizedHeight autorelease];
	normalizedHeight = inValue;
	
}
- (NSNumber *)normalizedHeight{
	return normalizedHeight;
}
- (void)setNormalizedSurface:(NSNumber *)inValue{
	[inValue retain];
	[normalizedSurface autorelease];
	normalizedSurface = inValue;	
}
- (NSNumber *)normalizedSurface {
	return normalizedSurface;
}

- (void)setIdentifiedSearchResult:(id)inValue{
	[inValue retain];
	[identifiedSearchResult autorelease];
	identifiedSearchResult = inValue;
	
}
- (id)identifiedSearchResult{
	return identifiedSearchResult;
}

- (int)searchResultsCount{
	return [searchResults count];
}

- (NSMutableArray *)searchResults {
    return searchResults;
}

- (void)setSearchResults:(NSMutableArray *)array{
	if (array == searchResults)
		return;
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [[self document] undoManager];
	[[undo prepareWithInvocationTarget:self] setSearchResults:searchResults];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Set Search Results",@"")];
	}
	
	[searchResults release];
	[array retain];
	searchResults = array;
}

- (void)insertObject:(NSDictionary *)searchResult inSearchResultsAtIndex:(int)index{
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [[self document] undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Search Result",@"")];
	}
	
	// Add the peak to the array
	[searchResults insertObject:searchResult atIndex:index];
}

- (void)removeObjectFromSearchResultsAtIndex:(int)index{
	NSDictionary *searchResult = [searchResults objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [[self document] undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:searchResult inSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Search Result",@"")];
	}
	
	// Remove the searchResult from the array
	[searchResults removeObjectAtIndex:index];
}


#pragma mark NSCODING

- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeInt:3 forKey:@"version"];
		[coder encodeConditionalObject:document forKey:@"document"];
		[coder encodeObject:peakID forKey:@"peakID"];
		[coder encodeObject:start forKey:@"start"];
        [coder encodeObject:end forKey:@"end"];
        [coder encodeObject:top forKey:@"top"];
//        [coder encodeObject:topTime forKey:@"topTime"];
        [coder encodeObject:height forKey:@"height"];
        [coder encodeObject:normalizedHeight forKey:@"normalizedHeight"];
		[coder encodeObject:baselineLeft forKey:@"baselineLeft"];
        [coder encodeObject:baselineRight forKey:@"baselineRight"];
        [coder encodeObject:surface forKey:@"surface"];
        [coder encodeObject:normalizedSurface forKey:@"normalizedSurface"];
        [coder encodeObject:label forKey:@"label"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeBool:identified forKey:@"identified"];
		[coder encodeBool:confirmed forKey:@"confirmed"];
		[coder encodeObject:identifiedSearchResult forKey:@"identifiedSearchResult"];
		[coder encodeObject:retentionIndex forKey:@"retentionIndex"];
		[coder encodeObject:searchResults forKey:@"searchResults"];
		[coder encodeObject:spectrum forKey:@"spectrum"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
		int version = [coder decodeIntForKey:@"version"];
		document = [coder decodeObjectForKey:@"document"]; 
        // Support for reading in old file-format
        if (document == nil) {
            _needsUpdating = YES;
            _libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain];
            _score = [[coder decodeObjectForKey:@"score"] retain];
        }
		peakID = [[coder decodeObjectForKey:@"peakID"] retain];
		start = [[coder decodeObjectForKey:@"start"] retain];
        end = [[coder decodeObjectForKey:@"end"] retain];
        top = [[coder decodeObjectForKey:@"top"] retain];
        height = [[coder decodeObjectForKey:@"height"] retain];
        normalizedHeight = [[coder decodeObjectForKey:@"normalizedHeight"] retain];
        // Support for reading in old file-format
		if (version < 3) {
			baselineLeft = [[coder decodeObjectForKey:@"baselineL"] retain];
			baselineRight = [[coder decodeObjectForKey:@"baselineR"] retain];
		} else {
			baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
			baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
		}
        surface = [[coder decodeObjectForKey:@"surface"] retain];
        normalizedSurface = [[coder decodeObjectForKey:@"normalizedSurface"] retain];
        label = [[coder decodeObjectForKey:@"label"] retain];
		symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
		confirmed = [coder decodeBoolForKey:@"confirmed"];
		identifiedSearchResult = [[coder decodeObjectForKey:@"identifiedSearchResult"] retain];
		retentionIndex = [[coder decodeObjectForKey:@"retentionIndex"] retain];
		searchResults = [[coder decodeObjectForKey:@"searchResults"] retain];
        spectrum = [[coder decodeObjectForKey:@"spectrum"] retain];		
	} 
    return self;
}

- (void)updateForNewEncoding {
    if (_needsUpdating) {
        // A bit of a hack really
        document = [[NSDocumentController sharedDocumentController] currentDocument];
        NSAssert(document != nil, @"updateForNewEncoding - No document found");
        spectrum = [[JKSpectrum alloc] init];
        float npts = [document endValuesSpectrum:[top intValue]] - [document startValuesSpectrum:[top intValue]];
        float *xpts = [document massValuesForSpectrumAtScan:[top intValue]];
        float *ypts = [document intensityValuesForSpectrumAtScan:[top intValue]];
        [spectrum setMasses:xpts withCount:npts];
        [spectrum setIntensities:ypts withCount:npts];
        [spectrum setDocument:document];
        free(xpts);
        free(ypts);
        [self setSpectrum:spectrum];
        // Don't release now because no spectrum is yet set in init
        // [spectrum release];

        searchResults = [[NSMutableArray alloc] init];

        if (identified && ((_score != nil) && (_libraryHit != nil))) {
            
            NSMutableDictionary *searchResult = [[NSMutableDictionary alloc] init];
			[searchResult setValue:_score forKey:@"score"];
			[searchResult setValue:_libraryHit forKey:@"libraryHit"];

            [self willChangeValueForKey:@"libraryHit"];
            [self setIdentifiedSearchResult:searchResult];
            // Initial default settings after identification, but can be customized by user later on
            [self setSymbol:[searchResult valueForKeyPath:@"libraryHit.symbol"]];
            
            if (![searchResults containsObject:searchResult]) {
                [self willChangeValueForKey:@"searchResultCount"];
                [searchResults insertObject:searchResult atIndex:[searchResults count]];
                [self didChangeValueForKey:@"searchResultCount"];
            }
            [self didChangeValueForKey:@"libraryHit"];
            
			[searchResult release];
        }
    }
}

@end
