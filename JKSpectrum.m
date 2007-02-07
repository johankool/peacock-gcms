//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKSpectrum.h"

#import "JKLibraryEntry.h"
#import "jk_statistics.h"
#import "JKGCMSDocument.h"
#import "JKPeakRecord.h"
#import "SpectrumGraphDataSerie.h"

@implementation JKSpectrum

#pragma mark INITIALIZATION

+ (void)initialize {
    [self setKeys:[NSArray arrayWithObjects:@"masses",nil] triggerChangeNotificationsForDependentKey:@"minimumMass"];
    [self setKeys:[NSArray arrayWithObjects:@"masses",nil] triggerChangeNotificationsForDependentKey:@"maximumMass"];
    [self setKeys:[NSArray arrayWithObjects:@"intensities",nil] triggerChangeNotificationsForDependentKey:@"minimumIntensity"];
    [self setKeys:[NSArray arrayWithObjects:@"intensities",nil] triggerChangeNotificationsForDependentKey:@"maximumIntensity"];
}

- (id) init {
	return [self initWithDocument:nil forModel:@""];
}


- (id)initWithDocument:(JKGCMSDocument *)inDocument forModel:(NSString *)modelString {
    self = [super init];
	if (self != nil) {
		masses = (float *) malloc(1*sizeof(float));
		intensities = (float *) malloc(1*sizeof(float));
        [self setDocument:inDocument];
        NSAssert(modelString, @"modelString is nil");
        [self setModel:modelString];
	}
	return self;
}

- (void)dealloc {
	free(masses);
	free(intensities);
	[super dealloc];
}

#pragma mark ACCESSORS
- (void)setDocument:(JKGCMSDocument *)inValue {
	// Weak reference
	document = inValue;
}
- (JKGCMSDocument *)document {
    return document;
}

- (NSString *)model {
    return model;
}
- (void)setModel:(NSString *)inString {
    if (inString != model) {
        [inString retain];
        [model autorelease];
        model = inString;        
    }
}

- (void)setPeak:(JKPeakRecord *)inValue {
	// Weak reference
	peak = inValue;
}
- (JKPeakRecord *)peak {
    return peak;
}

- (int)numberOfPoints {
	return numberOfPoints;
}

- (void)setMasses:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    masses = (float *) realloc(masses, numberOfPoints*sizeof(float));
    memcpy(masses, inArray, numberOfPoints*sizeof(float));
}
- (float *)masses {
    return masses;
}

- (void)setIntensities:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    intensities = (float *) realloc(intensities, numberOfPoints*sizeof(float));
    memcpy(intensities, inArray, numberOfPoints*sizeof(float));
}

- (float *)intensities {
    return intensities;
}
//- (void)setRetentionIndex:(float)inValue {
//	retentionIndex = inValue;
//}
//- (float)retentionIndex {
//	return retentionIndex;
//}
//
//- (float)minimumMass {
//    return minimumMass;
//}
//- (float)maximumMass {
//    return maximumMass;
//}
//- (float)minimumIntensity {
//    return minimumIntensity;
//}
//- (float)maximumIntensity {
//    return maximumIntensity;
//}

- (JKSpectrum *)spectrumBySubtractingSpectrum:(JKSpectrum *)inSpectrum {
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
	[outSpectrum setModel:[NSString stringWithFormat:@"%@ - %@",[self model], [inSpectrum model]]];
    
	do {
		d1 = masses[i];
		d2 = massesIn[j];
		d3 = intensities[i];
		d4 = intensitiesIn[j];
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

- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum {
	return [self spectrumByAveragingWithSpectrum:inSpectrum withWeight:0.5];	
}

// the higher the weight the more import the incoming spectrum
- (JKSpectrum *)spectrumByAveragingWithSpectrum:(JKSpectrum *)inSpectrum  withWeight:(float)weight{
    NSAssert(weight >= 0.0, @"Weight value below 0.0");
    NSAssert(weight <= 1.0, @"Weight value above 1.0");
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
	float roundd1, roundd2, diff;
	float counterweight = 1.0 - weight;
	[outSpectrum setModel:[NSString stringWithFormat:@"(%g %@ + %g %@)", counterweight, [self model], weight, [inSpectrum model]]];

	do {
		d1 = masses[i];
		d2 = massesIn[j];
		d3 = intensities[i] * counterweight;
		d4 = intensitiesIn[j] * weight;
		roundd1 = roundf(d1);
		roundd2 = roundf(d2);
		diff = roundd1 - roundd2;
        
		if (diff == 0.0) {
			massesOut[k] = round(d1);
			intensitiesOut[k] = d3+d4;
			
			k++; i++; j++;
		} else if (diff < 0.0) {
			massesOut[k] = d1;
			intensitiesOut[k] = d3;
			
			k++; i++;
		} else if (diff > 0.0) {
			massesOut[k] = d2;
			intensitiesOut[k] = d4;
			
			k++; j++;
		} else {
            NSLog(@"unexpected error in JKSpectrum spectrumByAveragingWithSpectrum");
            i++; j++;
        };
	} while (i < count1 && j < count2);
	
	[outSpectrum setMasses:massesOut withCount:k];
	[outSpectrum setIntensities:intensitiesOut withCount:k];
	[outSpectrum autorelease];
	return outSpectrum;	
}

- (JKSpectrum *)normalizedSpectrum {
	int i;
	JKSpectrum *outSpectrum = [[JKSpectrum alloc] init];
	float intensitiesOut[numberOfPoints];
    float maximumIntensity = jk_stats_float_max(intensities,numberOfPoints);
    
	for (i = 0; i < numberOfPoints; i++) {
		intensitiesOut[i] = intensities[i]/maximumIntensity;
	}

    [outSpectrum setPeak:[self peak]];
    [outSpectrum setModel:[self model]];
    [outSpectrum setDocument:[self document]];
	[outSpectrum setMasses:masses withCount:numberOfPoints];
	[outSpectrum setIntensities:intensitiesOut withCount:numberOfPoints];
	[outSpectrum autorelease];
	return outSpectrum;
}

- (float)scoreComparedToSpectrum:(JKSpectrum *)inSpectrum {
	return [self scoreComparedToLibraryEntry:(JKLibraryEntry *)inSpectrum];
}

- (float)scoreComparedToLibraryEntry:(JKSpectrum *)libraryEntry { 
    return [self scoreComparedToSpectrum:libraryEntry usingMethod:[[self document] scoreBasis] penalizingForRententionIndex:[[self document] penalizeForRetentionIndex]];
}
//#pragma mark optimization_level 3

- (float)scoreComparedToSpectrum:(JKSpectrum *)libraryEntry usingMethod:(int)scoreBasis penalizingForRententionIndex:(BOOL)penalizeForRetentionIndex { // Could be changed to id <protocol> to resolve warning	
	int i,j,k,count1,count2;
	float score, score2, score3, maxIntensityLibraryEntry, maxIntensitySpectrum;
	i=0; j=0; k=0; 
	score = 0.0;
	score2 = 0.0;
	score3 = 0.0;
	maxIntensityLibraryEntry = jk_stats_float_max([libraryEntry intensities],numberOfPoints);
	maxIntensitySpectrum = jk_stats_float_max(intensities,numberOfPoints);;
	count1 = [self numberOfPoints];
	count2 = [libraryEntry numberOfPoints];
	float *peakMasses = [self masses];
	float *peakIntensities = [self intensities];
	float *libraryEntryMasses = [libraryEntry masses];
	float *libraryEntryIntensities = [libraryEntry intensities];
	float massDifference;
	float temp1, temp2;
	BOOL peakMassesAtEnd = NO;
	BOOL libraryEntryMassesAtEnd = NO;
	
	switch (scoreBasis) {
		case 0: // Using formula 1 in Gan 2001
			while ((i < count1) & (j < count2)) {
				// If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
				if (i >= count1) i = count1-1;
				if (j >= count2) j = count2-1;
				// roundf is expensive
				// massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
				// therefor is an alternative routine
				massDifference = peakMasses[i] - libraryEntryMasses[j];
				if ( fabs(massDifference) < 0.5f) {
					massDifference = 0.0f;
				}
				
				if (massDifference == 0.0) {
					temp1  = (peakIntensities[i]/maxIntensitySpectrum);
					temp2  = (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					score  = score  + fabsf(temp1 - temp2);
					score2 = score2 + fabsf(temp1 + temp2);
					
					k++; i++; j++;
				} else if (massDifference < 0.0) {
					temp1  = fabsf(peakIntensities[i]/maxIntensitySpectrum);
					score  = score  + temp1;
					score2 = score2 + temp1;
					
					k++; i++;
				} else if (massDifference > 0.0) {
					temp1  = fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
					score  = score  + temp1;
					score2 = score2 + temp1;
					
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
			while ((i < count1) & (j < count2)) {
				// If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
				if (i >= count1) i = count1-1;
				if (j >= count2) j = count2-1;
				massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
				
				if (massDifference == 0.0) {
					if ((peakIntensities[i]/maxIntensitySpectrum < 0.02) | (libraryEntryIntensities[j]/maxIntensityLibraryEntry < 0.02)) {
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
			while ((i < count1) & (j < count2)) {
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
		default:
			JKLogWarning(@"Don't know which formula to use!");
	}
	
//	JKLogDebug(@"returned score %f score = %f score2 = %f", (1.0-score/score2)*100.0, score, score2);
	if (penalizeForRetentionIndex) {
		float retentionIndexDelta, retentionIndexPenalty;
		float retentionIndexLibrary = [[libraryEntry retentionIndex] floatValue];
		if (retentionIndexLibrary == 0.0 || [[self peak] retentionIndex] == nil) {
			return (1.0-score/score2)*90.0;			//10% penalty!!
		}
					
		retentionIndexDelta = retentionIndexLibrary - [[[self peak] retentionIndex] floatValue];
		retentionIndexPenalty = pow(retentionIndexDelta,2) *  -0.000004 + 1;
		
		return (1.0-score/score2) * retentionIndexPenalty * 100.0; 
	} else {
		return (1.0-score/score2)*100.0;			
	}
}

- (NSNumber *)retentionIndex {
    if (peak) {
//        NSLog(@"retentionIndex spectrum '%@' = %g", [self model], [[peak retentionIndex] floatValue]);
        return [peak retentionIndex];
    } else {
        if (document) {
            if ([[self model] intValue] != 0) {
                return [NSNumber numberWithFloat:[document retentionIndexForScan:[[self model] intValue]]];                
            }
        }
    }
    NSLog(@"retentionIndex requested for spectrum '%@' without peak, document or recognized model", [self model]);
    return nil;
}

//#pragma mark optimization_level reset

#pragma mark Encoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:document forKey:@"document"]; // weak reference
		[coder encodeObject:peak forKey:@"peak"]; // weak reference
//		[coder encodeFloat:retentionIndex forKey:@"retentionIndex"];
        [coder encodeInt:numberOfPoints forKey:@"numberOfPoints"];
		[coder encodeBytes:(void *)masses length:numberOfPoints*sizeof(float) forKey:@"masses"];
		[coder encodeBytes:(void *)intensities length:numberOfPoints*sizeof(float) forKey:@"intensities"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder {
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		document = [coder decodeObjectForKey:@"document"]; // weak reference
		peak = [coder decodeObjectForKey:@"peak"]; // weak reference
		
//		retentionIndex = [coder decodeFloatForKey:@"retentionIndex"];
        numberOfPoints = [coder decodeIntForKey:@"numberOfPoints"];
		
		const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
		unsigned int length;
		masses = (float *) malloc(1*sizeof(float));
		intensities = (float *) malloc(1*sizeof(float));
		
		temporary	= [coder decodeBytesForKey:@"masses" returnedLength:&length];
		[self setMasses:(float *)temporary withCount:numberOfPoints];
		
		temporary	= [coder decodeBytesForKey:@"intensities" returnedLength:&length];
		[self setIntensities:(float *)temporary withCount:numberOfPoints];
    } 
    return self;
}

@end
