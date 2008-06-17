//
//  PKDefaultBaselineDetectionMethod.m
//  Peacock
//
//  Created by Johan Kool on 03-01-08.
//  Copyright 2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKDefaultBaselineDetectionMethod.h"

#import "PKLog.h"
#import "pk_statistics.h"

@implementation PKDefaultBaselineDetectionMethod

- (id)init {
//    PKLogEnteringMethod();
    self = [super init];
    if (self != nil) {
        [self setSettings:[PKDefaultBaselineDetectionMethod defaultSettings]];
    }
    return self;
}

- (void)dealloc {
    [self setSettings:nil];
    [super dealloc];
}

- (NSArray *)baselineForChromatogram:(PKChromatogram *)aChromatogram error:(NSError **)error {
    //PKLogEnteringMethod();
    // Fall back to default settings when settings are nil
    if (![self settings]) {
        [self setSettings:[PKDefaultBaselineDetectionMethod defaultSettings]];
     }
    
    // get tot intensities
    // determing running minimum
    // dilute factor is e.g. 5
    // get minimum for scan 0 - 5 = min at scan 0
    // get minimum for scan 0 - 6 = min at scan 1
    // ...
    // get minimum for scan 0 - 10 = min at scan 5
    // get minimum for scan 1 - 11 = min at scan 6
    // get minimum for scan 2 - 12 = min at scan 7
    // distance to running min
    // distance[x] = intensity[x] - minimum[x]
    // normalize distance[x] ??
    // determine slope
    // slope[x] = (intensity[x+1]-intensity[x])/(time[x+1]-time[x])
    // normalize slope[x] ??
    // determine pointdensity
    // pointdensity[x] = sum of (1/distance to point n from x) / n  how about height/width ratio then?!
    // normalize pointdensity[x] ??
    // baseline if 
    // distance[x] = 0 - 0.1 AND
    // slope[x] = -0.1 - 0 - 0.1 AND
    // pointdensity[x] = 0.9 - 1
    int i, j, count;
    count = [aChromatogram numberOfPoints];
    float minimumSoFar, densitySoFar, distanceSquared;
    float minimum[count];
    float distance[count];
    float slope[count];
    float density[count];
    float *intensity;
    float *time;
    intensity = [aChromatogram totalIntensity];
   	time = [aChromatogram time];
    // to minimize object calling
    //	float baselineWindowWidthF = [[[self document] baselineWindowWidth] floatValue];
    int baselineWindowWidthI = [[[self settings] valueForKey:@"baselineWindowWidth"] intValue];
    float baselineDistanceThresholdF = [[[self settings] valueForKey:@"baselineDistanceThreshold"] floatValue];
    float baselineSlopeThresholdF = [[[self settings] valueForKey:@"baselineSlopeThreshold"] floatValue];
    //	float baselineDensityThresholdF = [[[self document] baselineDensityThreshold] floatValue];
        
    // determine minimum (but don't go below 0 or above count for j)         
    for (i = baselineWindowWidthI/2; i < count; i++) {
        minimumSoFar = intensity[i];
        for (j = i - baselineWindowWidthI/2; j < i + baselineWindowWidthI/2; j++) {
            if (j < 0) continue;
            if (j >= count) continue;
            if (intensity[j] < minimumSoFar) {
                minimumSoFar = intensity[j];
            }
        }
        minimum[i] = minimumSoFar;	
    }
    
    for (i = 0; i < count; i++) {
        distance[i] = fabsf(intensity[i] - minimum[i]);
    }
    
    for (i = 1; i < count-1; i++) {
        slope[i] = (fabsf((intensity[i+1]-intensity[i])/(time[i+1]-time[i])) + fabsf((intensity[i]-intensity[i-1])/(time[i]-time[i-1])))/2;
    }
    slope[0] = 0.0f;
    slope[count-1] = 0.0f;
    
    for (i = 0; i < count; i++) {
        densitySoFar = 0.0f;
        for (j = i - baselineWindowWidthI/2; j < i + baselineWindowWidthI/2; j++) {
            if (j < 0) continue;
            if (j >= count) continue;
            distanceSquared = pow(fabsf(intensity[j]-intensity[i]),2) + pow(fabsf(time[j]-time[i]),2);
            if (distanceSquared != 0.0f) densitySoFar = densitySoFar + 1/sqrt(distanceSquared);	
        }
        density[i] = densitySoFar;		
    }
    
    normalize(distance, count);
    normalize(slope, count);
    normalize(density, count);
    
    // Starting point
    NSMutableArray *newBaseline = [[NSMutableArray alloc] initWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"scan", [NSNumber numberWithFloat:intensity[0]], @"intensity", nil], nil];
    
    for (i = 1; i < count-1; i++) {
        //   PKLogDebug(@"intensity: %g; minimum: %g; distance: %g; slope: %g; density:%g",intensity[i],minimum[i],distance[i],slope[i],density[i]);
        if (distance[i] < baselineDistanceThresholdF && (slope[i] > -baselineSlopeThresholdF  && slope[i] < baselineSlopeThresholdF)) {  //   } && density[i] > baselineDensityThresholdF) { 
            [newBaseline addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"scan", [NSNumber numberWithFloat:intensity[i]], @"intensity", nil]];
        }
    }
//    PKLogDebug(@"%d baseline points found", [newBaseline count]);
    return [newBaseline autorelease];
}

- (void)prepareForAction {
    // Not needed... (but has to be implemented)
}
- (void)cleanUpAfterAction {
    // Not needed... (but has to be implemented)
}

+ (NSString *)methodName {
    return @"Default Baseline Detection Method";
}

+ (NSDictionary *)defaultSettings {
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:30], @"baselineWindowWidth", [NSNumber numberWithFloat:0.01f], @"baselineDistanceThreshold", [NSNumber numberWithFloat:0.01f], @"baselineSlopeThreshold", nil];
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
