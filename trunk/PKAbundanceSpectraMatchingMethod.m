//
//  PKAbundanceSpectraMatchingMethod.m
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import "PKAbundanceSpectraMatchingMethod.h"

#import "JKLog.h"
#import "math.h"

@implementation PKAbundanceSpectraMatchingMethod

- (id)init {
    JKLogEnteringMethod();
    self = [super init];
    if (self != nil) {
      //  [self setSettings:[PKAbundanceSpectraMatchingMethod defaultSettings]];
    }
    return self;
}

- (void)dealloc {
    [self setSettings:nil];
    [super dealloc];
}

- (CGFloat)matchingScoreForSpectrum:(id <JKComparableProtocol>)spectrum comparedToLibraryEntry:(id <JKComparableProtocol>)libraryEntry error:(NSError **)error {
    int i,j,k;
	float score, score2, score3;
	i=0; j=0; k=0; 
	score = 0.0f;
	score2 = 0.0f;
	score3 = 0.0f;
    
    // spectrum1
	int count1 = [spectrum numberOfPoints];
	float *peakMasses = [spectrum masses];
	float *peakIntensities = [spectrum intensities];
	float maxIntensitySpectrum = [spectrum maxIntensity]; //jk_stats_float_max(peakIntensities, count1);
    if (maxIntensitySpectrum <= 0.0f) {
        return 0.0f;
    }   
    NSAssert(maxIntensitySpectrum > 0.0f, @"maxIntensitySpectrum is 0 or smaller");    
 
    // libraryEntry
	int count2 = [libraryEntry numberOfPoints];
	float *libraryEntryMasses = [libraryEntry masses];
	float *libraryEntryIntensities = [libraryEntry intensities];
    float maxIntensityLibraryEntry = [libraryEntry maxIntensity]; // jk_stats_float_max(libraryEntryIntensities, count2); 
    if (maxIntensityLibraryEntry <= 0.0f) {
        return 0.0f;
    }
    NSAssert1(maxIntensityLibraryEntry > 0.0f, @"maxIntensityLibraryEntry is 0 or smaller for library entry '%@'", libraryEntry);
    
//    JKLogDebug(@"maxIntensitySpectrum %g; maxIntensityLibraryEntry %g", maxIntensitySpectrum, maxIntensityLibraryEntry);

	float massDifference = 0.0f;
	float temp1, temp2;
//	BOOL peakMassesAtEnd = NO;
//	BOOL libraryEntryMassesAtEnd = NO;
    i = 0;
    j = 0;
    k = 0; 
    BOOL iFinished = NO;
    BOOL jFinished = NO;
    BOOL useForScore = YES;
    float minScannedMassRange = 0.0f;
    float maxScannedMassRange = 1000000.0f;
    
    // useScanRangeCheck
    BOOL useScanRangeCheck = NO;
    if ([spectrum hasScannedMassRange]) {
        minScannedMassRange = [spectrum minScannedMassRange];
        maxScannedMassRange = [spectrum maxScannedMassRange];
        useScanRangeCheck = YES;
    }
    
    if (maxScannedMassRange <= minScannedMassRange) {
 //       JKLogDebug(@"useScanRangeCheck disabled: minScannedMassRange: %g; maxScannedMassRange: %g", minScannedMassRange, maxScannedMassRange);
        useScanRangeCheck = NO;
    }
    
    // Using formula 1 in Gan 2001
    while ((!iFinished) || (!jFinished)) {
        // If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
        if ((i >= count1) && (j >= count2)) {
            iFinished = YES;
            jFinished = YES;
            break;
        } else if (i >= count1) {
            iFinished = YES;
            massDifference = peakMasses[count1-1] - libraryEntryMasses[j];
            if ((libraryEntryMasses[j] < minScannedMassRange) || (libraryEntryMasses[j] >  maxScannedMassRange)) {
                // Do not use for scoring
                useForScore = NO;
            } else {
                useForScore = YES;
            }
        } else if (j >= count2) {
            jFinished = YES;
            massDifference = peakMasses[i] - libraryEntryMasses[count2-1];
            if ((libraryEntryMasses[count2-1] < minScannedMassRange) || (libraryEntryMasses[count2-1] >  maxScannedMassRange)) {
                // Do not use for scoring
                useForScore = NO;
            } else {
                useForScore = YES;
            }
        } else {
            massDifference = peakMasses[i] - libraryEntryMasses[j];
            if ((libraryEntryMasses[j] < minScannedMassRange) || (libraryEntryMasses[j] >  maxScannedMassRange)) {
                // Do not use for scoring
                useForScore = NO;
            } else {
                useForScore = YES;
            }
        }
        
        // roundf is expensive
        // massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
        // therefor is an alternative routine
        //				massDifference = peakMasses[i] - libraryEntryMasses[j];
        
        if (fabsf(massDifference) < 1.0f) {
            if ((useForScore && useScanRangeCheck) || !useScanRangeCheck) {
                temp1  = (peakIntensities[i]/maxIntensitySpectrum);
                temp2  = (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
                score  = score  + fabsf(temp1 - temp2);
                score2 = score2 + fabsf(temp1 + temp2);                        
            }
            
            if (iFinished) {
                k++; j++;
            } else if (jFinished) {
                k++; i++;
            } else {                        
                k++; i++; j++;
            }
        } else if ((massDifference < 0.0f) && !iFinished) { // mass1 is smaller than mass2 -> if possible increase mass1
            if ((useForScore && useScanRangeCheck) || !useScanRangeCheck) {
                temp1  = fabsf(peakIntensities[i]/maxIntensitySpectrum);
                score  = score  + temp1;
                score2 = score2 + temp1;
            }
            k++; i++;
        } else if ((massDifference > 0.0f) && !jFinished) {
            if ((useForScore && useScanRangeCheck) || !useScanRangeCheck) {
                temp1  = fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
                score  = score  + temp1;
                score2 = score2 + temp1;
            }
            
            k++; j++;
        } else if (iFinished) {
            if ((useForScore && useScanRangeCheck) || !useScanRangeCheck) {
                temp1  = fabsf(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
                score  = score  + temp1;
                score2 = score2 + temp1;
            }
            
            k++; j++;
        } else if (jFinished) {
            if ((useForScore && useScanRangeCheck) || !useScanRangeCheck) {
                temp1  = fabsf(peakIntensities[i]/maxIntensitySpectrum);
                score  = score  + temp1;
                score2 = score2 + temp1;
            }
            
            k++; i++;
        } else {
            // When out of range?!?
            // Keep counting to get us out of it...
            k++; i++; j++;
            //JKLogError(@"This should not happen ever!! i %d j %d k %d massdif %f mass %f masslib %f inten %f intenlib %f count1 %d count2 %d", i,j,k, massDifference, masses[i], libraryEntryMasses[j], intensities[i], libraryEntryIntensities[j], count1, count2);
        }
        
        if ((i >= count1) && (j >= count2)) {
            iFinished = YES;
            jFinished = YES;
        }
//        NSAssert(score >= 0.0f, @"score < 0");
//        NSAssert(score2 >= 0.0f, @"score2 < 0");
    } 

    if (isnan(score)  || isnan(score2)) {
 //     NSLog(@"000");
        return 0.0f;
    }
//    NSAssert(score > 0.0f, @"score < 0");
//    NSAssert(score2 > 0.0f, @"score2 < 0");

    float result = (1.0f-score/score2)*100.0f;
//    NSAssert(result >= 0.0f, @"result < 0");
//    NSAssert(result <= 100.0f, @"result > 100");
 
//    NSLog(@"%g", result);
    return result;
}

- (void)prepareForAction {
    // Not needed... (but has to be implemented)
}
- (void)cleanUpAfterAction {
    // Not needed... (but has to be implemented)
}

+ (NSString *)methodName {
    return @"Abundance";
}

+ (NSDictionary *)defaultSettings {
    return [NSDictionary dictionaryWithObjectsAndKeys:nil];
}

- (NSDictionary *)settings {
    return settings;
}

- (void)setSettings:(NSDictionary *)theSettings {
    if (settings != theSettings) {
        [settings autorelease];
        [theSettings retain];
        settings = theSettings;
    }
}

- (NSView *)settingsView {
    return nil;
}

@end
