//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKLibraryEntry;
@class JKGCMSDocument;
@class JKPeakRecord;
@class SpectrumGraphDataSerie;

@interface JKSpectrum : NSObject <NSCoding> {
	JKGCMSDocument *document;
	JKPeakRecord *peak;
	
	float retentionIndex;

    float minimumIntensity;
    float maximumIntensity;
	float minimumMass;
    float maximumMass;
	
	int numberOfPoints;
	float *masses;
	float *intensities;
}

#pragma mark ACTIONS

- (JKSpectrum *)spectrumBySubtractingSpectrum:(JKSpectrum *)inSpectrum;
- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum;
- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum  withWeight:(float)weight;
- (JKSpectrum *)normalizedSpectrum;

- (SpectrumGraphDataSerie *)spectrumDataSerie;

- (float)scoreComparedToSpectrum:(JKSpectrum *)inSpectrum;
- (float)scoreComparedToLibraryEntry:(JKLibraryEntry *)libraryEntry;

#pragma mark ACCESSORS
- (void)setDocument:(JKGCMSDocument *)inValue;
- (JKGCMSDocument *)document;
- (void)setPeak:(JKPeakRecord *)inValue;
- (JKPeakRecord *)peak;

- (int)numberOfPoints;
- (void)setMasses:(float *)inArray withCount:(int)inValue;
- (float *)masses;
- (void)setIntensities:(float *)inArray withCount:(int)inValue;
- (float *)intensities;
- (void)setRetentionIndex:(float)inValue;
- (float)retentionIndex;

- (float)minimumMass;
- (float)maximumMass;
- (float)minimumIntensity;
- (float)maximumIntensity;

@end
