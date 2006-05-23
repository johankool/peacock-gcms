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

- (NSString *)description  
{
	return [NSString stringWithFormat:@"JKPeakRecord: %@ (top: %f)", [self label], [[self topTime] floatValue]];
}

- (id)init  
{
	self = [super init];
	if (self != nil) {
		searchResults = [[NSMutableArray alloc] init];
    }
    return self;	
}

#pragma mark CALCULATED ACCESSORS

- (NSNumber *)deltaRetentionIndex  
{
	float value = 0.0;
	if (([libraryHit retentionIndex] == nil) | ([[libraryHit retentionIndex] floatValue] == 0.0)) {
		return [NSNumber numberWithFloat:0.0];
	}
	value = [[libraryHit retentionIndex] floatValue] - [[self retentionIndex] floatValue];
    return [NSNumber numberWithFloat:value];
}

#pragma mark ACCESSORS

- (void)setPeakID:(NSNumber *)inValue  
{
	[inValue retain];
	[peakID autorelease];
	peakID = inValue;
}
- (NSNumber *)peakID  
{
    return peakID;
}
- (void)setDocument:(JKGCMSDocument *)inValue  
{
	// Weak link
	document = inValue;
}
- (JKGCMSDocument *)document  
{
    return document;
}

- (void)setScore:(NSNumber *)inValue  
{
	[inValue retain];
	[score autorelease];
	score = inValue;
}

- (NSNumber *)score  
{
    return score;
}


- (void)setLabel:(NSString *)inValue  
{
	[inValue retain];
	[label autorelease];
	label = inValue;
}

- (NSString *)label  
{
    return label;
}

- (void)setSymbol:(NSString *)inValue  
{
	[inValue retain];
	[symbol autorelease];
	symbol = inValue;
}

- (NSString *)symbol  
{
    return symbol;
} 

- (void)setTopTime:(NSNumber *)inValue  
{
	[inValue retain];
	[topTime autorelease];
	topTime = inValue;
}

- (NSNumber *)topTime  
{
    return topTime;
}


- (void)setHeight:(NSNumber *)inValue  
{
	[inValue retain];
	[height autorelease];
	height = inValue;
}

- (NSNumber *)height  
{
    return height;
}

- (void)setBaselineLeft:(NSNumber *)inValue  
{
	[inValue retain];
	[baselineLeft autorelease];
	baselineLeft = inValue;
}

- (NSNumber *)baselineLeft
{
    return baselineLeft;
}

- (void)setBaselineRight:(NSNumber *)inValue  
{
	[inValue retain];
	[baselineRight autorelease];
	baselineRight = inValue;
}

- (NSNumber *)baselineRight 
{
    return baselineRight;
}

- (void)setBaselineLeftTime:(NSNumber *)inValue  
{
	[inValue retain];
	[baselineLeftTime autorelease];
	baselineLeftTime = inValue;
}

- (NSNumber *)baselineLeftTime
{
    return baselineLeftTime;
}

- (void)setBaselineRightTime:(NSNumber *)inValue  
{
	[inValue retain];
	[baselineRightTime autorelease];
	baselineRightTime = inValue;
}

- (NSNumber *)baselineRightTime
{
    return baselineRightTime;
}

- (void)setSurface:(NSNumber *)inValue  
{
	[inValue retain];
	[surface autorelease];
	surface = inValue;
}

- (NSNumber *)surface  
{
    return surface;
}

- (void)setSearchResults:(NSMutableArray *)inValue  
{
	[inValue retain];
	[searchResults autorelease];
	searchResults = inValue;
}

- (NSMutableArray *)searchResults  
{
    return searchResults;
}

- (void)setTop:(NSNumber *)inValue  
{
	[inValue retain];
	[top autorelease];
	top = inValue;
}

- (NSNumber *)top  
{
    return top;
}

- (void)setStart:(NSNumber *)inValue  
{
	[inValue retain];
	[start autorelease];
	start = inValue;
}

- (NSNumber *)start  
{
    return start;
}

- (void)setEnd:(NSNumber *)inValue  
{
	[inValue retain];
	[end autorelease];
	end = inValue;
}

- (NSNumber *)end  
{
    return end;
}

- (void)setSpectrum:(JKSpectrum *)inValue  
{
	[inValue retain];
	[spectrum autorelease];
	spectrum = inValue;
}

- (JKSpectrum *)spectrum  
{
    return spectrum;
}


- (void)setIdentified:(BOOL)inValue  
{
	identified = inValue;
}

- (BOOL)identified  
{
    return identified;
}

- (void)setConfirmed:(BOOL)inValue  
{
	confirmed = inValue;
}

- (BOOL)confirmed  
{
    return confirmed;
}

- (void)setLibrary:(NSString *)inValue  
{
	[inValue retain];
	[library release];
	library = inValue;
}
- (NSString *)library  
{
	return library;
}

- (void)setLibraryHit:(JKLibraryEntry *)inValue  
{
	[inValue retain];
	[libraryHit release];
	libraryHit = inValue;
}
- (JKLibraryEntry *)libraryHit  
{
	return libraryHit;
}

- (void)setRetentionIndex:(NSNumber *)inValue  
{
	[inValue retain];
	[retentionIndex autorelease];
	retentionIndex = inValue;
}

- (NSNumber *)retentionIndex  
{
    return retentionIndex;
}

- (void)setNormalizedHeight:(NSNumber *)inValue
{
	[inValue retain];
	[normalizedHeight autorelease];
	normalizedHeight = inValue;
	
}
- (NSNumber *)normalizedHeight
{
	return normalizedHeight;
}
- (void)setNormalizedSurface:(NSNumber *)inValue
{
	[inValue retain];
	[normalizedSurface autorelease];
	normalizedSurface = inValue;
	
}
- (NSNumber *)normalizedSurface {
	return normalizedSurface;
}

#pragma mark NSCODING

- (void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeInt:2 forKey:@"version"];
		[coder encodeConditionalObject:document forKey:@"document"]; // weak reference
		[coder encodeObject:peakID forKey:@"peakID"];
		[coder encodeObject:start forKey:@"start"];
        [coder encodeObject:end forKey:@"end"];
        [coder encodeObject:top forKey:@"top"];
        [coder encodeObject:topTime forKey:@"topTime"];
        [coder encodeObject:height forKey:@"height"];
        [coder encodeObject:baselineLeft forKey:@"baselineLeft"];
        [coder encodeObject:baselineRight forKey:@"baselineRight"];
        [coder encodeObject:surface forKey:@"surface"];
        [coder encodeObject:label forKey:@"label"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeBool:identified forKey:@"identified"];
		[coder encodeBool:confirmed forKey:@"confirmed"];
        [coder encodeObject:score forKey:@"score"];
        [coder encodeObject:libraryHit forKey:@"libraryHit"];
		[coder encodeObject:retentionIndex forKey:@"retentionIndex"];
		[coder encodeObject:searchResults forKey:@"searchResults"];
		[coder encodeObject:spectrum forKey:@"spectrum"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		document = [coder decodeObjectForKey:@"document"]; // weak reference
		peakID = [[coder decodeObjectForKey:@"peakID"] retain];
		start = [[coder decodeObjectForKey:@"start"] retain];
        end = [[coder decodeObjectForKey:@"end"] retain];
        top = [[coder decodeObjectForKey:@"top"] retain];
        height = [[coder decodeObjectForKey:@"height"] retain];
        baselineLeft = [[coder decodeObjectForKey:@"baselineLeft"] retain];
        baselineRight = [[coder decodeObjectForKey:@"baselineRight"] retain];
        surface = [[coder decodeObjectForKey:@"surface"] retain];
        label = [[coder decodeObjectForKey:@"label"] retain];
		symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
		confirmed = [coder decodeBoolForKey:@"confirmed"];
        score = [[coder decodeObjectForKey:@"score"] retain];
        libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain];
		retentionIndex = [[coder decodeObjectForKey:@"retentionIndex"] retain];
		searchResults = [[coder decodeObjectForKey:@"searchResults"] retain];
		spectrum = [[coder decodeObjectForKey:@"spectrum"] retain];
	} 
    return self;
}

@end
