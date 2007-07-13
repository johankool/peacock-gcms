//
//  JKCombinedPeak.m
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "JKCombinedPeak.h"

#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "JKStatisticsDocument.h"
#import "JKLibraryEntry.h"

@implementation JKCombinedPeak

#pragma mark INIT
- (id)init {
	if ((self = [super init]) != nil) {
		peaks = [[NSMutableDictionary alloc] init];
        index = -1;
	}
	return self;
}

- (void) dealloc {
    [peaks release];
    [super dealloc];
}

#pragma mark NSCODING

- (id)initWithCoder:(NSCoder *)decoder {
	[super init];
    int version = [decoder decodeIntForKey:@"version"];
    if (version < 1) {
        index = -1;
        symbol= [[decoder decodeObjectForKey:@"symbol"] retain];
        if (symbol)
            index = [symbol intValue];
    } else {
        symbol= [[decoder decodeObjectForKey:@"symbol"] retain];
        index = [decoder decodeIntForKey:@"index"];
    }       
    document = [decoder decodeObjectForKey:@"document"];
    label= [[decoder decodeObjectForKey:@"label"] retain];
    retentionIndex = [[decoder decodeObjectForKey:@"retentionIndex"] retain];
    model = [[decoder decodeObjectForKey:@"model"] retain];
    spectrum = [[decoder decodeObjectForKey:@"spectrum"] retain];
    libraryEntry = [[decoder decodeObjectForKey:@"libraryEntry"] retain];
    unknownCompound = [decoder decodeBoolForKey:@"unknownCompound"];
    peaks = [[decoder decodeObjectForKey:@"peaks"] retain];

    if (version < 1) {
        if (libraryEntry)
            group = [[libraryEntry group] retain];
    } else {
        group = [[decoder decodeObjectForKey:@"group"] retain];
    }       
    
    // If a peak is not found, we'll sadly need to remove it...
    NSMutableArray *keysToDeleteArray = [NSMutableArray arrayWithCapacity:[peaks count]];
    NSString *aKey;
    id peak;
    NSEnumerator *keyEnumerator = [peaks keyEnumerator];
    while (aKey = [keyEnumerator nextObject]) {
        peak = [peaks objectForKey:aKey];
        if(![peak isKindOfClass:[JKPeakRecord class]]) {
            [keysToDeleteArray addObject:aKey];
        }
    }
    if ([keysToDeleteArray count] > 0) {
        JKLogWarning(@"Removing peaks for %@",keysToDeleteArray);
        [peaks removeObjectsForKeys:keysToDeleteArray];
    }
        
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:1 forKey:@"version"];
	[encoder encodeObject:label forKey:@"label"];
    [encoder encodeInt:index forKey:@"index"];
	[encoder encodeObject:symbol forKey:@"symbol"];
	[encoder encodeObject:retentionIndex forKey:@"retentionIndex"];
	[encoder encodeObject:model forKey:@"model"];
	[encoder encodeObject:group forKey:@"group"];
	[encoder encodeObject:spectrum forKey:@"spectrum"];
	[encoder encodeObject:libraryEntry forKey:@"libraryEntry"];
	[encoder encodeObject:peaks forKey:@"peaks"];
	[encoder encodeBool:unknownCompound forKey:@"unknownCompound"];
	[encoder encodeObject:document forKey:@"document"];
}


#pragma mark UNDO
- (NSUndoManager *)undoManager {
    return [[self document] undoManager];
}

#pragma mark ACTIONS
- (void)confirm {
    JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
    
    while ((peak = [peaksEnumerator nextObject])) {
        if ([peak identified] | [peak confirmed]) {
            [peak confirm];
        } else if ([[peak searchResults] count] > 0) {
            [peak identifyAs:[[peak searchResults] objectAtIndex:0]];
            [peak confirm];
        } else {
            JKLogWarning(@"Could not confirm peak %d in document '%@', no search result available.", [peak peakID], [document displayName]);
        }
    }
}

#pragma mark CALCULATED ACCESSORS
- (NSNumber *)certainty {
    int count = 0;
    NSEnumerator *peakEnum = [peaks objectEnumerator];
    JKPeakRecord *peak;

    while ((peak = [peakEnum nextObject]) != nil) {
    	if ([peak confirmed]) {
            count++;
        }
    }
    
    return [NSNumber numberWithFloat:count*1.0f/[self countOfPeaks]];
}
- (NSNumber *)averageRetentionIndex {
    JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + [[peak retentionIndex] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
    
 }
- (NSNumber *)averageSurface {
  	JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + [[peak surface] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)averageHeight {
  	JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + [[peak height] floatValue];
    }
    
    // Calculate average
    return [NSNumber numberWithFloat:sum/[self countOfPeaks]];		
}

- (NSNumber *)standardDeviationRetentionIndex {
	JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    float average = [[self averageRetentionIndex] floatValue];
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + powf(([[peak retentionIndex] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}

- (NSNumber *)standardDeviationSurface {
  	JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    float average = [[self averageSurface] floatValue];
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + powf(([[peak surface] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}
- (NSNumber *)standardDeviationHeight {
   	JKPeakRecord *peak = nil;
	NSEnumerator *peaksEnumerator = [[self peaks] objectEnumerator];
	float sum = 0.0f;
    float average = [[self averageHeight] floatValue];
    
    while ((peak = [peaksEnumerator nextObject])) {
        sum = sum + powf(([[peak height] floatValue] - average),2);
    }
    
    // Calculate deviation
    return [NSNumber numberWithFloat:sqrtf(sum/([self countOfPeaks]-1))];		
}


#pragma mark SPECIAL ACCESSORS
- (id)valueForUndefinedKey:(NSString *)key {
    // Peaks can be accessed using key in the format "file_nn"
    if ([key hasPrefix:@"file_"]) {
//        if ([peaks objectForKey:key]
        return [peaks objectForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Peaks can be set using key in the format "file_nn"
    if ([key hasPrefix:@"file_"]) {
        NSUndoManager *undo = [self undoManager];
        if ([peaks objectForKey:key]) {
            [[undo prepareWithInvocationTarget:peaks] setObject:[peaks objectForKey:key] forKey:key];            
        } else {
            [[undo prepareWithInvocationTarget:peaks] removeObjectForKey:key];
        }

        if (value) {
            [peaks setObject:value forKey:key];            
            if ([value confirmed]) {
                if ([value label] && ![[value label] isEqualToString:@""]) {
                    [self setLabel:[value label]];
                }
                if ([value libraryHit]) {
                    [self setLibraryEntry:[value libraryHit]];
                    [self setSpectrum:[value libraryHit]];   
                    [self setGroup:[[value libraryHit] group]];
                    [self setSymbol:[[value libraryHit] symbol]];
                }
            }
        } else {
            [peaks removeObjectForKey:key];
        }
    } else {
        [super setValue:value forUndefinedKey:key];
    }
}

#pragma mark ACCESSORS
- (JKStatisticsDocument *)document {
	return document;
}
- (void)setDocument:(JKStatisticsDocument *)aDocument {
	document = aDocument;
}

- (NSString *)label {
	return label;
}
- (void)setLabel:(NSString *)aLabel {
    if (aLabel != label) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setLabel:)
                                            object:label];
        
        [label autorelease];
        label = [aLabel retain];
        
        // Set label also for all peaks
        if (aLabel) {
            if (!([aLabel isEqualToString:@""] || [aLabel hasPrefix:NSLocalizedString(@"Unknown compound",@"")])) {
                NSEnumerator *peakEnum = [peaks objectEnumerator];
                JKPeakRecord *peak;
                while (peak = [peakEnum nextObject]) {
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
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setSymbol:)
                                            object:symbol];
        
        [symbol autorelease];
        symbol = [aSymbol retain];
        
        // Set symbol also for all peaks
        NSEnumerator *peakEnum = [peaks objectEnumerator];
        JKPeakRecord *peak;
        while (peak = [peakEnum nextObject]) {
            [peak setSymbol:symbol];
        }
    }
}
- (int)index {
	return index;
}
- (void)setIndex:(int)aIndex {
	index = aIndex;
}


- (NSNumber *)retentionIndex {
	return retentionIndex;
}
- (void)setRetentionIndex:(NSNumber *)aRetentionIndex {
	[retentionIndex autorelease];
	retentionIndex = [aRetentionIndex retain];
}

- (NSString *)model {
	return model;
}
- (void)setModel:(NSString *)aModel {
	[model autorelease];
	model = [aModel retain];
}

- (NSString *)group {
	return group;
}
- (void)setGroup:(NSString *)aGroup {
   if (aGroup != group) {
        [[self undoManager] registerUndoWithTarget:self
                                          selector:@selector(setGroup:)
                                            object:group];
        
       [group autorelease];
       group = [aGroup retain];
       
        // Set group also for all peaks' libraryhits
        NSEnumerator *peakEnum = [peaks objectEnumerator];
        JKPeakRecord *peak;
        while (peak = [peakEnum nextObject]) {
            [[peak libraryHit] setGroup:group];
        }
        [[self libraryEntry] setGroup:group];
    }    
}
- (JKSpectrum *)spectrum {
	return spectrum;
}
- (void)setSpectrum:(JKSpectrum *)aSpectrum {
	[spectrum autorelease];
	spectrum = [aSpectrum retain];
}
- (JKLibraryEntry *)libraryEntry {
	return libraryEntry;
}
- (void)setLibraryEntry:(JKLibraryEntry *)aLibraryEntry {
	[libraryEntry autorelease];
	libraryEntry = [aLibraryEntry retain];
    if ([libraryEntry group]) {
        [self setGroup:[libraryEntry group]];
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
