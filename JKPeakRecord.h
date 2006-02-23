//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKMainDocument;
@class JKSpectrum;
@class JKLibraryEntry;

@interface JKPeakRecord : NSObject {
    NSNumber *peakID;

	// Set during peak identification
    NSNumber *start;
    NSNumber *end;
    NSNumber *top;
    NSNumber *startTime;
    NSNumber *endTime;
	NSNumber *topTime;
    NSNumber *width;
    NSNumber *widthTime;
    NSNumber *height;
    NSNumber *baselineL;
    NSNumber *baselineR;
    NSNumber *surface;
	NSNumber *normalizedSurface;
	NSNumber *normalizedHeight;
	
	// Set during compound identification
	NSString *label;
	NSString *symbol;
	BOOL identified;
	BOOL confirmed;
	NSNumber *score;
	NSString *library;
	JKLibraryEntry *libraryHit;
	NSNumber *retentionIndex;
}

# pragma mark INITIALIZATION

# pragma mark ACCESSORS

-(void)setPeakID:(NSNumber *)inValue;
-(NSNumber *)peakID;

-(void)setLabel:(NSString *)inValue;
-(NSString *)label;

-(void)setSymbol:(NSString *)inValue;
-(NSString *)symbol;

-(void)setStartTime:(NSNumber *)inValue;
-(NSNumber *)startTime;

-(void)setEndTime:(NSNumber *)inValue;
-(NSNumber *)endTime;

-(void)setWidth:(NSNumber *)inValue;
-(NSNumber *)width;

-(void)setHeight:(NSNumber *)inValue;
-(NSNumber *)height;

-(void)setNormalizedHeight:(NSNumber *)inValue;
-(NSNumber *)normalizedHeight;

-(void)setBaselineL:(NSNumber *)inValue;
-(NSNumber *)baselineL;

-(void)setBaselineR:(NSNumber *)inValue;
-(NSNumber *)baselineR;

-(void)setSurface:(NSNumber *)inValue;
-(NSNumber *)surface;

-(void)setNormalizedSurface:(NSNumber *)inValue;
-(NSNumber *)normalizedSurface;

-(void)setTop:(NSNumber *)inValue;
-(NSNumber *)top;

-(void)setTopTime:(NSNumber *)inValue;
-(NSNumber *)topTime;

-(void)setStart:(NSNumber *)inValue;
-(NSNumber *)start;

-(void)setEnd:(NSNumber *)inValue;
-(NSNumber *)end;

-(void)setIdentified:(BOOL)inValue;
-(BOOL)identified;

-(void)setConfirmed:(BOOL)inValue;
-(BOOL)confirmed;

-(void)setLibrary:(NSString *)inValue;
-(NSString *)library;

-(void)setLibraryHit:(JKLibraryEntry *)inValue;
-(JKLibraryEntry *)libraryHit;

-(void)setRetentionIndex:(NSNumber *)inValue;
-(NSNumber *)retentionIndex;

//-(void)setDeltaRetentionIndex:(NSNumber *)inValue;
-(NSNumber *)deltaRetentionIndex;

-(void)setScore:(NSNumber *)inValue;
-(NSNumber *)score;

-(void)setWidthTime:(NSNumber *)inValue;
-(NSNumber *)widthTime;

@end
