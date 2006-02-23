//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKSpectrum.h"
#import "JKLibraryEntry.h"

@implementation JKSpectrum

#pragma mark INITIALIZATION

- (id) init {
	self = [super init];
	if (self != nil) {
		masses = (float *) malloc(1*sizeof(float));
		intensities = (float *) malloc(1*sizeof(float));
	}
	return self;
}

-(void)dealloc {
	free(masses);
	free(intensities);
	[super dealloc];
}

#pragma mark ACCESSORS
-(int)numberOfPoints {
	return numberOfPoints;
}

-(void)setMasses:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    masses = (float *) realloc(masses, numberOfPoints*sizeof(float));
    memcpy(masses, inArray, numberOfPoints*sizeof(float));
}
-(float *)masses {
    return masses;
}

-(void)setIntensities:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    intensities = (float *) realloc(intensities, numberOfPoints*sizeof(float));
    memcpy(intensities, inArray, numberOfPoints*sizeof(float));
	int i;
	maximumIntensity = intensities[0];
	for (i=1; i < numberOfPoints; i++) {
		if (intensities[i] > maximumIntensity) {
			maximumIntensity = intensities[i];
		}
	}
}
-(float)maximumIntensity {
    return maximumIntensity;
}
-(float *)intensities {
    return intensities;
}
-(void)setRetentionTime:(float)inValue {
	retentionTime = inValue;
}
-(float)retentionTime {
	return retentionTime;
}

-(JKSpectrum *)spectrumBySubtractingSpectrum:(JKSpectrum *)inSpectrum {
	int i,j,k,count1,count2;
	float d1, d2, d3, d4;
	JKSpectrum *outSpectrum = [[JKSpectrum alloc] init];
	count1 = [self numberOfPoints];
	count2 = [inSpectrum numberOfPoints];	
	i=0; j=0; k=0; 
	float *massesIn = [inSpectrum masses];
	float *intensitiesIn = [inSpectrum intensities];
	float massesOut[count1+count2];
	float intensitiesOut[count1+count2];
	float roundd1, roundd2;
	
	do {
		d1 = masses[i];
		d2 = massesIn[i];
		d3 = intensities[i];
		d4 = intensitiesIn[i];
		roundd1 = roundf(d1);
		roundd2 = roundf(d2);
		
		if ((roundd1-roundd2) == 0.0) {
			massesOut[k] = round(d1);
			intensitiesOut[k] = d3-d4;
			
			k++; i++; j++;
		} else if ((roundd1 - roundd2) < 0.0) {
			massesOut[k] = d1;
			intensitiesOut[k] = d3;
			
			k++; i++;
		} else if ((roundd1 - roundd2) > 0.0) {
			massesOut[k] = d2;
			intensitiesOut[k] = -d4;
			
			k++; j++;
		};
	} while (i < count1 && j < count2);
	
	[outSpectrum setMasses:massesOut withCount:k];
	[outSpectrum setIntensities:intensitiesOut withCount:k];
	[outSpectrum autorelease];
	return outSpectrum;
}

-(JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum {
	int i,j,k,count1,count2;
	float d1, d2, d3, d4;
	JKSpectrum *outSpectrum = [[JKSpectrum alloc] init];
	count1 = [self numberOfPoints];
	count2 = [inSpectrum numberOfPoints];	
	i=0; j=0; k=0; 
	float *massesIn = [inSpectrum masses];
	float *intensitiesIn = [inSpectrum intensities];
	float massesOut[count1+count2];
	float intensitiesOut[count1+count2];
	float roundd1, roundd2;
	
	do {
		d1 = masses[i];
		d2 = massesIn[i];
		d3 = intensities[i];
		d4 = intensitiesIn[i];
		roundd1 = roundf(d1);
		roundd2 = roundf(d2);
		
		if ((roundd1-roundd2) == 0.0) {
			massesOut[k] = round(d1);
			intensitiesOut[k] = (d3+d4)/2;
			
			k++; i++; j++;
		} else if ((roundd1 - roundd2) < 0.0) {
			massesOut[k] = d1;
			intensitiesOut[k] = d3;
			
			k++; i++;
		} else if ((round(d1) - round(d2)) > 0.0) {
			massesOut[k] = d2;
			intensitiesOut[k] = d4;
			
			k++; j++;
		};
	} while (i < count1 && j < count2);
	
	[outSpectrum setMasses:massesOut withCount:k];
	[outSpectrum setIntensities:intensitiesOut withCount:k];
	[outSpectrum autorelease];
	return outSpectrum;	
}

-(JKSpectrum *)normalizedSpectrum {
	int i;
	JKSpectrum *outSpectrum = [[JKSpectrum alloc] init];
	float intensitiesOut[numberOfPoints];

	for (i = 0; i < numberOfPoints; i++) {
		intensitiesOut[i] = intensities[i]/maximumIntensity;
	}

	[outSpectrum setMasses:masses withCount:numberOfPoints];
	[outSpectrum setIntensities:intensitiesOut withCount:numberOfPoints];
	[outSpectrum setRetentionTime:retentionTime];
	[outSpectrum autorelease];
	return outSpectrum;
}

-(float)scoreComparedToSpectrum:(JKSpectrum *)inSpectrum {
	return [self scoreComparedToLibraryEntry:inSpectrum];
}

-(float)scoreComparedToLibraryEntry:(JKLibraryEntry *)libraryEntry {
#warning Fails when not set...
	int formulaChoosen = [[[NSUserDefaults standardUserDefaults] valueForKey:@"scoreBasis"] intValue];
	JKLogDebug(@"formulaChoosen = %d", formulaChoosen);
	BOOL penalizeForRetentionIndex = [[[NSUserDefaults standardUserDefaults] valueForKey:@"retentionIndexPenalty"] boolValue];
	
	int i,j,k,count1,count2;
	float score, score2, score3, maxIntensityLibraryEntry, maxIntensitySpectrum;
	i=0; j=0; k=0; 
	score = 0.0;
	score2 = 0.0;
	score3 = 0.0;
	maxIntensityLibraryEntry = [libraryEntry maximumIntensity];
	maxIntensitySpectrum = [self maximumIntensity];
	count1 = [self numberOfPoints];
	count2 = [libraryEntry numberOfPoints];
	float *peakMasses = [self masses];
	float *peakIntensities = [self intensities];
	float *libraryEntryMasses = [libraryEntry masses];
	float *libraryEntryIntensities = [libraryEntry intensities];
	float massDifference;
	BOOL peakMassesAtEnd = NO;
	BOOL libraryEntryMassesAtEnd = NO;
	
	switch (formulaChoosen) {
		case 0: // Using formula 1 in Gan 2001
			while (i < count1 & j < count2) {
				// If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
				if (i >= count1) i = count1-1;
				if (j >= count2) j = count2-1;
				massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
				
				if (massDifference == 0.0) {
					score = score + fabsf((peakIntensities[i]/maxIntensitySpectrum)-(libraryEntryIntensities[j]/maxIntensityLibraryEntry));
					score2 = score2 + fabsf((peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry));
					
					k++; i++; j++;
				} else if (massDifference < 0.0) {
					score = score + fabsf(peakIntensities[i]/maxIntensitySpectrum);
					score2 = score2 + fabsf(peakIntensities[i]/maxIntensitySpectrum);
					
					k++; i++;
				} else if (massDifference > 0.0) {
					score = score + fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					score2 = score2 + fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					
					k++; j++;
				} else {
					// When out of range?!?
					// Keep counting to get us out of it...
					k++; i++; j++;
					JKLogDebug(@"This should not happen ever!! i %d j %d k %d massdif %f mass %f masslib %f inten %f intenlib %f count1 %d count2 %d", i,j,k, massDifference, masses[i], libraryEntryMasses[j], intensities[i], libraryEntryIntensities[j], count1, count2);
				}
			} 
			
			break;
		case 1: // Using formula 2 in Gan 2001
			while (i < count1 & j < count2) {
				// If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
				if (i >= count1) i = count1-1;
				if (j >= count2) j = count2-1;
				massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
				
				if (massDifference == 0.0) {
					if (peakIntensities[i]/maxIntensitySpectrum < 0.02 | libraryEntryIntensities[j]/maxIntensityLibraryEntry < 0.02) {
						score = score + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
						score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
						
					} else {
						score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);					
					}				
					
					k++; i++; j++;
				} else if (massDifference < 0.0) {
					score = score + (peakIntensities[i]/maxIntensitySpectrum);
					score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum);
					
					k++; i++;
				} else if (massDifference > 0.0) {
					score = score + (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					score2 = score2 + (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					
					k++; j++;
				} else {
					// When out of range?!?
					// Keep counting to get us out of it...
					k++; i++; j++;
					JKLogDebug(@"This should not happen ever!! i %d j %d k %d massdif %f mass %f masslib %f inten %f intenlib %f count1 %d count2 %d", i,j,k, massDifference, masses[i], libraryEntryMasses[j], intensities[i], libraryEntryIntensities[j], count1, count2);
				}
			} 
			break;
			
		case 2: // Literature reference search i.e. all peaks in the libentry must be present and intensity is more important
			while (i < count1 & j < count2) {
				// If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
				// If we go out of bounds, we are at the end of the range, which should be handled slightly different for some scores
				if (i >= count1) {
					i = count1-1;
					peakMassesAtEnd = YES;
				} 
				if (j >= count2) {
					 j = count2-1;
					libraryEntryMassesAtEnd = YES;
				}
				// Calculate the difference. Lower than zero means the mass for the peak is "left" for the current library mass.
				massDifference = peakMasses[i] - libraryEntryMasses[j];
				
				if (massDifference == 0.0) {
					score = score + fabsf(peakIntensities[i]/maxIntensitySpectrum - libraryEntryIntensities[j]/maxIntensityLibraryEntry);
						
					k++; i++; j++;
				} else if (massDifference < 0.0) {
					score3 = score3 + peakIntensities[i]/maxIntensitySpectrum;
					
					i++;
				} else if (massDifference > 0.0) {
					if (libraryEntryMassesAtEnd) score3 = score3 + peakIntensities[i]/maxIntensitySpectrum;
					//score = score + fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					j++;
				} else {
					// When out of range?!? Happens when we have an error reading the data, e.g. a NaN value.
					// Keep counting to get us out of it...
					k++; i++; j++;
					JKLogDebug(@"This should not happen ever!! i %d j %d k %d massdif %f mass %f masslib %f inten %f intenlib %f count1 %d count2 %d", i,j,k, massDifference, masses[i], libraryEntryMasses[j], intensities[i], libraryEntryIntensities[j], count1, count2);
				}
			}
			// We penalize for not found libraryentries quite strongly, as those are very bad in a literature search.
			if (k < count2) {
				score = score + count2 - k;
			}
			score2 = count2; 
			// This correction penalizes the score for having to much other high peaks in the chromatogram, which is not expected for literature entries.
			//score = score * score3/count1;
			break;
	}
	
//	JKLogDebug(@"score %f n = %d score = %f score2 = %f", (1.0-score/score2)*100.0, n, score, score2);
	if (penalizeForRetentionIndex) {
		float retentionIndexDelta, retentionIndexPenalty;
		float retentionIndex          = [[libraryEntry valueForKey:@"retentionIndex"] floatValue];
		if (retentionIndex == 0.0 || retentionIndex == nil) {
			return (1.0-score/score2)*90.0;			//10% penalty!!
		}
					
		retentionIndexDelta = retentionIndex - [self observedRetentionIndex];
		retentionIndexPenalty = pow(retentionIndexDelta,2) *  -0.000004 + 1;
		
		return (1.0-score/score2) * retentionIndexPenalty * 100.0; 
	} else {
		return (1.0-score/score2)*100.0;			
	}
}

-(float)observedRetentionIndex {
	float observedRetentionIndex;
	float retentionIndexSlope	  = [[[NSUserDefaults standardUserDefaults] valueForKey:@"retentionIndexSlope"] floatValue];//  = 72.742; //= [[[self document] model] retentionIndexSlope]; 
	float retentionIndexRemainder = [[[NSUserDefaults standardUserDefaults] valueForKey:@"retentionIndexRemainder"] floatValue];// =  178.44; //= [[[self document] model] retentionIndexRemainder];
	
	observedRetentionIndex = [self retentionTime] * retentionIndexSlope + retentionIndexRemainder;
	
	return observedRetentionIndex;
}


@end