//
//  JKCombinedPeak.m
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKCombinedPeak.h"

#import "JKPeakRecord.h"
#import "JKLibraryEntry.h"
#import "JKGCMSDocument.h"

@implementation JKCombinedPeak

#pragma mark INIT
- (id)init {
	if ((self = [super init]) != nil) {
		peaks = [[NSMutableDictionary alloc] init];
        label = [@"Combined Peak" retain];
	}
	return self;
}

- (void) dealloc {
    [label release];
    [peaks release];
    [super dealloc];
}

#pragma mark ACTIONS
- (void)confirm {
//	for (JKPeakRecord *peak in [[self peaks] allValues]) {
//        [peak confirm]
//        if ([peak identified] | [peak confirmed]) {
//            [peak confirm];
//        } else if ([[peak searchResults] count] > 0) {
//            [peak identifyAs:[[peak searchResults] objectAtIndex:0]];
//            [peak confirm];
//        } else {
//            JKLogWarning(@"Could not confirm peak %d in document '%@', no search result available.", [peak peakID], [[peak document] displayName]);
//        }
//    }
}

#pragma mark CALCULATED ACCESSORS
- (NSNumber *)certainty {
    int count = 0;
	for (JKPeakRecord *peak in [[self peaks] allValues]) {
    	if ([peak confirmed]) {
            count++;
        }
    }
    
    // Calculate certainty
    return [NSNumber numberWithFloat:count*1.0f/[self countOfPeaks]];
}
- (NSNumber *)averageRetentionIndex {
  	float sum = 0.0f;
	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak retentionIndex] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
    
 }
- (NSNumber *)averageSurface {
	float sum = 0.0f;
	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak surface] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)averageHeight {
 	float sum = 0.0f;
	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak height] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)standardDeviationRetentionIndex {
	float sum = 0.0f;
    float average = [[self averageRetentionIndex] floatValue];    
	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak retentionIndex] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}

- (NSNumber *)standardDeviationSurface {
	float sum = 0.0f;
    float average = [[self averageSurface] floatValue];
 	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak surface] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}

- (NSNumber *)standardDeviationHeight {
 	float sum = 0.0f;
    float average = [[self averageHeight] floatValue];
 	for (JKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak height] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}


#pragma mark SPECIAL ACCESSORS
- (BOOL)isValidDocumentKey:(NSString *)aKey {
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    NSDocument *aDocument;
    
    for (aDocument in documents) {
        if ([aDocument isKindOfClass:[JKGCMSDocument class]]) {
            if ([[(JKGCMSDocument *)aDocument uuid] isEqualToString:aKey])
                return YES;
        }
    }
    JKLogDebug(@"Rejected key: %@", aKey);
    return NO;
}

- (void)addConfirmedPeak:(JKPeakRecord *)aPeak {
    NSString *documentKey = [[aPeak document] uuid];
    NSAssert([aPeak document], @"No document set for peak.");
    NSAssert(documentKey, @"UUID of document is not set.");
    [self setValue:aPeak forKey:documentKey];
}

- (void)removeUnconfirmedPeak:(JKPeakRecord *)aPeak {
    NSString *documentKey = [[aPeak document] uuid];
    NSAssert(documentKey, @"UUID of document is not set.");
    [self setValue:nil forKey:documentKey];
}

- (BOOL)isCombinedPeakForPeak:(JKPeakRecord *)aPeak {
    if ([self libraryEntry] && [aPeak libraryHit]) {
        return ([self libraryEntry] == [aPeak libraryHit]);
    } else {
        return NO;
    }
}

- (BOOL)isCompound:(NSString *)compoundString {
//    compoundString = [compoundString lowercaseString];
    
//    if ([[[self label] lowercaseString] isEqualToString:compoundString]) {
    if ([[self label] isEqualToString:compoundString]) {
        return YES;
    }
    
    if ([self libraryEntry]) {
        NSArray *synonymsArray = [[self libraryEntry] synonymsArray];

        for (NSString *synonym in synonymsArray) {
//            if ([[synonym lowercaseString] isEqualToString:compoundString]) {
            if ([synonym isEqualToString:compoundString]) {
                return YES;
            }
        }        
    }
    
    return NO;    
 }

- (id)valueForUndefinedKey:(NSString *)key {
    if ([self isValidDocumentKey:key]) {
        return [peaks objectForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
     if ([self isValidDocumentKey:key]) {

        if (value) {
            [peaks setObject:value forKey:key];            
            if ([value libraryHit] && ![self libraryEntry]) {
                [self setLibraryEntry:[value libraryHit]];
            }
            if ([value symbol] && ![self symbol]) {
                [self setSymbol:[value symbol]];
            }        
            if ([value label] && ![self label]) {
                [self setLabel:[value label]];
            }        
         } else {
            [peaks removeObjectForKey:key];
        }
    } else {
        [super setValue:value forUndefinedKey:key];
    }
}

#pragma mark ACCESSORS

- (NSString *)label {
    if ([self libraryEntry]) {
        return [[self libraryEntry] name];
    }
	return label;
}
- (void)setLabel:(NSString *)aLabel {
    if (aLabel != label) {
        [label autorelease];
        label = [aLabel retain];
        
        // Set label also for all peaks
        if (aLabel && ![self libraryEntry]) {
            if (!([aLabel isEqualToString:@""] || [aLabel hasPrefix:NSLocalizedString(@"Unknown compound",@"")])) {
                for (JKPeakRecord *peak in [[self peaks] allValues]) {
                    [peak setLabel:label];
                }            
            }            
        }
     }
}

- (NSString *)symbol {
	return symbol;
}
- (void)setSymbol:(NSString *)aSymbol {
    if (aSymbol != symbol) {
        [symbol autorelease];
        symbol = [aSymbol retain];
        
        // Set symbol also for all peaks
        for (JKPeakRecord *peak in [[self peaks] allValues]) {
            [peak setSymbol:symbol];
        }
    }
}

//- (int)index {
//	return index;
//}
//- (void)setIndex:(int)aIndex {
//	index = aIndex;
//}
//

//- (NSNumber *)retentionIndex {
//	return retentionIndex;
//}
//- (void)setRetentionIndex:(NSNumber *)aRetentionIndex {
//	[retentionIndex autorelease];
//	retentionIndex = [aRetentionIndex retain];
//}

//- (NSString *)model {
//	return model;
//}
//- (void)setModel:(NSString *)aModel {
//	[model autorelease];
//	model = [aModel retain];
//}

- (NSString *)group {
	return group;
}
- (void)setGroup:(NSString *)aGroup {
   if (aGroup != group) {        
       [group autorelease];
       group = [aGroup retain];
       
//        // Set group also for all peaks' libraryhits
//        for (JKPeakRecord *peak in [[self peaks] allValues]) {
//            [[peak libraryHit] setGroup:group];
//        }
//        [[self libraryEntry] setGroup:group];
    }    
}
//- (JKSpectrum *)spectrum {
//	return spectrum;
//}
//- (void)setSpectrum:(JKSpectrum *)aSpectrum {
//	[spectrum autorelease];
//	spectrum = [aSpectrum retain];
//}
- (JKLibraryEntry *)libraryEntry {
	return libraryEntry;
}
- (void)setLibraryEntry:(JKLibraryEntry *)aLibraryEntry {
    if (libraryEntry != aLibraryEntry) {
        [libraryEntry autorelease];
        libraryEntry = [aLibraryEntry retain];
        
        // Set libraryEntry also for all peaks
        if (libraryEntry) {
            for (JKPeakRecord *peak in [[self peaks] allValues]) {
                if (libraryEntry != [peak libraryHit]) {
                    JKSearchResult *searchResult = [peak addSearchResultForLibraryEntry:(JKManagedLibraryEntry *)libraryEntry];
                    [peak identifyAsSearchResult:searchResult];
                    [peak confirm];
                }
            }            
        }            
        
        
        if ([libraryEntry group]) {
            [self setGroup:[libraryEntry group]];
        }
        if ([libraryEntry symbol]) {
            [self setSymbol:[libraryEntry symbol]];
        }        
        if ([libraryEntry name]) {
            [self setLabel:[libraryEntry name]];
        }        
    }
}

- (BOOL)unknownCompound {
	return unknownCompound;
}
- (void)setUnknownCompound:(BOOL)aUnknownCompound {
	unknownCompound = aUnknownCompound;
}


// Mutable To-Many relationship peaks
- (NSMutableDictionary *)peaks {
	return peaks;
}

- (void)setPeaks:(NSMutableDictionary *)inValue {
    [inValue retain];
    [peaks release];
    peaks = inValue;
}

- (int)countOfPeaks {
    return [[self peaks] count];
}


@end
