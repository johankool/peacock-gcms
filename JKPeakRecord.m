//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPeakRecord.h"
#import "JKLibraryEntry.h"

@implementation JKPeakRecord

# pragma mark INITIALIZATION

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"topTime",@"retentionIndex",@"libraryHit",nil] triggerChangeNotificationsForDependentKey:@"deltaRetentionIndex"];
//    [self setKeys:[NSArray arrayWithObjects:@"end",nil] triggerChangeNotificationsForDependentKey:@"endTime"];
//    [self setKeys:[NSArray arrayWithObjects:@"start",@"end",nil] triggerChangeNotificationsForDependentKey:@"width"];
//    [self setKeys:[NSArray arrayWithObjects:@"start",@"end",@"baselineL",@"baselineR",nil] triggerChangeNotificationsForDependentKey:@"height"];
//    [self setKeys:[NSArray arrayWithObjects:@"start",@"end",nil] triggerChangeNotificationsForDependentKey:@"top"];
//    [self setKeys:[NSArray arrayWithObjects:@"start",@"end",nil] triggerChangeNotificationsForDependentKey:@"topTime"];
//    [self setKeys:[NSArray arrayWithObjects:@"start",@"end",@"baselineL",@"baselineR",nil] triggerChangeNotificationsForDependentKey:@"surface"];
}

-(NSString *)description {
	return [NSString stringWithFormat:@"JKPeakRecord: %@ (top: %f)", [self label], [[self topTime] floatValue]];
}

-(id)init {
	self = [super init];
	if (self != nil) {
		// Set so it ain't nil?
		[self setLibraryHit:[[JKLibraryEntry alloc] init]];
    }
    return self;	
}

#pragma mark ACCESSORS

-(void)setPeakID:(NSNumber *)inValue {
	[inValue retain];
	[peakID autorelease];
	peakID = inValue;
}

-(NSNumber *)peakID {
    return peakID;
}

-(void)setScore:(NSNumber *)inValue {
	[inValue retain];
	[score autorelease];
	score = inValue;
}

-(NSNumber *)score {
    return score;
}

-(void)setWidthTime:(NSNumber *)inValue {
	[inValue retain];
	[widthTime autorelease];
	widthTime = inValue;
}

-(NSNumber *)widthTime {
    return widthTime;
}

-(void)setLabel:(NSString *)inValue {
	[inValue retain];
	[label autorelease];
	label = inValue;
}

-(NSString *)label {
    return label;
}

-(void)setSymbol:(NSString *)inValue {
	[inValue retain];
	[symbol autorelease];
	symbol = inValue;
}

-(NSString *)symbol {
    return symbol;
}

-(void)setStartTime:(NSNumber *)inValue {
	[inValue retain];
	[startTime autorelease];
	startTime = inValue;
}

-(NSNumber *)startTime {	
    return startTime;
}
 

-(void)setEndTime:(NSNumber *)inValue {
	[inValue retain];
	[endTime autorelease];
	endTime = inValue;
}

-(NSNumber *)endTime {
    return endTime;
}

-(void)setTopTime:(NSNumber *)inValue {
	[inValue retain];
	[topTime autorelease];
	topTime = inValue;
}

-(NSNumber *)topTime {
    return topTime;
}


-(void)setWidth:(NSNumber *)inValue {
	[inValue retain];
	[width autorelease];
	width = inValue;
}

-(NSNumber *)width {
    return width;
}

-(void)setHeight:(NSNumber *)inValue {
	[inValue retain];
	[height autorelease];
	height = inValue;
}

-(NSNumber *)height {
    return height;
}

-(void)setNormalizedHeight:(NSNumber *)inValue {
	[inValue retain];
	[normalizedHeight autorelease];
	normalizedHeight = inValue;
}

-(NSNumber *)normalizedHeight {
    return normalizedHeight;
}
-(void)setBaselineL:(NSNumber *)inValue {
	[inValue retain];
	[baselineL autorelease];
	baselineL = inValue;
}

-(NSNumber *)baselineL {
    return baselineL;
}

-(void)setBaselineR:(NSNumber *)inValue {
	[inValue retain];
	[baselineR autorelease];
	baselineR = inValue;
}

-(NSNumber *)baselineR {
    return baselineR;
}

-(void)setSurface:(NSNumber *)inValue {
	[inValue retain];
	[surface autorelease];
	surface = inValue;
}

-(NSNumber *)surface {
    return surface;
}
-(void)setNormalizedSurface:(NSNumber *)inValue {
	[inValue retain];
	[normalizedSurface autorelease];
	normalizedSurface = inValue;
}

-(NSNumber *)normalizedSurface {
    return normalizedSurface;
}

-(void)setTop:(NSNumber *)inValue {
	[inValue retain];
	[top autorelease];
	top = inValue;
}

-(NSNumber *)top {
    return top;
}

-(void)setStart:(NSNumber *)inValue {
	[inValue retain];
	[start autorelease];
	start = inValue;
}

-(NSNumber *)start {
    return start;
}

-(void)setEnd:(NSNumber *)inValue {
	[inValue retain];
	[end autorelease];
	end = inValue;
}

-(NSNumber *)end {
    return end;
}

-(void)setIdentified:(BOOL)inValue {
	identified = inValue;
}

-(BOOL)identified {
    return identified;
}

-(void)setConfirmed:(BOOL)inValue {
	confirmed = inValue;
}

-(BOOL)confirmed {
    return confirmed;
}

-(void)setLibrary:(NSString *)inValue {
	[inValue retain];
	[library release];
	library = inValue;
}
-(NSString *)library {
	return library;
}

-(void)setLibraryHit:(JKLibraryEntry *)inValue {
	[inValue retain];
	[libraryHit release];
	libraryHit = inValue;
}
-(JKLibraryEntry *)libraryHit {
	return libraryHit;
}

//-(void)setDeltaRetentionIndex:(NSNumber *)inValue {
//	// = rti lib hit minus rti peak (@ top)
//	[inValue retain];
//	[deltaRetentionIndex autorelease];
//	deltaRetentionIndex = inValue;
//}

-(NSNumber *)deltaRetentionIndex {
	float value = 0.0;
	if ([libraryHit retentionIndex] == nil) {
		return [NSNumber numberWithFloat:0.0];
	}
	value = [libraryHit retentionIndex] - [[self retentionIndex] floatValue];
    return [NSNumber numberWithFloat:value];
}

-(void)setRetentionIndex:(NSNumber *)inValue {
	[inValue retain];
	[retentionIndex autorelease];
	retentionIndex = inValue;
}

-(NSNumber *)retentionIndex {
    return retentionIndex;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeObject:peakID forKey:@"peakID"];
		[coder encodeObject:start forKey:@"start"];
        [coder encodeObject:end forKey:@"end"];
        [coder encodeObject:top forKey:@"top"];
        [coder encodeObject:startTime forKey:@"startTime"];
        [coder encodeObject:endTime forKey:@"endTime"];
        [coder encodeObject:topTime forKey:@"topTime"];
        [coder encodeObject:width forKey:@"width"];
        [coder encodeObject:widthTime forKey:@"widthTime"];
        [coder encodeObject:height forKey:@"height"];
        [coder encodeObject:normalizedHeight forKey:@"normalizedHeight"];
        [coder encodeObject:baselineL forKey:@"baselineL"];
        [coder encodeObject:baselineR forKey:@"baselineR"];
        [coder encodeObject:surface forKey:@"surface"];
        [coder encodeObject:normalizedSurface forKey:@"normalizedSurface"];
        [coder encodeObject:label forKey:@"label"];
        [coder encodeObject:symbol forKey:@"symbol"];
        [coder encodeBool:identified forKey:@"identified"];
		[coder encodeBool:confirmed forKey:@"confirmed"];
        [coder encodeObject:score forKey:@"score"];
        [coder encodeObject:libraryHit forKey:@"libraryHit"];
		[coder encodeObject:retentionIndex forKey:@"retentionIndex"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		peakID = [[coder decodeObjectForKey:@"peakID"] retain];
		start = [[coder decodeObjectForKey:@"start"] retain];
        end = [[coder decodeObjectForKey:@"end"] retain];
        top = [[coder decodeObjectForKey:@"top"] retain];
        startTime = [[coder decodeObjectForKey:@"startTime"] retain];
        endTime = [[coder decodeObjectForKey:@"endTime"] retain];
        topTime = [[coder decodeObjectForKey:@"topTime"] retain];
        width = [[coder decodeObjectForKey:@"width"] retain];
        widthTime = [[coder decodeObjectForKey:@"widthTime"] retain];
        height = [[coder decodeObjectForKey:@"height"] retain];
        normalizedHeight = [[coder decodeObjectForKey:@"normalizedHeight"] retain];
        baselineL = [[coder decodeObjectForKey:@"baselineL"] retain];
        baselineR = [[coder decodeObjectForKey:@"baselineR"] retain];
        surface = [[coder decodeObjectForKey:@"surface"] retain];
        normalizedSurface = [[coder decodeObjectForKey:@"normalizedSurface"] retain];
#warning Stupid fixing code in place!
		NSString *fixedString = [[coder decodeObjectForKey:@"label"] lowercaseString];
		if ([fixedString length] > 1) {
			NSRange range4 = [fixedString rangeOfString:@"/"]; // don't swap, because probably two names are given
			if (range4.location == NSNotFound){
				// Swapping phenol stuff
				NSRange range = [fixedString rangeOfString:@", "];
				if (range.location != NSNotFound){
					NSRange range3 = [[fixedString substringToIndex:range.location] rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
					if ((range3.location == 0) && (![[fixedString substringWithRange:NSMakeRange([fixedString length]-2,1)] isEqualToString:@")"])){
						fixedString = [NSString stringWithFormat:@"%@%@", [[fixedString substringFromIndex:range.location+2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]], [fixedString substringToIndex:range.location]];
					} else {
						fixedString = [NSString stringWithFormat:@"%@%@", [fixedString substringFromIndex:range.location+2], [fixedString substringToIndex:range.location]];
						
					}
				}
			}
		// Capitalize first letter only
		//NSRange range2 = NSMakeRange(0,1);
		NSRange range2 = [fixedString rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]];
		fixedString = [NSString stringWithFormat:@"%@%@%@", [fixedString substringToIndex:range2.location], [[fixedString substringWithRange:range2] uppercaseString], [fixedString substringFromIndex:range2.location+1]];
		//fixedString = [fixedString capitalizedString];
	}		
		if ([fixedString length] > 1) {

		NSRange range5 = [fixedString rangeOfString:@"N-c"]; //fizx n-alk
		if (range5.location == 0){
			fixedString = [NSString stringWithFormat:@"n-C%@", [fixedString substringFromIndex:3]];
		}
		}
        label = [fixedString retain];
#warning End of Stupid fixing code in place!
//        label = [[coder decodeObjectForKey:@"label"] retain];
		
		
        symbol = [[coder decodeObjectForKey:@"symbol"] retain];
        identified = [coder decodeBoolForKey:@"identified"];
		confirmed = [coder decodeBoolForKey:@"confirmed"];
        score = [[coder decodeObjectForKey:@"score"] retain];
        libraryHit = [[coder decodeObjectForKey:@"libraryHit"] retain];
		retentionIndex = [[coder decodeObjectForKey:@"retentionIndex"] retain];
    } 
    return self;
}

@end
