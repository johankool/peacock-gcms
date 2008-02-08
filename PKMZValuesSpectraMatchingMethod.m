//
//  PKMZValuesSpectraMatchingMethod.m
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import "PKMZValuesSpectraMatchingMethod.h"

#import "JKLog.h"

@implementation PKMZValuesSpectraMatchingMethod

- (id)init {
    JKLogEnteringMethod();
    self = [super init];
    if (self != nil) {
       // [self setSettings:[PKMZValuesSpectraMatchingMethod defaultSettings]];
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
    NSAssert(maxIntensityLibraryEntry > 0.0f, @"maxIntensityLibraryEntry is 0 or smaller");
    
    
	float massDifference;
	float temp1, temp2;
	BOOL peakMassesAtEnd = NO;
	BOOL libraryEntryMassesAtEnd = NO;
    i = 0;
    j = 0;
    k = 0; 
    BOOL iFinished = NO;
    BOOL jFinished = NO;
    BOOL useForScore = YES;
    BOOL useScanRangeCheck = NO;
    float minScannedMassRange = 0.0f;
    float maxScannedMassRange = 1000000.0f;
    if ([spectrum hasScannedMassRange]) {
        minScannedMassRange = [spectrum minScannedMassRange];
        maxScannedMassRange = [spectrum maxScannedMassRange];
        useScanRangeCheck = YES;
    } 
    
    
    // Using formula 2 in Gan 2001
    while ((i < count1) || (j < count2)) {
        // If we go beyond the bounds, we get unexpected results, so make sure we are within the bounds.
        if (i >= count1) i = count1-1;
        if (j >= count2) j = count2-1;
        massDifference = roundf(peakMasses[i]) - roundf(libraryEntryMasses[j]);
        
        if (massDifference == 0.0f) {
            if ((peakIntensities[i]/maxIntensitySpectrum < 0.02f) | (libraryEntryIntensities[j]/maxIntensityLibraryEntry < 0.02f)) {
                score = score + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
                score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);
                
            } else {
                score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum)+(libraryEntryIntensities[j]/maxIntensityLibraryEntry);					
            }				
            
            k++; i++; j++;
        } else if (massDifference < 0.0f) {
            score = score + (peakIntensities[i]/maxIntensitySpectrum);
            score2 = score2 + (peakIntensities[i]/maxIntensitySpectrum);
            
            k++; i++;
        } else if (massDifference > 0.0f) {
            score = score + (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
            score2 = score2 + (libraryEntryIntensities[j]/maxIntensityLibraryEntry);
            
            k++; j++;
        } else {
            // When out of range?!?
            // Keep counting to get us out of it...
            k++; i++; j++;
           // JKLogDebug(@"This should not happen ever!! i %d j %d k %d massdif %f mass %f masslib %f inten %f intenlib %f count1 %d count2 %d", i,j,k, massDifference, masses[i], libraryEntryMasses[j], intensities[i], libraryEntryIntensities[j], count1, count2);
        }
    } 
    JKLogDebug(@"score: %g", (1.0f-score/score2)*100.0f);

    return (1.0f-score/score2)*100.0f;
}

- (void)prepareForAction {
    // Not needed... (but has to be implemented)
}
- (void)cleanUpAfterAction {
    // Not needed... (but has to be implemented)
}

+ (NSString *)methodName {
    return @"m/z Values";
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
