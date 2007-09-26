//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKModelObject.h"
#import "JKComparableProtocol.h"
#import "JKTargetObjectProtocol.h"

@class JKLibraryEntry;
@class JKGCMSDocument;
@class PKPeak;
@class SpectrumGraphDataSerie;

@interface JKSpectrum : PKModelObject <NSCoding, JKComparableProtocol, JKTargetObjectProtocol> {
	PKPeak *peak;
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

- (float)scoreComparedTo:(id <JKComparableProtocol>)inSpectrum;
- (float)scoreComparedTo:(id <JKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;

- (NSNumber *)retentionIndex;
- (NSString *)peakTable;

#pragma mark ACCESSORS
- (JKGCMSDocument *)document;
- (void)setPeak:(PKPeak *)inValue;
- (PKPeak *)peak;
- (NSString *)model;
- (void)setModel:(NSString *)aString;
- (int)numberOfPoints;
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;
- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;

@property (getter=numberOfPoints) int numberOfPoints;
@property (getter=masses) float *masses;
@property (assign,getter=peak,setter=setPeak:) PKPeak *peak;
@property (getter=intensities) float *intensities;
@end
