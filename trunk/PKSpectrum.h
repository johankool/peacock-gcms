//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKModelObject.h"
#import "PKComparableProtocol.h"
#import "PKTargetObjectProtocol.h"

@class PKLibraryEntry;
@class PKGCMSDocument;
@class PKPeakRecord;
@class PKSpectrumDataSeries;

@interface PKSpectrum : PKModelObject <NSCoding, PKComparableProtocol, PKTargetObjectProtocol> {
	PKPeakRecord *peak;
	NSString *model;
    	
	int numberOfPoints;
	float *masses;
	float *intensities;
    BOOL combined;
}

- (id)initWithModel:(NSString *)modelString;

#pragma mark ACTIONS

- (PKSpectrum *)spectrumBySubtractingSpectrum:(PKSpectrum *)inSpectrum;
- (PKSpectrum *)spectrumByAveragingWithSpectrum:(PKSpectrum *)inSpectrum;
- (PKSpectrum *)spectrumByAveragingWithSpectrum:(PKSpectrum *)inSpectrum  withWeight:(float)weight;
- (PKSpectrum *)normalizedSpectrum;

- (float)scoreComparedTo:(id <PKComparableProtocol>)inSpectrum;
- (float)scoreComparedTo:(id <PKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (float)oldScoreComparedTo:(id <PKComparableProtocol>)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex;
- (NSNumber *)retentionIndex;
- (NSString *)peakTable;
- (NSString *)legendEntry;
    
#pragma mark ACCESSORS
- (PKGCMSDocument *)document;
- (void)setPeak:(PKPeakRecord *)inValue;
- (PKPeakRecord *)peak;
- (NSString *)model;
- (void)setModel:(NSString *)aString;
- (int)numberOfPoints;
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;
- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;
- (BOOL)combined;
- (void)setCombined:(BOOL)inValue;

@property (getter=masses) float *masses;
@property (assign,getter=peak,setter=setPeak:) PKPeakRecord *peak;
@property (getter=numberOfPoints) int numberOfPoints;
@property (getter=intensities) float *intensities;
@end
