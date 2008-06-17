//
//  JKCombinedPeak.m
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKCombinedPeak.h"

#import "PKPeakRecord.h"
#import "PKLibraryEntry.h"
#import "PKGCMSDocument.h"

@implementation PKCombinedPeak

#pragma mark Initialization & deallocation
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
#pragma mark -

#pragma mark Calculated Accessors
- (NSNumber *)certainty {
    int count = 0;
	for (PKPeakRecord *peak in [[self peaks] allValues]) {
    	if ([peak confirmed]) {
            count++;
        }
    }
    
    // Calculate certainty
    return [NSNumber numberWithFloat:count*1.0f/[self countOfPeaks]];
}
- (NSNumber *)averageRetentionIndex {
  	float sum = 0.0f;
	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak retentionIndex] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
    
 }
- (NSNumber *)averageSurface {
	float sum = 0.0f;
	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak surface] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)averageHeight {
 	float sum = 0.0f;
	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + [[peak height] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)standardDeviationRetentionIndex {
	float sum = 0.0f;
    float average = [[self averageRetentionIndex] floatValue];    
	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak retentionIndex] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}

- (NSNumber *)standardDeviationSurface {
	float sum = 0.0f;
    float average = [[self averageSurface] floatValue];
 	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak surface] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}

- (NSNumber *)standardDeviationHeight {
 	float sum = 0.0f;
    float average = [[self averageHeight] floatValue];
 	for (PKPeakRecord *peak in [[self peaks] allValues]) {
        sum = sum + powf(([[peak height] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}
#pragma mark -

#pragma mark Actions
- (void)addConfirmedPeak:(PKPeakRecord *)aPeak {
    NSString *documentKey = [[aPeak document] uuid];
    NSAssert([aPeak document], @"No document set for peak.");
    NSAssert(documentKey, @"UUID of document is not set.");
    [self setValue:aPeak forKey:documentKey];
}

- (void)removeUnconfirmedPeak:(PKPeakRecord *)aPeak {
    NSString *documentKey = [[aPeak document] uuid];
    NSAssert(documentKey, @"UUID of document is not set.");
    [self setValue:nil forKey:documentKey];
}
#pragma mark -

#pragma mark Helper methods
- (BOOL)isValidDocumentKey:(NSString *)aKey {
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    NSDocument *aDocument;
    
    for (aDocument in documents) {
        if ([aDocument isKindOfClass:[PKGCMSDocument class]]) {
            if ([[(PKGCMSDocument *)aDocument uuid] isEqualToString:aKey])
                return YES;
        }
    }
    PKLogDebug(@"Rejected key: %@", aKey);
    return NO;
}

- (BOOL)isCombinedPeakForPeak:(PKPeakRecord *)aPeak {
    if ([self libraryEntry] && [aPeak libraryHit]) {
        return ([self libraryEntry] == [aPeak libraryHit]);
    } else {
        return NO;
    }
}

- (BOOL)isCompound:(NSString *)compoundString {

    if ([[self label] isEqualToString:compoundString]) {
        return YES;
    }
    
    if ([self libraryEntry]) {
        NSArray *synonymsArray = [[self libraryEntry] synonymsArray];

        for (NSString *synonym in synonymsArray) {
            if ([synonym isEqualToString:compoundString]) {
                return YES;
            }
        }        
    }
    
    return NO;    
 }
#pragma mark -

#pragma mark Key Value Coding "abuse"
- (id)valueForUndefinedKey:(NSString *)key {
    if ([self isValidDocumentKey:key]) {
        return [peaks objectForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Peaks from documents are stored using their documents uuid
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
#pragma mark -

#pragma mark Accessors
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
                for (PKPeakRecord *peak in [[self peaks] allValues]) {
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
        for (PKPeakRecord *peak in [[self peaks] allValues]) {
            [peak setSymbol:symbol];
        }
    }
}

- (NSString *)group {
    if ([self libraryEntry]) {
        if ([[self libraryEntry] group])
            if (![[[self libraryEntry] group] isEqualToString:@""])
                return [[self libraryEntry] group];
    }
	return @"X";
}

- (PKLibraryEntry *)libraryEntry {
	return libraryEntry;
}
- (void)setLibraryEntry:(PKLibraryEntry *)aLibraryEntry {
    BOOL result;
    
    if (libraryEntry != aLibraryEntry) {
        result = YES;
        
        // Set aLibraryEntry first for all peaks
        if (libraryEntry) {
            for (PKPeakRecord *peak in [[self peaks] allValues]) {
                if (aLibraryEntry != [peak libraryHit]) {
                    PKSearchResult *searchResult = [peak addSearchResultForLibraryEntry:(PKManagedLibraryEntry *)aLibraryEntry];
                    result = [peak identifyAndConfirmAsSearchResult:searchResult];
                }
            }            
        }     
        
        // Only set for combined peak if succesful set for all peaks
        if (result) {
            [libraryEntry autorelease];
            libraryEntry = [aLibraryEntry retain];
        }
    }
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
