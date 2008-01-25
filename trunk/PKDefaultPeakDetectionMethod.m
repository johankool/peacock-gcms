//
//  PKDefaultPeakDetectionMethod.m
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import "PKDefaultPeakDetectionMethod.h"

#import "JKLog.h"

@implementation PKDefaultPeakDetectionMethod

- (id)init {
 //   JKLogEnteringMethod();
    self = [super init];
    if (self != nil) {
        [self setSettings:[PKDefaultPeakDetectionMethod defaultSettings]];
    }
    return self;
}

- (void)dealloc {
    [self setSettings:nil];
    [super dealloc];
}

- (NSArray *)peaksForChromatogram:(JKChromatogram *)aChromatogram error:(NSError **)error {
//    JKLogEnteringMethod();
    // Fall back to default settings when settings are nil
    if (![self settings]) {
        [self setSettings:[PKDefaultPeakDetectionMethod defaultSettings]];
    }

    int i, j; 
	int start, end, top;
    float maximumIntensity;
    
    // Baseline check
    if ([aChromatogram baselinePointsCount] <= 0) {
        // Error 300
        // No Baseline
        NSString *errorString = NSLocalizedString(@"No Baseline", @"error 300: No Baseline");
        NSString *recoverySuggestionString = NSLocalizedString(@"Add a baseline to the chromatogram before attempting to detect peaks.", @"error 300: No Baseline recovery suggestion");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObjectsAndKeys:errorString, NSLocalizedDescriptionKey, recoverySuggestionString, NSLocalizedRecoverySuggestionErrorKey, nil];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:300
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;             
        
        return nil;
        //        answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        //        return;
    }
    
    NSMutableArray *newPeaks = [[NSMutableArray alloc] init];
    // Some initial settings
    maximumIntensity = [aChromatogram maxTotalIntensity];
    float peakIdentificationThresholdF = [[[self settings] valueForKey:@"peakIdentificationThreshold"] floatValue];
    int numberOfPoints = [aChromatogram numberOfPoints];
    float *totalIntensity = [aChromatogram totalIntensity];
    for (i = 1; i < numberOfPoints; i++) {
        if (totalIntensity[i]/[aChromatogram baselineValueAtScan:i] > (1.0 + peakIdentificationThresholdF)){
            // determine: high, start, end
            // start
            for (j=i; totalIntensity[j] > totalIntensity[j-1]; j--) {
				if (j <= 0){
                    break;
                }
            }
            start = j;
            if (start < 0) start = 0; // Don't go outside bounds!
            
            // top
            for (j=start; totalIntensity[j] < totalIntensity[j+1]; j++) {
                if (j >= numberOfPoints-1) {
                    break;
                }
            }
            top=j;
            if (top >= numberOfPoints) top = numberOfPoints-1; // Don't go outside bounds!
            
            // end
            for (j=top; totalIntensity[j] > totalIntensity[j+1]; j++) {				
                if (j >= numberOfPoints-1) {
                    break;
                }
            }
            end=j;
            if (end >= numberOfPoints-1) end = numberOfPoints-1; // Don't go outside bounds!
            
            if ((top != start && top != end) && ((totalIntensity[top] - [aChromatogram baselineValueAtScan:top])/maximumIntensity > peakIdentificationThresholdF)) { // Sanity check
                JKPeakRecord *newPeak = [aChromatogram peakFromScan:start toScan:end];
                if (![[aChromatogram peaks] containsObject:newPeak]) {
                    [newPeaks addObject:newPeak];
                }
            }
            
            // Continue looking for peaks from end of this peak
            i = end;			
        }
    }    
    NSLog(@"%d peaks found", [newPeaks count]);
    return [newPeaks autorelease];
}

- (void)prepareForAction {
    // Not needed... (but has to be implemented)
}
- (void)cleanUpAfterAction {
    // Not needed... (but has to be implemented)
}

+ (NSString *)methodName {
    return @"Default Peak Detection Method";
}

+ (NSDictionary *)defaultSettings {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:0.03f], @"peakIdentificationThreshold", nil];
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
