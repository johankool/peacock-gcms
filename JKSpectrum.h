//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKModelObject.h"

@class JKLibraryEntry;
@class JKGCMSDocument;
@class JKPeakRecord;
@class SpectrumGraphDataSerie;

@interface JKSpectrum : JKModelObject <NSCoding> {
	JKPeakRecord *peak;
	NSString *model;
    	
	int numberOfPoints;
	float *masses;
	float *intensities;
}

- (id)initWithModel:(NSString *)modelString;

#pragma mark ACTIONS

- (JKSpectrum *)spectrumBySubtractingSpectrum:(JKSpectrum *)inSpectrum;
- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum;
- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum  withWeight:(float)weight;
- (JKSpectrum *)normalizedSpectrum;

- (float)scoreComparedToSpectrum:(JKSpectrum *)inSpectrum;
- (float)scoreComparedToLibraryEntry:(JKSpectrum *)libraryEntry;
- (float)scoreComparedToSpectrum:(JKSpectrum *)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;

- (NSNumber *)retentionIndex;

#pragma mark ACCESSORS
- (JKGCMSDocument *)document;
- (void)setPeak:(JKPeakRecord *)inValue;
- (JKPeakRecord *)peak;
- (NSString *)model;
- (void)setModel:(NSString *)aString;
- (int)numberOfPoints;
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;
- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;

@end
