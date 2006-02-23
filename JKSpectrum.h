//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKSpectrum;
@class JKLibraryEntry;

@interface JKSpectrum : NSObject {
	float retentionTime;
    float maximumIntensity;
	
	int numberOfPoints;
	float *masses;
	float *intensities;
 }

-(JKSpectrum *)spectrumBySubtractingSpectrum:(JKSpectrum *)inSpectrum;
-(JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum;
-(JKSpectrum *)normalizedSpectrum;

-(float)scoreComparedToSpectrum:(JKSpectrum *)inSpectrum;
-(float)scoreComparedToLibraryEntry:(JKLibraryEntry *)libraryEntry;
-(float)observedRetentionIndex;

#pragma mark ACCESSORS
-(int)numberOfPoints;
-(void)setMasses:(float *)inArray withCount:(int)inValue;
-(float *)masses;
-(void)setIntensities:(float *)inArray withCount:(int)inValue;
-(float *)intensities;
-(float)maximumIntensity;
-(void)setRetentionTime:(float)inValue;
-(float)retentionTime;


@end
