//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKChromatogram.h"

#import "PKChromatogramDataSeries.h"
#import "JKGCMSDocument.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "jk_statistics.h"
#import "netcdf.h"
#import "NSCoder+CArrayEncoding.h"

@implementation JKChromatogram

#pragma mark Initialization & deallocation

- (id)init 
{
    return [self initWithModel:@"TIC"];
}

- (id)initWithModel:(NSString *)inModel 
{
    // designated initializer
    if ((self = [super init])) {
        model = [inModel retain];
        time = (float *) malloc(1*sizeof(float));
        totalIntensity = (float *) malloc(1*sizeof(float));

        peaks = [[NSMutableArray alloc] init];
        baselinePointsCount = 0;
        baselinePointsScans = (int *) malloc(sizeof(int));
        baselinePointsIntensities = (float *) malloc(sizeof(float));

    }
    return self;
}

- (void)dealloc {
    free(time);
    free(totalIntensity);
    free(baselinePointsScans);
    free(baselinePointsIntensities);
    [model release];
    [peaks release];
    [super dealloc];
}
#pragma mark -

#pragma mark Actions
- (void)obtainBaseline {
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
	int i, j, count, newBaselinePointsCount;
	count = [self numberOfPoints];
	float minimumSoFar, densitySoFar, distanceSquared;
	float minimum[count];
	float distance[count];
	float slope[count];
	float density[count];
	float *intensity;
	//	float *time;
	intensity = totalIntensity;
	//	time = [self time];
	// to minimize object calling
//	float baselineWindowWidthF = [[[self document] baselineWindowWidth] floatValue];
	int baselineWindowWidthI = [[[self document] baselineWindowWidth] intValue];
	float baselineDistanceThresholdF = [[[self document] baselineDistanceThreshold] floatValue];
	float baselineSlopeThresholdF = [[[self document] baselineSlopeThreshold] floatValue];
//	float baselineDensityThresholdF = [[[self document] baselineDensityThreshold] floatValue];
    
//    [[[self document] undoManager] registerUndoWithTarget:self
//                                      selector:@selector(setBaselinePoints:)
//                                        object:[baselinePoints mutableCopy]];
//    [[[self document] undoManager] setActionName:NSLocalizedString(@"Identify Baseline",@"")];
    
	[self willChangeValueForKey:@"baseline"];

    int newBaselinePointsScans[count];
    float newBaselinePointsIntensities[count]; 
	
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
    newBaselinePointsCount = 0;
    newBaselinePointsScans[newBaselinePointsCount] = 0;
    newBaselinePointsIntensities[newBaselinePointsCount] = intensity[0];
    
	for (i = 1; i < count-1; i++) {
     //   JKLogDebug(@"intensity: %g; minimum: %g; distance: %g; slope: %g; density:%g",intensity[i],minimum[i],distance[i],slope[i],density[i]);
		if (distance[i] < baselineDistanceThresholdF && (slope[i] > -baselineSlopeThresholdF  && slope[i] < baselineSlopeThresholdF)) {  //   } && density[i] > baselineDensityThresholdF) { 
            newBaselinePointsCount++;
            newBaselinePointsScans[newBaselinePointsCount] = i;
            newBaselinePointsIntensities[newBaselinePointsCount] = intensity[i];
 		}
	}
    newBaselinePointsCount++;
    newBaselinePointsScans[newBaselinePointsCount] = count-1;
    newBaselinePointsIntensities[newBaselinePointsCount] = intensity[count-1];
 
    baselinePointsCount = newBaselinePointsCount+1;
    baselinePointsScans = (int *) realloc(baselinePointsScans, baselinePointsCount*sizeof(int));
    baselinePointsIntensities = (float *) realloc(baselinePointsIntensities, baselinePointsCount*sizeof(float));
    
	for (i = 0; i < baselinePointsCount; i++) {
        baselinePointsScans[i] = newBaselinePointsScans[i];
        baselinePointsIntensities[i] = newBaselinePointsIntensities[i];
 	}
    [self didChangeValueForKey:@"baseline"];

}	

- (float)baselineValueAtScan:(int)inValue {
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
	int i = 0;
	float lowestScan, lowestInten, highestScan, highestInten;
	
    for (i = 0; i < baselinePointsCount-1; i++) {
        if (inValue < baselinePointsScans[i]) {
            break;
        }
    }
    
	if (i <= 0) {
		lowestScan = 0.0f;
		lowestInten = 0.0f;
		highestScan = baselinePointsScans[i]*1.0f;
		highestInten = baselinePointsIntensities[i];
	} else {
		lowestScan = baselinePointsScans[i-1]*1.0f;
		lowestInten = baselinePointsIntensities[i-1];
		highestScan = baselinePointsScans[i]*1.0f;
		highestInten = baselinePointsIntensities[i];
	}
	
	return (highestInten-lowestInten) * ((inValue-lowestScan)/(highestScan-lowestScan)) + lowestInten; 
}

- (int)baselinePointsIndexAtScan:(int)inValue {
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
	int i = 0;
	
	while (inValue > baselinePointsScans[i] && i < baselinePointsCount) {
		i++;
	} 
	
	return i; 
}

- (void)identifyPeaks
{
    [self identifyPeaksWithForce:NO];
}

- (void)identifyPeaksWithForce:(BOOL)forced
{
	int i, j, answer;
	int start, end, top;
    float maximumIntensity;
    [self willChangeValueForKey:@"peaks"];
    
//    if (!forced) {
//        if ([[self peaks] count] > 0) {
//            answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Delete current peaks?",@""),NSLocalizedString(@"Peaks that are already identified could cause doublures. It's recommended to delete the current peaks.",@""),NSLocalizedString(@"Delete",@""),NSLocalizedString(@"Cancel",@""),NSLocalizedString(@"Keep",@""));
//            if (answer == NSOKButton) {
//                // Delete contents!
//                [[self peaks] removeAllObjects];
//             } else if (answer == NSCancelButton) {
//                return;
//            } else {
//
//            }
//        }        
//    }
    
    // Baseline check
    if (baselinePointsCount <= 0) {
        [self obtainBaseline];
//        answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
//        return;
    }
    
    // Some initial settings
    maximumIntensity = [self maxTotalIntensity];
    float peakIdentificationThresholdF = [[[self document] peakIdentificationThreshold] floatValue];
    for (i = 1; i < numberOfPoints; i++) {
        if (totalIntensity[i]/[self baselineValueAtScan:i] > (1.0 + peakIdentificationThresholdF)){
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
            
            if ((top != start && top != end) && ((totalIntensity[top] - [self baselineValueAtScan:top])/maximumIntensity > peakIdentificationThresholdF)) { // Sanity check
                JKPeakRecord *newPeak = [self peakFromScan:start toScan:end];
                if (![peaks containsObject:newPeak]) {
                    [self insertObject:newPeak inPeaksAtIndex:[peaks count]];                    
                }
            }
            
            // Continue looking for peaks from end of this peak
            i = end;			
        }
    }
    [self didChangeValueForKey:@"peaks"];
}


- (JKPeakRecord *)peakFromScan:(int)startScan toScan:(int)endScan {
    // Baseline check
    if (baselinePointsCount <= 0) {
        [self obtainBaseline];
//       NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
//        return nil;
    }
    if (startScan > endScan) {
        int temp = startScan;
        startScan = endScan;
        endScan = temp;
    }
    if (startScan == endScan) {
        endScan++;
    }
    
	for (JKPeakRecord *peak in [self peaks]) {
    	if (([peak start] == startScan) && ([peak end] == endScan)) {
            return peak;
        }
    }
    JKPeakRecord *newPeak = [[JKPeakRecord alloc] init];
    [newPeak setPeakID:[[self document] nextPeakID]];
    [newPeak setStart:startScan];
    [newPeak setEnd:endScan];
    [newPeak setChromatogram:self];
    
    NSError *outError;
    
    NSNumber *leftBaseline = [NSNumber numberWithFloat:[self baselineValueAtScan:startScan]];
    if ([newPeak validateBaselineLeft:&leftBaseline error:&outError]) {
        [newPeak setValue:leftBaseline forKey:@"baselineLeft"];
    } else {
        leftBaseline = [NSNumber numberWithFloat:totalIntensity[startScan]];
        [newPeak setValue:leftBaseline forKey:@"baselineLeft"];
    }
    NSNumber *rightBaseline = [NSNumber numberWithFloat:[self baselineValueAtScan:endScan]];
    if ([newPeak validateBaselineRight:&rightBaseline error:&outError]) {
        [newPeak setValue:rightBaseline forKey:@"baselineRight"];
    } else {
        rightBaseline = [NSNumber numberWithFloat:totalIntensity[endScan]];
        [newPeak setValue:rightBaseline forKey:@"baselineRight"];
    }
    
    return [newPeak autorelease];     
}

- (BOOL)combinePeaks:(NSArray *)peaksToCombine {
    int indexForStart, indexForEnd, peakCount, i, indexForIdentified, indexForConfirmed, indexForCombinedPeak;
    BOOL twoOrMoreIdentified = NO;
    JKPeakRecord *peak;
    
    peakCount = [peaksToCombine count];
    if (peakCount <= 1) {
        NSRunInformationalAlertPanel(NSLocalizedString(@"Combining Peaks Failed",@""),NSLocalizedString(@"Can't combine one or less peaks.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return NO;
    }
    peak = [peaksToCombine objectAtIndex:0];
    indexForStart = 0;
    indexForEnd = 0;
    BOOL identified = [peak identified];
    indexForIdentified = 0;
    BOOL confirmed = [peak confirmed];
    indexForConfirmed = 0;
    
    for (i = 1; i < peakCount; i++) {
        peak = [peaksToCombine objectAtIndex:i];
        
        if (![peaks containsObject:peak]) {
            NSRunInformationalAlertPanel(NSLocalizedString(@"Combining Peaks Failed",@""),NSLocalizedString(@"Can't combine peaks not in same chromatogram.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
            return NO;
        }

    	if ([peak start] < [(JKPeakRecord *)[peaksToCombine objectAtIndex:indexForStart] start]) {
            indexForStart = i;
        }
    	if ([peak end] > [[peaksToCombine objectAtIndex:indexForEnd] end]) {
            indexForEnd = i;
        }
        
        if ([peak identified]) {
            indexForIdentified = i;
            if (identified) {
                twoOrMoreIdentified = YES;
            }
            identified = YES;
        }
        if ([peak confirmed]) {
            indexForConfirmed = i;
            if (confirmed) {
                NSRunInformationalAlertPanel(NSLocalizedString(@"Combining Peaks Failed",@""),NSLocalizedString(@"Can't combine peaks two or more confirmed peaks.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
                return NO;
            }
            confirmed = YES;
        }
    }
    
    if (twoOrMoreIdentified && !confirmed) {
        NSRunInformationalAlertPanel(NSLocalizedString(@"Combining Peaks Failed",@""),NSLocalizedString(@"Can't combine peaks two or more identified peaks, if none is confirmed.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return NO;
    }
    
    if (confirmed) {
        indexForCombinedPeak = indexForConfirmed;        
    } else if (identified) {
        indexForCombinedPeak = indexForIdentified;        
    } else {
        indexForCombinedPeak = indexForStart;
    }
    peak = [peaksToCombine objectAtIndex:indexForCombinedPeak];
    [peak setStart:[(JKPeakRecord *)[peaksToCombine objectAtIndex:indexForStart] start]];
    [peak setEnd:[[peaksToCombine objectAtIndex:indexForEnd] end]];
    [peak setBaselineLeft:[[peaksToCombine objectAtIndex:indexForStart] baselineLeft]];
    [peak setBaselineRight:[[peaksToCombine objectAtIndex:indexForEnd] baselineRight]];
    
    // Remove the peaks we don't need anymore
    [self willChangeValueForKey:@"peaks"];
    for (i = 0; i < peakCount; i++) {
        if (i != indexForCombinedPeak) {
            [[self peaks] removeObject:[peaksToCombine objectAtIndex:i]];
        }
    }
    [self didChangeValueForKey:@"peaks"];
    return YES;
}

- (float)timeForScan:(int)scan {
    NSAssert(scan >= 0, @"Scan must be equal or larger than zero");
    return time[scan];    
}

- (int)scanForTime:(float)inTime {
    int i;
//    inTime = inTime * 60.0f;
    if (inTime <= time[0]) {
        return 0;
    } else if (inTime >= time[numberOfPoints-1]) {
        return numberOfPoints-1;
    }
    for (i=0; i<numberOfPoints; i++) {
        if (time[i]>inTime) {
            // this calculates wether i or i-1 is closer the inTime
            if ((time[i]-inTime) <= 0.5) {
                return i;
            } else {
                return i-1;                
            }
        }
    }
    return numberOfPoints-1;
}

- (float)highestPeakHeight {
    highestPeakHeight = 0.0f;
    
	for (JKPeakRecord *peak in [self peaks]) {
    	if ([[peak height] floatValue] > highestPeakHeight) {
            highestPeakHeight = [[peak height] floatValue];
        }
    }
    
    return highestPeakHeight;
}

- (float)largestPeakSurface {
    largestPeakSurface = 0.0f;
     
    for (JKPeakRecord *peak in [self peaks]) {
    	if ([[peak surface] floatValue] > largestPeakSurface) {
            largestPeakSurface = [[peak surface] floatValue];
        }
    }
    
    return largestPeakSurface;
}

- (void)removeUnidentifiedPeaks
{    
    NSMutableArray *peaksToSave = [NSMutableArray array];
	for (JKPeakRecord *peak in [self peaks]) {
    	if ((([peak identified]) | ([[peak searchResults] count] > 0  | ([peak flagged]))) | (![[peak label] isEqualToString:@""])) {
            [peaksToSave addObject:peak];
        }
    }
    [self setPeaks:peaksToSave];
}
#pragma mark -

#pragma mark Sorting
- (NSArray *)mzValues {
    int j;
    
    if (![self model] || [[self model] isEqualToString:@""]) {
        return nil;
    }

    NSMutableArray *mzValues = [NSMutableArray array];
    NSString *theModel = [[self model] stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
	NSArray *mzValuesPlus = [theModel componentsSeparatedByString:@"+"];
	NSArray *mzValuesMin = nil;
    NSNumber *minimumScannedMassRange = [[self document] minimumScannedMassRange];
    NSNumber *maximumScannedMassRange = [[self document] maximumScannedMassRange];
	for (id loopItem in mzValuesPlus) {
		mzValuesMin = [loopItem componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
                    if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                        [mzValues addObject:[NSNumber numberWithInt:j]];                        
                    }
				}
			} else {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j++) {
                    if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                        [mzValues addObject:[NSNumber numberWithInt:j]];
                    }
				}
			}
		} else {
            j = [[mzValuesMin objectAtIndex:0] intValue];
            if ((j >= [minimumScannedMassRange intValue]) && (j <= [maximumScannedMassRange intValue])) {
                [mzValues addObject:[NSNumber numberWithInt:j]];
            }
		}
	}
    if ([mzValues count] < 1) {
        return nil;
    } 
	// Short mzValues
    mzValues = [[mzValues sortedArrayUsingFunction:intSort context:NULL] mutableCopy];
    return [mzValues autorelease];
}

- (NSComparisonResult)sortOrderComparedTo:(JKChromatogram *)otherChromatogram
{
    if ([[self document] modelString:[self model] isEqualToString:[otherChromatogram model]]) {
        return NSOrderedSame;
    }
    if ([[self model] isEqualToString:@""]) {
        return NSOrderedDescending;
    }
    if ([[otherChromatogram model] isEqualToString:@""]) {
        return NSOrderedAscending;
    }
    
    NSArray *mzValuesSelf = [self mzValues];
    NSArray *mzValuesOther = [otherChromatogram mzValues];
    int i, count = [mzValuesSelf count];
    if ([mzValuesOther count] < count) {
        count = [mzValuesOther count];
    }
	for (i = 0; i < count; i++) {
        if ([[mzValuesSelf objectAtIndex:i] intValue] > [[mzValuesOther objectAtIndex:i] intValue]) {
            return NSOrderedDescending;
        } else if ([[mzValuesSelf objectAtIndex:i] intValue] < [[mzValuesOther objectAtIndex:i] intValue]) {
            return NSOrderedAscending;
        }
    }
    if ([mzValuesSelf count] < [mzValuesOther count]) {
        return NSOrderedAscending;
    } else if ([mzValuesSelf count] > [mzValuesOther count]) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}
#pragma mark -

#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)coder {
    if ([coder allowsKeyedCoding]) {
        if ([super conformsToProtocol:@protocol(NSCoding)]) {
            [super encodeWithCoder:coder];        
        } 

		[coder encodeInt:2 forKey:@"version"];
		[coder encodeObject:model forKey:@"model"];
        [coder encodeObject:peaks forKey:@"peaks"];
        
        [coder encodeFloatArray:time withCount:numberOfPoints forKey:@"time"];
        [coder encodeFloatArray:totalIntensity withCount:numberOfPoints forKey:@"totalIntensity"];
        
        [coder encodeIntArray:baselinePointsScans withCount:baselinePointsCount forKey:@"baselinePointsScans"];
        [coder encodeFloatArray:baselinePointsIntensities withCount:baselinePointsCount forKey:@"baselinePointsIntensities"];
    } else {
        [NSException raise:NSInvalidArchiveOperationException
                    format:@"Only supports NSKeyedArchiver coders"];
    }
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
        int version = [coder decodeIntForKey:@"version"];
        model = [[coder decodeObjectForKey:@"model"] retain];
        peaks = [[coder decodeObjectForKey:@"peaks"] retain];
        JKPeakRecord *peak;
        for (peak in peaks) {
//            // Remove duplicate peaks
//            int firstIndex = [peaks indexOfObject:peak];
//            int count = [peaks count];
//            if (firstIndex >= count-1) {
//                break;
//            }
//            while ([peaks indexOfObject:peak inRange:NSMakeRange(firstIndex+1,count-firstIndex-1)] != NSNotFound) {
//                count = [peaks count];
//                if (firstIndex >= count-1) {
//                    break;
//                }                
//                [peaks removeObjectAtIndex:[peaks indexOfObject:peak inRange:NSMakeRange(firstIndex+1,count-firstIndex-1)]];
//            }
            [peak setContainer:self];
        }
        
        if (version == 1) {
            numberOfPoints = [coder decodeIntForKey:@"numberOfPoints"];
            
            const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
            unsigned int length;
            time = (float *) malloc(numberOfPoints*sizeof(float));
            totalIntensity = (float *) malloc(numberOfPoints*sizeof(float));
            
            temporary	= [coder decodeBytesForKey:@"time" returnedLength:&length];
            [self setTime:(float *)temporary withCount:numberOfPoints];
            
            temporary	= [coder decodeBytesForKey:@"totalIntensity" returnedLength:&length];
            [self setTotalIntensity:(float *)temporary withCount:numberOfPoints];

            baselinePointsScans = (int *) malloc(2*sizeof(int));
            baselinePointsIntensities = (float *) malloc(2*sizeof(float));
//            baselinePoints = [[coder decodeObjectForKey:@"baselinePoints"] retain];

        } else {
            unsigned int length;
  
            time = [coder decodeFloatArrayForKey:@"time" returnedCount:&length];
            numberOfPoints = length;

            totalIntensity = [coder decodeFloatArrayForKey:@"totalIntensity" returnedCount:&length];

            baselinePointsScans= [coder decodeIntArrayForKey:@"baselinePointsScans" returnedCount:&length];
            baselinePointsCount = length;
            
            baselinePointsIntensities = [coder decodeFloatArrayForKey:@"baselinePointsIntensities" returnedCount:&length];           
        }
 	} 
    return self;
}
#pragma mark -

#pragma mark Document
- (JKGCMSDocument *)document
{
    return (JKGCMSDocument *)[self container];
}
#pragma mark -

#pragma mark Accessors
#pragma mark (parameters)
- (NSString *)model
{
    return model;
}

- (void)setModel:(NSString *)inString
{
    if (inString != model) {
        [model autorelease];
        model = [inString copy];        
    }
}

// Chromatogram data
- (int)numberOfPoints 
{
    return numberOfPoints;
}

- (float *)time 
{
    return time;
}
- (void)setTime:(float *)inArray withCount:(int)inValue 
{
    numberOfPoints = inValue;
    time = (float *) realloc(time, numberOfPoints*sizeof(float));
    memcpy(time, inArray, numberOfPoints*sizeof(float));
}

- (float *)totalIntensity
{
    return totalIntensity;
}
- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue 
{
    numberOfPoints = inValue;
    totalIntensity = (float *) realloc(totalIntensity, numberOfPoints*sizeof(float));
    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(float));
}

// Baseline points
- (int)baselinePointsCount 
{
    return baselinePointsCount;
}

- (int *)baselinePointsScans
{
    return baselinePointsScans;
}
- (void)setBaselinePointsScans:(int *)inArray withCount:(int)inValue 
{
    baselinePointsCount = inValue;
    baselinePointsScans = (int *) realloc(baselinePointsScans, baselinePointsCount*sizeof(int));
    memcpy(baselinePointsScans, inArray, baselinePointsCount*sizeof(int));
}

- (float *)baselinePointsIntensities 
{
    return baselinePointsIntensities;
}
- (void)setBaselinePointsIntensities:(float *)inArray withCount:(int)inValue {
    baselinePointsCount = inValue;
    baselinePointsIntensities = (float *) realloc(baselinePointsIntensities, baselinePointsCount*sizeof(float));
    memcpy(baselinePointsIntensities, inArray, baselinePointsCount*sizeof(float));
}

- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index
{
    int i, newCount = baselinePointsCount+1;
    int newScans[newCount];
    float newIntensities[newCount];
    
    for (i=0; i<index; i++) {
        newScans[i] = baselinePointsScans[i];
        newIntensities[i] = baselinePointsIntensities[i];
    }
    newScans[index] = [[aBaselinePoint valueForKey:@"Scan"] intValue];
    newIntensities[index] = [[aBaselinePoint valueForKey:@"Total Intensity"] floatValue];
    if (newCount > index) {
        for (i= index+1; i<newCount; i++) {
            newScans[i] = baselinePointsScans[i-1];
            newIntensities[i] = baselinePointsIntensities[i-1];
        }
    }
    [self setBaselinePointsScans:newScans withCount:newCount];
    [self setBaselinePointsIntensities:newIntensities withCount:newCount];
}

#pragma mark (to many relationships)
// Mutable To-Many relationship peaks
- (NSMutableArray *)peaks {
//    if ([[self model] isEqualToString:@"TIC"]) {
//        return [[self document] peaks];
//    }
	return peaks;
}

- (void)setPeaks:(NSMutableArray *)inValue {
    [[self container] willChangeValueForKey:@"peaks"];
    JKPeakRecord *peak;
    if (inValue != peaks) {
        [inValue retain];
        [peaks release];
   
        for (peak in peaks) {
            [peak setContainer:nil];
        }
        
        peaks = inValue;
    }
    
    for (peak in peaks) {
    	[peak setContainer:self];
    }
    [[self container] didChangeValueForKey:@"peaks"];
}

- (int)countOfPeaks {
    return [[self peaks] count];
}

- (JKPeakRecord *)objectInPeaksAtIndex:(int)index {
    return [[self peaks] objectAtIndex:index];
}

- (void)getPeak:(JKPeakRecord **)somePeaks range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [peaks getObjects:somePeaks range:inRange];
}

- (void)insertObject:(JKPeakRecord *)aPeak inPeaksAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Peak",@"")];
	}
	
	// Add aPeak to the array peaks
    [[self container] willChangeValueForKey:@"peaks"];
	[peaks insertObject:aPeak atIndex:index];
    [aPeak setContainer:self];
    [[self container] didChangeValueForKey:@"peaks"];
}

- (void)removeObjectFromPeaksAtIndex:(int)index{
    if (index >= [peaks count] || index < 0) {
        JKLogError(@"No peak at out-of-bounds index %d.", index);
        return;
    }
	JKPeakRecord *aPeak = [peaks objectAtIndex:index];
    if (!aPeak) {
        JKLogError(@"No peak found at index %d.", index);
        return;
    }
	if ([aPeak confirmed]) {
        int  answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Delete Confirmed Peak",@""),NSLocalizedString(@"The peak you are about to remove was previously confirmed. Are you sure you want to delete this peak?",@""), NSLocalizedString(@"Delete",@""), NSLocalizedString(@"Cancel",@""), nil);
        if (answer == NSOKButton) {
            // Continue
        } else if (answer == NSCancelButton) {
            // Cancel
            return;
        } else {
            return;
        }
    }
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aPeak inPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Peak",@"")];
	}
	
	// Remove the peak from the array
//    [[self container] willChangeValueForKey:@"peaks"];
	[peaks removeObjectAtIndex:index];
    [aPeak setContainer:nil];
//    [[self container] didChangeValueForKey:@"peaks"];
}

- (void)replaceObjectInPeaksAtIndex:(int)index withObject:(JKPeakRecord *)aPeak{
	JKPeakRecord *replacedPeak = [peaks objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedPeak];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace Peak",@"")];
	}
	
	// Replace the peak from the array
    [[self container] willChangeValueForKey:@"peaks"];
	[peaks replaceObjectAtIndex:index withObject:aPeak];
    [aPeak setContainer:self];
    [replacedPeak setContainer:nil];
    [[self container] didChangeValueForKey:@"peaks"];
}

- (BOOL)validatePeak:(JKPeakRecord **)aPeak error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end peaks
#pragma mark -

#pragma mark Convenience methods

-(float)maxTime {
    return jk_stats_float_max(time, numberOfPoints);
}

-(float)minTime {
    return jk_stats_float_min(time, numberOfPoints);
}

-(float)maxTotalIntensity {
    return jk_stats_float_max(totalIntensity, numberOfPoints);
}

-(float)minTotalIntensity {
    return jk_stats_float_min(totalIntensity, numberOfPoints);
}



@synthesize numberOfPoints;
@synthesize baselinePointsCount;
@synthesize time;
@synthesize baselinePointsIntensities;
@synthesize totalIntensity;
@synthesize baselinePointsScans;
@end

