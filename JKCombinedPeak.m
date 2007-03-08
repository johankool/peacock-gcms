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

    label= [[decoder decodeObjectForKey:@"label"] retain];
    symbol= [[decoder decodeObjectForKey:@"symbol"] retain];
    retentionIndex = [[decoder decodeObjectForKey:@"retentionIndex"] retain];
    model = [[decoder decodeObjectForKey:@"model"] retain];
    spectrum = [[decoder decodeObjectForKey:@"spectrum"] retain];
    libraryEntry = [[decoder decodeObjectForKey:@"libraryEntry"] retain];
    peaks = [[decoder decodeObjectForKey:@"peaks"] retain];
    unknownCompound = [decoder decodeBoolForKey:@"unknownCompound"];
    document = [[decoder decodeObjectForKey:@"document"] retain];
    
	return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:0 forKey:@"version"];
	[encoder encodeObject:label forKey:@"label"];
	[encoder encodeObject:symbol forKey:@"symbol"];
	[encoder encodeObject:retentionIndex forKey:@"retentionIndex"];
	[encoder encodeObject:model forKey:@"model"];
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
- (NSNumber *)standardDeviatioHeight {
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
        return [peaks objectForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    // Peaks can be set using key in the format "file_nn"
    if ([key hasPrefix:@"file_"]) {
        if (value) {
            [peaks setObject:value forKey:key];            
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
	[label autorelease];
	label = [aLabel retain];
}
- (NSNumber *)symbol {
	return symbol;
}
- (void)setSymbol:(NSNumber *)aSymbol {
	[symbol autorelease];
	symbol = [aSymbol retain];
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
