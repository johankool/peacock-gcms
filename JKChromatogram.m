//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKChromatogram.h"

#import "ChromatogramGraphDataSerie.h"
#import "JKGCMSDocument.h"
#import "JKPeakRecord.h"
#import "JKSpectrum.h"
#import "jk_statistics.h"
#import "netcdf.h"
#import "NSCoder+CArrayEncoding.h"

@implementation JKChromatogram

#pragma mark INITIALIZATION

- (id)init {
    return [self initWithDocument:nil];
}

- (id)initWithDocument:(JKGCMSDocument *)inDocument {
    return [self initWithDocument:inDocument forModel:@"TIC"];
}

- (id)initWithDocument:(JKGCMSDocument *)inDocument forModel:(NSString *)inModel {
    // designated initializer
    if ((self = [super init])) {
        [self setDocument:inDocument];
        [self setModel:inModel];
        peaks = [[NSMutableArray alloc] init];
       // baselinePoints = [[NSMutableArray alloc] init];
        baselinePointsCount = 0;
        baselinePointsScans = (int *) malloc(baselinePointsCount*sizeof(int));
        baselinePointsIntensities = (float *) malloc(baselinePointsCount*sizeof(float));

    }
    return self;
}

- (void)dealloc {
    free(baselinePointsScans);
    free(baselinePointsIntensities);

    [peaks release];
//    [baselinePoints release];
    [super dealloc];
}

#pragma mark ACTIONS

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

 

- (void)identifyPeaks{
	int i, j, answer;
	int start, end, top;
    float maximumIntensity;
    
    if ([[self peaks] count] > 0) {
        answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Delete current peaks?",@""),NSLocalizedString(@"Peaks that are already identified could cause doublures. It's recommended to delete the current peaks.",@""),NSLocalizedString(@"Delete",@""),NSLocalizedString(@"Cancel",@""),nil);
        if (answer == NSOKButton) {
            // Delete contents!
        } else if (answer == NSCancelButton) {
            return;
        }
    }
    
    // Baseline check
    if (baselinePointsCount <= 0) {
        answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return;
    }
    
    // Some initial settings
    NSMutableArray *newPeaks = [NSMutableArray array];
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
                [newPeaks addObject:[self peakFromScan:start toScan:end]];
            }
            
            // Continue looking for peaks from end of this peak
            i = end;			
        }
    }
    
    [self setPeaks:newPeaks];
}

- (JKPeakRecord *)peakFromScan:(int)startScan toScan:(int)endScan {
    // Baseline check
    if (baselinePointsCount <= 0) {
       NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return nil;
    }
    if (startScan > endScan) {
        int temp = startScan;
        startScan = endScan;
        endScan = temp;
    }
    JKPeakRecord *newPeak = [[JKPeakRecord alloc] init];
    [newPeak setPeakID:[document nextPeakID]];
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

    	if ([peak start] < [[peaksToCombine objectAtIndex:indexForStart] start]) {
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
    [peak setStart:[[peaksToCombine objectAtIndex:indexForStart] start]];
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

- (NSUndoManager *)undoManager {
    return [[self document] undoManager];
}

- (float)highestPeakHeight {
    highestPeakHeight = 0.0f;
    
    NSEnumerator *peakEnumerator = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;

    while ((peak = [peakEnumerator nextObject]) != nil) {
    	if ([[peak height] floatValue] > highestPeakHeight) {
            highestPeakHeight = [[peak height] floatValue];
        }
    }
    
    return highestPeakHeight;
}

- (float)largestPeakSurface {
    largestPeakSurface = 0.0f;
    
    NSEnumerator *peakEnumerator = [[self peaks] objectEnumerator];
    JKPeakRecord *peak;
    
    while ((peak = [peakEnumerator nextObject]) != nil) {
    	if ([[peak surface] floatValue] > largestPeakSurface) {
            largestPeakSurface = [[peak surface] floatValue];
        }
    }
    
    return largestPeakSurface;
}



#pragma mark NSCODING

- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeInt:2 forKey:@"version"];
		[coder encodeObject:document forKey:@"document"];
		[coder encodeObject:model forKey:@"model"];
        [coder encodeObject:peaks forKey:@"peaks"];
//      [coder encodeInt:numberOfPoints forKey:@"numberOfPoints"];
//		[coder encodeBytes:(void *)time length:numberOfPoints*sizeof(float) forKey:@"time"];
//		[coder encodeBytes:(void *)totalIntensity length:numberOfPoints*sizeof(float) forKey:@"totalIntensity"];
        
        [coder encodeFloatArray:time withCount:numberOfPoints forKey:@"time"];
        [coder encodeFloatArray:totalIntensity withCount:numberOfPoints forKey:@"totalIntensity"];
        
		//[coder encodeObject:baselinePoints forKey:@"baselinePoints"];
        [coder encodeIntArray:baselinePointsScans withCount:baselinePointsCount forKey:@"baselinePointsScans"];
        [coder encodeFloatArray:baselinePointsIntensities withCount:baselinePointsCount forKey:@"baselinePointsIntensities"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
        int version = [coder decodeIntForKey:@"version"];
        document = [[coder decodeObjectForKey:@"document"] retain];            
        model = [[coder decodeObjectForKey:@"model"] retain];
        peaks = [[coder decodeObjectForKey:@"peaks"] retain];
         
        
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
            time = (float *) malloc(1*sizeof(float));
            totalIntensity = (float *) malloc(1*sizeof(float));
 
            float *temporaryFloatArray = [coder decodeFloatArrayForKey:@"time" returnedCount:&length];
            [self setTime:(float *)temporaryFloatArray withCount:length];
            temporaryFloatArray = [coder decodeFloatArrayForKey:@"totalIntensity" returnedCount:&length];
            [self setTotalIntensity:(float *)temporaryFloatArray withCount:length];
            
            int *temporaryIntArray = [coder decodeIntArrayForKey:@"baselinePointsScans" returnedCount:&length];
            baselinePointsCount = length;
            baselinePointsScans = (int *) malloc(length*sizeof(int));
            baselinePointsScans = temporaryIntArray;
            
            temporaryFloatArray = [coder decodeFloatArrayForKey:@"baselinePointsIntensities" returnedCount:&length];           
            baselinePointsIntensities = (float *) malloc(length*sizeof(float));
            baselinePointsIntensities = temporaryFloatArray;
        }
         

         
 	} 
    return self;
}

#pragma mark -
#pragma mark ACCESSORS

- (JKGCMSDocument *)document {
    return document;
}

- (void)setDocument:(JKGCMSDocument *)inDocument {
    if (inDocument != document) {
        [inDocument retain];
        [document autorelease];
        document = inDocument;        
    }
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

- (int)numberOfPoints {
    return numberOfPoints;
}

- (void)setTime:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    time = (float *) realloc(time, numberOfPoints*sizeof(float));
    memcpy(time, inArray, numberOfPoints*sizeof(float));
}

- (float *)time {
    return time;
}

- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue {
    numberOfPoints = inValue;
    totalIntensity = (float *) realloc(totalIntensity, numberOfPoints*sizeof(float));
    memcpy(totalIntensity, inArray, numberOfPoints*sizeof(float));
}

- (float *)totalIntensity {
    return totalIntensity;
}

- (int)baselinePointsCount {
    return baselinePointsCount;
}

- (void)setBaselinePointsScans:(int *)inArray withCount:(int)inValue {
    baselinePointsCount = inValue;
    baselinePointsScans = (int *) realloc(baselinePointsScans, baselinePointsCount*sizeof(int));
    memcpy(baselinePointsScans, inArray, baselinePointsCount*sizeof(int));
}

- (int *)baselinePointsScans {
    return baselinePointsScans;
}

- (void)setBaselinePointsIntensities:(float *)inArray withCount:(int)inValue {
    baselinePointsCount = inValue;
    baselinePointsIntensities = (float *) realloc(baselinePointsIntensities, baselinePointsCount*sizeof(float));
    memcpy(baselinePointsIntensities, inArray, baselinePointsCount*sizeof(float));
}

- (float *)baselinePointsIntensities {
    return baselinePointsIntensities;
}



//// Mutable To-Many relationship baselinePoints
//- (NSMutableArray *)baselinePoints {
//	return baselinePoints;
//}
//
//- (void)setBaselinePoints:(NSMutableArray *)inValue {
//    [inValue retain];
//    [baselinePoints release];
//    baselinePoints = inValue;
//    [self cacheBaselinePoints];
//}
//
//- (int)countOfBaselinePoints {
//    return [[self baselinePoints] count];
//}
//
//- (NSMutableDictionary *)objectInBaselinePointsAtIndex:(int)index {
//    return [[self baselinePoints] objectAtIndex:index];
//}
//
//- (void)getBaselinePoint:(NSMutableDictionary **)someBaselinePoints range:(NSRange)inRange {
//    // Return the objects in the specified range in the provided buffer.
//    [baselinePoints getObjects:someBaselinePoints range:inRange];
//}
//
//- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index {
//	// Add the inverse action to the undo stack
//	NSUndoManager *undo = [self undoManager];
//	[[undo prepareWithInvocationTarget:self] removeObjectFromBaselinePointsAtIndex:index];
//	
//	if (![undo isUndoing]) {
//		[undo setActionName:NSLocalizedString(@"Insert BaselinePoint",@"")];
//	}
//	
//	// Add aBaselinePoint to the array baselinePoints
//	[baselinePoints insertObject:aBaselinePoint atIndex:index];
//    [self cacheBaselinePoints];
//}
//
//- (void)removeObjectFromBaselinePointsAtIndex:(int)index{
//	NSMutableDictionary *aBaselinePoint = [baselinePoints objectAtIndex:index];
//	
//	// Add the inverse action to the undo stack
//	NSUndoManager *undo = [self undoManager];
//	[[undo prepareWithInvocationTarget:self] insertObject:aBaselinePoint inBaselinePointsAtIndex:index];
//	
//	if (![undo isUndoing]) {
//		[undo setActionName:NSLocalizedString(@"Delete BaselinePoint",@"")];
//	}
//	
//	// Remove the peak from the array
//	[baselinePoints removeObjectAtIndex:index];
//    [self cacheBaselinePoints];
//}
//
//- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSMutableDictionary *)aBaselinePoint{
//	NSMutableDictionary *replacedBaselinePoint = [baselinePoints objectAtIndex:index];
//	
//	// Add the inverse action to the undo stack
//	NSUndoManager *undo = [self undoManager];
//	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedBaselinePoint];
//	
//	if (![undo isUndoing]) {
//		[undo setActionName:NSLocalizedString(@"Replace BaselinePoint",@"")];
//	}
//	
//	// Replace the peak from the array
//	[baselinePoints replaceObjectAtIndex:index withObject:aBaselinePoint];
//    [self cacheBaselinePoints];
//}
//
//- (BOOL)validateBaselinePoint:(NSMutableDictionary **)aBaselinePoint error:(NSError **)outError {
//    // Implement validation here...
//    return YES;
//} 
//
//- (void)cacheBaselinePoints {
//    int i;
//    baselinePointsCount = [self countOfBaselinePoints];
//    baselinePointsScans = (int *) realloc(baselinePointsScans, baselinePointsCount*sizeof(int));
//    baselinePointsIntensities = (float *) realloc(baselinePointsIntensities, baselinePointsCount*sizeof(float));
//
//    for (i = 0; i < baselinePointsCount; i++) {
//        baselinePointsScans[i] = [[[[self baselinePoints] objectAtIndex:i] valueForKey:@"Scan"] intValue];
//        baselinePointsIntensities[i] = [[[[self baselinePoints] objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
//    }
//}
//
//// end baselinePoints

// Mutable To-Many relationship peaks
- (NSMutableArray *)peaks {
	return peaks;
}

- (void)setPeaks:(NSMutableArray *)inValue {
    [[self document] willChangeValueForKey:@"peaks"];
    [inValue retain];
    [peaks release];
    peaks = inValue;
    [[self document] didChangeValueForKey:@"peaks"];
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
    [[self document] willChangeValueForKey:@"peaks"];
	[peaks insertObject:aPeak atIndex:index];
    [[self document] didChangeValueForKey:@"peaks"];
}

- (void)removeObjectFromPeaksAtIndex:(int)index{
	JKPeakRecord *aPeak = [peaks objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aPeak inPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Peak",@"")];
	}
	
	// Remove the peak from the array
    [[self document] willChangeValueForKey:@"peaks"];
	[peaks removeObjectAtIndex:index];
    [[self document] didChangeValueForKey:@"peaks"];
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
    [[self document] willChangeValueForKey:@"peaks"];
	[peaks replaceObjectAtIndex:index withObject:aPeak];
    [[self document] didChangeValueForKey:@"peaks"];
}

- (BOOL)validatePeak:(JKPeakRecord **)aPeak error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end peaks


#pragma mark OBSOLETE ?!

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



@end

