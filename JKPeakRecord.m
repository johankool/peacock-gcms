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
#import "JKManagedLibraryEntry.h"
#import "JKSearchResult.h"
#import "JKSpectrum.h"
#import "jk_statistics.h"
#import "JKAppDelegate.h"
#import "NSString+ModelCompare.h"

@implementation JKPeakRecord

# pragma mark Initialization & deallocation
+ (void)initialize{
	[self setKeys:[NSArray arrayWithObjects:@"identifiedSearchResult",nil] triggerChangeNotificationsForDependentKey:@"libraryHit"];
	[self setKeys:[NSArray arrayWithObjects:@"identifiedSearchResult",nil] triggerChangeNotificationsForDependentKey:@"library"];
	[self setKeys:[NSArray arrayWithObjects:@"identifiedSearchResult",nil] triggerChangeNotificationsForDependentKey:@"deltaRetentionIndex"];
	[self setKeys:[NSArray arrayWithObjects:@"identifiedSearchResult",nil] triggerChangeNotificationsForDependentKey:@"score"];
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
	return [NSString stringWithFormat:@"JKPeakRecord: %@ (top: %f)\nuuid: %@", [self label], [[self topTime] floatValue], [self uuid]];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		searchResults = [[NSMutableArray alloc] init];
		label = [@"" retain];
        symbol = [@"" retain];
        identified = NO;
        confirmed = NO;
        baselineLeft = [[NSNumber alloc] init]; 
        baselineRight = [[NSNumber alloc] init]; 
        end = 0;
        peakID = 0;
        start = 0;
        flagged = NO;
        uuid = GetUUID();
        [uuid retain];
        identifiedSearchResult = nil;
    }
    return self;	
}

- (void)dealloc {
    [label release];
    [symbol release];
    [searchResults release];
    [uuid release];
    [baselineLeft release];
    [baselineRight release];
    [super dealloc];
}

-(JKLibraryEntry *)libraryEntryRepresentation
{
    JKLibraryEntry *libEntry = [[JKLibraryEntry alloc] init];
    [libEntry setName:[self label]];
    [libEntry setModel:[self model]];
    [libEntry setPeakTable:[[self spectrum] peakTable]];
    [libEntry setOwner:[NSString stringWithFormat:@"%@",NSFullUserName()]];
    [libEntry setSource:[[self document] displayName]];
    [libEntry setRetentionIndex:[self retentionIndex]];
    JKLogDebug([libEntry jcampString]);
    return [libEntry autorelease];
}
#pragma mark -

#pragma mark NSCoding
- (void)encodeWithCoder:(NSCoder *)coder{
    if ([coder allowsKeyedCoding]) {
        if ([super conformsToProtocol:@protocol(NSCoding)]) {
            [super encodeWithCoder:coder];        
        } 
		[coder encodeInt:6 forKey:@"version"];
		[coder encodeInt:peakID forKey:@"peakID"];
		[coder encodeInt:start forKey:@"start"];
        [coder encodeInt:end forKey:@"end"];
		[coder encodeObject:baselineLeft forKey:@"baselineLeft"];
        [coder encodeObject:baselineRight forKey:@"baselineRight"];
        [coder encodeObject:label forKey:@"label"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeBool:identified forKey:@"identified"];
		[coder encodeBool:confirmed forKey:@"confirmed"];
		[coder encodeBool:flagged forKey:@"flagged"];
		[coder encodeObject:identifiedSearchResult forKey:@"identifiedSearchResult"];
		[coder encodeObject:searchResults forKey:@"searchResults"];
        [coder encodeObject:uuid forKey:@"uuid"];
    } else {
        [NSException raise:NSInvalidArchiveOperationException
                    format:@"Only supports NSKeyedArchiver coders"];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ([coder allowsKeyedCoding]) {
        int version = [coder decodeIntForKey:@"version"];
        if (version < 6) {
            JKLogWarning(@"Deprecated file format no longer supported.");
        }
        peakID = [coder decodeIntForKey:@"peakID"];
        start = [coder decodeIntForKey:@"start"];
        end = [coder decodeIntForKey:@"end"];
        searchResults = [[coder decodeObjectForKey:@"searchResults"] retain];
        identifiedSearchResult = [[coder decodeObjectForKey:@"identifiedSearchResult"] retain];
        baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
        baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
        uuid = [[coder decodeObjectForKey:@"uuid"] retain];
        label = [[coder decodeObjectForKey:@"label"] retain];
        symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
        // We want notifications for confirmed peaks being posted
        confirmed = [coder decodeBoolForKey:@"confirmed"]; 
        //[self setConfirmed:[coder decodeBoolForKey:@"confirmed"]];
        flagged = [coder decodeBoolForKey:@"flagged"]; 
	} else {
        [NSException raise:NSInvalidArchiveOperationException
                    format:@"Only supports NSKeyedUnarchiver decoders"];
    }
    return self;
}
#pragma mark -

#pragma mark Actions
- (BOOL)confirm {
//    BOOL result;
    int answer;
    
    if (![self identified]) {	
        NSBeep();
        JKLogWarning(@"Can not confirm a peak that is not identified.");
        return NO;
    }
    
    if (![[self document] modelString:[[self chromatogram] model] isEqualToString:[[identifiedSearchResult libraryHit] model]] && ![[[identifiedSearchResult libraryHit] model] isEqualToString:@""] && identifiedSearchResult) {   
        answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Model mismatch occurred",@""), NSLocalizedString(@"The model of the peak is different from the library entry. Are you sure you want to assign this library entry to this peak?",@""), NSLocalizedString(@"Assign",@""), NSLocalizedString(@"Cancel",@""),nil); // NSLocalizedString(@"Move Peak to Model",@"")
        if (answer == NSOKButton) {
            // Continue
        } else if (answer == NSCancelButton) {
            // Cancel
            return NO;
//        } else {
//            // Move peak to chromatogram of the model in the libraryentry
//            JKChromatogram *targetChrom = nil;
//            if ([[self document] addChromatogramForModel:[[identifiedSearchResult libraryHit] model]]) {
//                targetChrom = [[self document] chromatogramForModel:[[identifiedSearchResult libraryHit] model]];
//                [targetChrom obtainBaseline];
//            } else {
//                targetChrom = [[self document] chromatogramForModel:[[identifiedSearchResult libraryHit] model]];
//            }
//            JKChromatogram *oldChrom = [self chromatogram];
//            [targetChrom insertObject:self inPeaksAtIndex:[targetChrom countOfPeaks]];
//            [oldChrom removeObjectFromPeaksAtIndex:[[oldChrom peaks] indexOfObject:self]];
        }
    }
    
    // check if there is already a peak with the same label
    if ([[[self chromatogram] document] hasPeakConfirmedAs:[identifiedSearchResult libraryHit] notBeing:self]) {
        answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Library hit already assigned",@""),NSLocalizedString(@"There is already a confirmed peak with the same library hit. Usually only one peak should be assigned to a library entry. What action do you want to take?",@""), NSLocalizedString(@"Assign to This Peak Only",@""), NSLocalizedString(@"Cancel",@""), NSLocalizedString(@"Assign to Both Peaks",@""));
        if (answer == NSOKButton) {
            // Assign to This Peak Only
            [[[self chromatogram] document] unconfirmPeaksConfirmedAs:[identifiedSearchResult libraryHit] notBeing:self];
        } else if (answer == NSCancelButton) {
            // Cancel
            return NO;
        } else {      
            // Assign to Both Peaks
        }        
    }
        
    // check if other peak with same top scan and offer to delete those
    if ([[[self chromatogram] document] hasPeakAtTopScan:[self top] notBeing:self]) {
        answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Remove peaks in other models?",@""), NSLocalizedString(@"One or more peaks with the same top scan were found in other models. Most likely you want to identify and confirm a peak in one model only. Do you want to remove the peaks in the other models?",@""), NSLocalizedString(@"Delete",@""), NSLocalizedString(@"Keep",@""),nil);
        if (answer == NSOKButton) {
            // Delete
            [[[self chromatogram] document] removePeaksAtTopScan:[self top] notBeing:self];
        } else if (answer == NSCancelButton) {
            // Keep
        }     
    }
    
	if ([self identified]) {		
		[self setConfirmed:YES];
        [self setSearchResults:[NSMutableArray arrayWithObject:identifiedSearchResult]];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit",@"Confirm Library Hit")];
        }
		return YES;		
    }
    
    return NO;
    
//    else if ([searchResults count] > 0) {
//        result = [self identifyAsSearchResult:[searchResults objectAtIndex:0]];
//        if (result) {
//            [self setConfirmed:YES];
//            [self setSearchResults:[NSMutableArray arrayWithObject:identifiedSearchResult]];
//            if (![[self undoManager] isUndoing]) {
//                [[self undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit",@"Confirm Library Hit")];
//            }                
//        }
//        return result;
//	} else {
//        // Allow this to mark a peak as confirmed with having the proper library entry
//        JKManagedLibraryEntry *managedLibEntry = [(JKAppDelegate *)[NSApp delegate] addLibraryEntryBasedOnPeak:self];
//        if (managedLibEntry) {
//            result = [self identifyAsLibraryEntry:[JKLibraryEntry libraryEntryWithJCAMPString:[managedLibEntry jcampString]]];
//            if (result) {
//                [self setConfirmed:YES]; 
//                [self setSearchResults:[NSMutableArray arrayWithObject:identifiedSearchResult]];
//            }
//        } else {
//            [self setConfirmed:YES];
//            result = YES;
//        }
//        
//        if (![[self undoManager] isUndoing]) {
//            [[self undoManager] setActionName:NSLocalizedString(@"Confirm Library Hit",@"Confirm Library Hit")];
//        }        
//        return result;
//	}
}

- (void)discard {
    [self setIdentified:NO];
	[self setConfirmed:NO];
	[self setLabel:@""];
	[self setSymbol:@""];
	[self setIdentifiedSearchResult:nil];
    if (![[self undoManager] isUndoing]) {
        [[self undoManager] setActionName:NSLocalizedString(@"Discard Library Hit",@"Discard Library Hit")];
    }    
}

- (JKSearchResult *)addSearchResult:(JKSearchResult *)searchResult {
	if (![searchResults containsObject:searchResult]) {
        // Loop through searchResults and make sure we not already have a search result like this one
        JKSearchResult *aSearchResult;
        BOOL foundMatch = NO;
        
        for (aSearchResult in searchResults) {
//        	if ([[searchResult libraryHit] isCompound:[[aSearchResult libraryHit] name]]) {
//                foundMatch = YES;
//                searchResult = aSearchResult;
//            }
        	if ([searchResult libraryHit] == [aSearchResult libraryHit]) {
                foundMatch = YES;
                searchResult = aSearchResult;
            }
        }
        if (!foundMatch)
            [self insertObject:searchResult inSearchResultsAtIndex:[searchResults count]];
    }
    
    NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score" ascending:NO] autorelease];
    [searchResults sortUsingDescriptors:[NSArray arrayWithObject:sortDescriptor]];
    
    if ((searchResult == [searchResults objectAtIndex:0]) && ([[searchResult score] floatValue] >= [[[self document] markAsIdentifiedThreshold] floatValue])) {
        [self identifyAsSearchResult:searchResult];
    }
	
    return searchResult;
}

- (JKSearchResult *)addSearchResultForLibraryEntry:(JKManagedLibraryEntry *)aLibraryEntry
{
    JKSearchResult *searchResult = [[JKSearchResult alloc] init];
    [searchResult setPeak:self];
    [searchResult setLibraryHit:aLibraryEntry];
    [searchResult setScore:[NSNumber numberWithFloat:[[self spectrum] scoreComparedTo:aLibraryEntry]]];
    return [self addSearchResult:searchResult];
}

- (BOOL)identifyAsSearchResult:(JKSearchResult *)searchResult {
    [self setConfirmed:NO];

    [self setIdentifiedSearchResult:searchResult];
    
     // Initial default settings after identification, but can be customized by user later on
    [self setLabel:[[searchResult libraryHit] name]];
    [self setSymbol:[[searchResult libraryHit] symbol]];
    [self setIdentified:YES];
        
    if (![[self undoManager] isUndoing]) {
        [[self undoManager] setActionName:NSLocalizedString(@"Identify as Library Hit",@"Identify as Library Hit")];
    }        
    
    return YES;
}

- (BOOL)isCompound:(NSString *)compoundString
{
    compoundString = [compoundString lowercaseString];
    
    if ([[[self label] lowercaseString] isEqualToString:compoundString]) {
        return YES;
    }
    
    if ([self confirmed] && [self libraryHit]) {
        NSArray *synonymsArray = [[self libraryHit] synonymsArray];
        NSString *synonym;
        
        for (synonym in synonymsArray) {
            if ([[synonym lowercaseString] isEqualToString:compoundString]) {
                return YES;
            }
        }        
    }
    
    return NO;    
}

#pragma mark -

#pragma mark JKTargetObjectProtocol
- (NSDictionary *)substitutionVariables
{
    int maximumMass = lroundf(jk_stats_float_max([[self spectrum] masses],[[self spectrum] numberOfPoints]));
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [self model], @"model",
        [NSNumber numberWithInt:[[self retentionIndex] intValue]], @"retentionIndex",
        [self label], @"label",
        [NSNumber numberWithInt:maximumMass], @"maximumMass",
        [NSNumber numberWithInt:[self top]], @"scan",
        [NSNumber numberWithInt:[[self topTime] intValue]], @"time",
        nil];
    //@"model",
    //@"retentionIndex",
    //@"label",
    //@"maximumMass"
    //@"maximumMassPlus50"
    //@"maximumMassMinus50"
    //@"scan"
    //@"time"
}
#pragma mark -

#pragma mark Calculated Accessors

- (NSNumber *)deltaRetentionIndex {
	float value = 0.0;
	if (([[self libraryHit] retentionIndex] == nil) || ([[[self libraryHit] retentionIndex] floatValue] == 0.0)) {
		//return [NSNumber numberWithFloat:0.0];
        return [NSDecimalNumber notANumber];
	}
	value = [[[self libraryHit] retentionIndex] floatValue] - [[self retentionIndex] floatValue];
    return [NSNumber numberWithFloat:value];
}

- (int)top {
    int top;
    int j;
    if (![self chromatogram]) {
        return 0;
    }
    float *totalIntensity = [[self chromatogram] totalIntensity];
    top = start;
    if (top > [[self chromatogram] numberOfPoints]) {
        [NSException raise:@"Out of bounds exception" format:@"The top for peak record '%@' is outside the range of values for chromatogram '%@'.", [self label], [[self chromatogram] model]];
    }
    for (j=start; j <= end; j++) {
        if (totalIntensity[j] > totalIntensity[top]) {
            top = j;
        }
    }
    return top;
}

- (NSNumber *)topTime {
    if (![self chromatogram]) {
        return [NSNumber numberWithFloat:0.0f];
    }
    
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
    return [NSNumber numberWithFloat:100.0f*surface/largestPeakSurface];
}

- (NSNumber *)normalizedSurface2 {
    float surface = [[self surface] floatValue];
    float totalPeakSurface = [[self document] confirmedPeaksSurface];
    return [NSNumber numberWithFloat:100.0f*surface/totalPeakSurface];
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
    [spectrum setPeak:self];
    return spectrum;
}

- (JKSpectrum *)combinedSpectrum {
    JKSpectrum *spectrum = [[[self document] spectrumForScan:[self top]] spectrumBySubtractingSpectrum:[[[self document] spectrumForScan:[self start]] spectrumByAveragingWithSpectrum:[[self document] spectrumForScan:[self end]]]];
    [spectrum setPeak:self];
    return spectrum;
}

- (NSNumber *)width {
    return [NSNumber numberWithInt:end-start];
}

- (NSString *)library {
    if ([self identified]) {
        return [[identifiedSearchResult libraryHit] library];
    } else {
        return nil;
    }
}

- (JKLibraryEntry *)libraryHit {
    if (!identifiedSearchResult)
        return nil;
	return [identifiedSearchResult libraryHit];
}

- (JKGCMSDocument *)document {
    return [[self chromatogram] document];
}

- (NSUndoManager *)undoManager {
    return [[self document] undoManager];
}

- (NSNumber *)score {
    if ([self identified]) {
        return [identifiedSearchResult score];
    } else {
        return nil;
    }
}

- (NSString *)model {
    return [[self chromatogram] model];
}

- (NSNumber *)startTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:start]];
}

- (NSNumber *)endTime{
    return [NSNumber numberWithFloat:[[self document] timeForScan:end]];
}

#pragma mark -

#pragma mark Accessors
- (NSString *)uuid {
    return uuid;
}

- (void)setPeakID:(int)inValue {
    if (inValue != peakID) {
        [[[self undoManager] prepareWithInvocationTarget:self] setPeakID:peakID];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak ID",@"Change Peak ID")];
        }
        peakID = inValue;        
    }
}

- (int)peakID {
    return peakID;
}

- (JKChromatogram *)chromatogram {
    return (JKChromatogram *)[self container];
}

- (void)setChromatogram:(JKChromatogram *)inValue {
    return [self setContainer:inValue];
}

- (void)setLabel:(NSString *)inValue {
    if (![inValue isEqualToString:label]) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setLabel:)
                                            object:label];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Label",@"Change Peak Label")];
        }
        
        [inValue copy];
        [label autorelease];
        label = inValue;   
        
//        if (!identifiedSearchResult) {
//            [self identifyAsLibraryEntry:[[NSApp delegate] libraryEntryForName:label]];
//        }
    }
}

- (NSString *)label {
    return label;
}

-(BOOL)validateLabel:(id *)ioValue error:(NSError **)outError
{
    if (*ioValue == nil) {
        return YES;
    }
    // enforce no use of characters "[];"
    if ([*ioValue rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"[];"]].location != NSNotFound) {
        NSString *errorString = NSLocalizedString(@"A peak label may not contain the characters '[', ']' and ';'.", @"validation: []; error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:109
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }

    return YES;
}

- (void)setSymbol:(NSString *)inValue {
    if (![inValue isEqualToString:symbol]) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setSymbol:)
                                            object:symbol];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Symbol",@"Change Peak Symbol")];
        }
        [inValue copy];
        [symbol autorelease];
        symbol = inValue;        
    }
}

- (NSString *)symbol {
    return symbol;
} 

- (void)setBaselineLeft:(NSNumber *)inValue {
    if ((!baselineLeft) || (![inValue isEqualToNumber:baselineLeft])) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setBaselineLeft:)
                                            object:baselineLeft];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Left Baseline",@"Change Peak Left Baseline")];
        }
        
        [inValue copy];
        [baselineLeft autorelease];
        baselineLeft = inValue;        
    }
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
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:105
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue floatValue] < 0.0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be larger than or equal to 0.",@"baseline to small error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:106
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setBaselineRight:(NSNumber *)inValue {
    if ((!baselineRight) || (![inValue isEqualToNumber:baselineRight])) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setBaselineRight:)
                                            object:baselineRight];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Right Baseline",@"Change Peak Right Baseline")];
        }
        
        [inValue copy];
        [baselineRight autorelease];
        baselineRight = inValue;        
    }
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
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:107
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue floatValue] < 0.0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for baseline intensity",@"baseline to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for the baseline intensity should be larger than or equal to 0.",@"baseline to small error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:108
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setStart:(int)inValue {
    if (inValue != start) {
        [[[self undoManager] prepareWithInvocationTarget:self] setStart:start];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Start Scan",@"Change Start Scan")];
        }
        start = inValue;                
    }
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
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:101
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue intValue] < 0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for start scan",@"start to small error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for start scan should be larger than or equal to 0.",@"start to small error"),[self end]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:102
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setEnd:(int)inValue {
    if (inValue != end) {
        [[[self undoManager] prepareWithInvocationTarget:self] setEnd:end];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak End Scan",@"Change End Scan")];
        }
        end = inValue;                
    }
}

- (int)end {
    return end;
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
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:104
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else if ([*ioValue intValue] >= [[self chromatogram] numberOfPoints]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for end scan",@"end to big error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The value for end scan should be smaller than the number of scans in the chromatogram. Enter a value smaller than %d.",@"end to small error"),[[self chromatogram] numberOfPoints]];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:103
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } else {
        return YES;
    }
}

- (void)setIdentified:(BOOL)inValue {
    if (inValue != identified) {
        [[[self undoManager] prepareWithInvocationTarget:self] setIdentified:identified];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Identified Status",@"Change Peak Identified Status")];
        }
        
        identified = inValue;    
        
        if (inValue) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JKDidIdentifyPeak" object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JKDidUnidentifyPeak" object:self];
        }
    }
}

- (BOOL)identified {
    return identified;
}

- (void)setConfirmed:(BOOL)inValue {
    if (inValue != confirmed) {
        [[[self undoManager] prepareWithInvocationTarget:self] setConfirmed:confirmed];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Confirmed Status",@"Change Peak Confirmed Status")];
        }
        
        confirmed = inValue;        
        
        if (inValue) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JKDidConfirmPeak" object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JKDidUnconfirmPeak" object:self];
        }
    }
}

- (BOOL)confirmed {
    return confirmed;
}

- (void)setFlagged:(BOOL)inValue {
    if (inValue != flagged) {
        [[[self undoManager] prepareWithInvocationTarget:self] setFlagged:flagged];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Flagged Status",@"Change Peak Flagged Status")];
        }
        
        flagged = inValue;        
    }    
}

- (BOOL)flagged {
    return flagged;
}

- (void)setIdentifiedSearchResult:(JKSearchResult *)inValue {
    if (inValue != identifiedSearchResult) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setIdentifiedSearchResult:)
                                            object:identifiedSearchResult];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Change Peak Identified Search Result",@"Change Peak Identified Search Result")];
        }
        
        [inValue retain];
        [identifiedSearchResult autorelease];
        identifiedSearchResult = inValue;        
    }	
}
- (JKSearchResult *)identifiedSearchResult{
	return identifiedSearchResult;
}

// Mutable To-Many relationship searchResults
- (NSMutableArray *)searchResults {
	return searchResults;
}

- (void)setSearchResults:(NSMutableArray *)inValue {
    if (inValue != searchResults) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setSearchResults:)
                                            object:searchResults];
        if (![[self undoManager] isUndoing]) {
            [[self undoManager] setActionName:NSLocalizedString(@"Set Search Results",@"Set Search Results")];
        }
        
        [inValue retain];
        [searchResults autorelease];
        searchResults = inValue;        
    }	
}

- (int)countOfSearchResults {
    return [[self searchResults] count];
}

- (JKSearchResult *)objectInSearchResultsAtIndex:(int)index {
    return [[self searchResults] objectAtIndex:index];
}

- (void)getSearchResult:(JKSearchResult **)someSearchResults range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [searchResults getObjects:someSearchResults range:inRange];
}

- (void)insertObject:(JKSearchResult *)aSearchResult inSearchResultsAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Search Result",@"")];
	}
	
	// Add aSearchResult to the array searchResults
    [self willChangeValueForKey:@"searchResults"];
	[searchResults insertObject:aSearchResult atIndex:index];
    [self didChangeValueForKey:@"searchResults"];
}

- (void)removeObjectFromSearchResultsAtIndex:(int)index
{
	JKSearchResult *aSearchResult = [searchResults objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aSearchResult inSearchResultsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Search Result",@"")];
	}
	
	// Remove the peak from the array
    [self willChangeValueForKey:@"searchResults"];
	[searchResults removeObjectAtIndex:index];
    [self didChangeValueForKey:@"searchResults"];
}

- (void)replaceObjectInSearchResultsAtIndex:(int)index withObject:(JKSearchResult *)aSearchResult
{
	JKSearchResult *replacedSearchResult = [searchResults objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedSearchResult];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Search Result",@"")];
	}
	
	// Replace the peak from the array
    [self willChangeValueForKey:@"searchResults"];
	[searchResults replaceObjectAtIndex:index withObject:aSearchResult];
    [self didChangeValueForKey:@"searchResults"];
}

- (BOOL)validateSearchResult:(JKSearchResult **)aSearchResult error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end searchResults

@synthesize _libraryHit;
@synthesize _score;
@synthesize _needsUpdating;
@synthesize uuid;
@end
