//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKModelObject.h"
#import "JKComparableProtocol.h"
#import "JKTargetObjectProtocol.h"

@class JKLibraryEntry;
@class JKGCMSDocument;
@class JKPeakRecord;
@class PKSpectrumDataSeries;

@interface JKSpectrum : JKModelObject <NSCoding, JKComparableProtocol, JKTargetObjectProtocol> {
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

- (float)scoreComparedTo:(id <JKComparableProtocol>)inSpectrum;
- (float)scoreComparedTo:(id <JKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (float)oldScoreComparedTo:(id <JKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (NSNumber *)retentionIndex;
- (NSString *)peakTable;

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

@property (getter=masses) float *masses;
@property (assign,getter=peak,setter=setPeak:) JKPeakRecord *peak;
@property (getter=numberOfPoints) int numberOfPoints;
@property (getter=intensities) float *intensities;
@end
