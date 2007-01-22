//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKChromatogram.h"
#import "JKSpectrum.h"
#import "JKGCMSDocument.h"
#import "netcdf.h"
#import "ChromatogramGraphDataSerie.h"
#import "JKPeakRecord.h"

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
        baselinePoints = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    [peaks release];
    [baselinePoints release];
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
	int i, j, count;
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
	float baselineWindowWidthF = [[[self document] baselineWindowWidth] floatValue];
	float baselineDistanceThresholdF = [[[self document] baselineDistanceThreshold] floatValue];
	float baselineSlopeThresholdF = [[[self document] baselineSlopeThreshold] floatValue];
	float baselineDensityThresholdF = [[[self document] baselineDensityThreshold] floatValue];
    NSMutableDictionary *aBaselinePoint = nil;
    
    [[[self document] undoManager] registerUndoWithTarget:self
                                      selector:@selector(setBaselinePoints:)
                                        object:[baselinePoints mutableCopy]];
    [[[self document] undoManager] setActionName:NSLocalizedString(@"Identify Baseline",@"")];
    
	[self willChangeValueForKey:@"baseline"];
	
    [baselinePoints removeAllObjects];
	
	for (i = 0; i < count; i++) {
		minimumSoFar = intensity[i];
		for (j = i - baselineWindowWidthF/2; j < i + baselineWindowWidthF/2; j++) {
			if (intensity[j] < minimumSoFar) {
				minimumSoFar = intensity[j];
			}
		}
		minimum[i] = minimumSoFar;	
	}
	
	for (i = 0; i < count; i++) {
		distance[i] = fabs(intensity[i] - minimum[i]);
	}
	
	for (i = 0; i < count-1; i++) {
		slope[i] = (fabs((intensity[i+1]-intensity[i])/(time[i+1]-time[i])) + fabs((intensity[i]-intensity[i-1])/(time[i]-time[i-1])))/2;
	}
	slope[count-1] = 0.0;
	
	for (i = 0; i < count; i++) {
		densitySoFar = 0.0;
		for (j = i - baselineWindowWidthF/2; j < i + baselineWindowWidthF/2; j++) {
			distanceSquared = pow(fabs(intensity[j]-intensity[i]),2) + pow(fabs(time[j]-time[i]),2);
			if (distanceSquared != 0.0) densitySoFar = densitySoFar + 1/sqrt(distanceSquared);	
		}
		density[i] = densitySoFar;		
	}
	
	normalize(distance, count);
	normalize(slope, count);
	normalize(density, count);
	
    // Starting point
    aBaselinePoint = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:0], @"Scan",
                                                          [NSNumber numberWithFloat:intensity[0]], @"Total Intensity",
                                                          [NSNumber numberWithFloat:time[0]], @"Time", nil];
    [self insertObject:aBaselinePoint inBaselinePointsAtIndex:0];
    
	for (i = 1; i < count; i++) {
		if (distance[i] < baselineDistanceThresholdF && (slope[i] > -baselineSlopeThresholdF  && slope[i] < baselineSlopeThresholdF) && density[i] > baselineDensityThresholdF) { 
            aBaselinePoint = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:i], @"Scan",
                                                                  [NSNumber numberWithFloat:intensity[i]], @"Total Intensity", 
                                                                  [NSNumber numberWithFloat:time[i]], @"Time", nil];
            [self insertObject:aBaselinePoint inBaselinePointsAtIndex:[[self baselinePoints] count]];
		}
	}
    
    // Ending point
    aBaselinePoint = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:count-1], @"Scan",
                                                          [NSNumber numberWithFloat:intensity[count-1]], @"Total Intensity",
                                                          [NSNumber numberWithFloat:time[count-1]], @"Time", nil];
    [self insertObject:aBaselinePoint inBaselinePointsAtIndex:[[self baselinePoints] count]];
//    NSLog([baselinePoints description]);
}	

- (float)baselineValueAtScan:(int)inValue {
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
	int i = 0;
	int baselineCount = [baselinePoints count];
	float lowestScan, lowestInten, highestScan, highestInten;
	
	while (inValue > [[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] intValue] && i < baselineCount) {
		i++;
	} 
	
	if (i <= 0) {
		lowestScan = 0.0;
		lowestInten = 0.0;
		highestScan = [[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] floatValue];
		highestInten = [[[baselinePoints objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
	} else {
		lowestScan = [[[baselinePoints objectAtIndex:i-1] valueForKey:@"Scan"] floatValue];
		lowestInten = [[[baselinePoints objectAtIndex:i-1] valueForKey:@"Total Intensity"] floatValue];
		highestScan = [[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] floatValue];
		highestInten = [[[baselinePoints objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
	}
	
	return (highestInten-lowestInten) * ((inValue-lowestScan)/(highestScan-lowestScan)) + lowestInten; 
}

- (int)baselinePointsIndexAtScan:(int)inValue {
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
	int i = 0;
	int baselineCount = [baselinePoints count];
	
	while (inValue > [[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] intValue] && i < baselineCount) {
		i++;
	} 
	
	return i; 
}

 

- (void)identifyPeaks{
	int i,j, peakCount, answer;
	int start, end, top;
	float a, b, height, surface, maximumSurface, maximumHeight;
	float startTime, topTime, endTime, widthTime;
	float time1, time2;
	float height1, height2;
	float retentionIndex;//, retentionIndexSlope, retentionIndexRemainder;
    JKSpectrum *spectrum;
    
    
    if ([[self peaks] count] > 0) {
        answer = NSRunCriticalAlertPanel(NSLocalizedString(@"Delete current peaks?",@""),NSLocalizedString(@"Peaks that are already identified could cause doublures. It's recommended to delete the current peaks.",@""),NSLocalizedString(@"Delete",@""),NSLocalizedString(@"Cancel",@""),NSLocalizedString(@"Keep",@""));
        if (answer == NSOKButton) {
            // Delete contents!
            [self willChangeValueForKey:@"peaks"];
            [[self peaks] removeAllObjects];
            [self didChangeValueForKey:@"peaks"];			
        } else if (answer == NSCancelButton) {
            return;
        } else {
            // Continue by adding peaks
        }
    }
    
    // Baseline check
    if ([[self baselinePoints] count] <= 0) {
        //			JKLogDebug([baseline description]);
        //			JKLogWarning(@"No baseline set. Can't recognize peaks without one.");
        answer = NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return;
    }
    
    // Some initial settings
    i = 0;
    peakCount = 1;	
    maximumSurface = 0.0;
    maximumHeight = 0.0;
    float peakIdentificationThresholdF = [[[self document] peakIdentificationThreshold] floatValue];
    
    for (i = 0; i < numberOfPoints; i++) {
        if (totalIntensity[i]/[self baselineValueAtScan:i] > (1.0 + peakIdentificationThresholdF)){
            
            // determine: high, start, end
            // start
            for (j=i; totalIntensity[j] > totalIntensity[j-1]; j--) {				
            }
            start = j;
            if (start < 0) start = 0; // Don't go outside bounds!
            
            // top
            for (j=start; totalIntensity[j] < totalIntensity[j+1]; j++) {
            }
            top=j;
            if (top >= numberOfPoints) top = numberOfPoints-1; // Don't go outside bounds!
            
            // end
            for (j=top; totalIntensity[j] > totalIntensity[j+1]; j++) {				
            }
            end=j;
            if (end >= numberOfPoints-1) end = numberOfPoints-1; // Don't go outside bounds!
            
            // start time
            startTime = [self timeForScan:start];
            
            // top time
            topTime = [self timeForScan:top];
            
            // end time
            endTime = [self timeForScan:end];
            
            // width
            widthTime = endTime - startTime;
            
            // baseline left
            float baselineAtStart = [self baselineValueAtScan:start];
            if (baselineAtStart > totalIntensity[start]) {
                baselineAtStart = totalIntensity[start];
            }
            // baseline right
            float baselineAtEnd = [self baselineValueAtScan:end];
            if (baselineAtEnd > totalIntensity[end]) {
                baselineAtEnd = totalIntensity[end];
            }
            
            // Calculations needed for height and width
            a= baselineAtEnd-baselineAtStart;
            b= endTime-startTime;
            
            // height
            //height = intensities[top]-(intensities[start] + (a/b)*(topTime-startTime) );
            height = totalIntensity[top] - [self baselineValueAtScan:top];
            // Keep track of what the heighest peak is
            if (height > maximumHeight) maximumHeight = height;
            
            // surface  WARNING! This is an absolute, not a relative peak surface!
            surface = 0.0;
            for (j=start; j < end; j++) {
                time1 = [self timeForScan:j];
                time2 = [self timeForScan:j+1];
                
                height1 = totalIntensity[j]-(baselineAtStart + (a/b)*(time1-startTime) );
                height2 = totalIntensity[j+1]-(baselineAtStart + (a/b)*(time2-startTime) );
                
                if (height1 > height2) {
                    surface = surface + (height2 * (time2-time1)) + ((height1-height2) * (time2-time1) * 0.5);
                } else {
                    surface = surface + (height1 * (time2-time1)) + ((height2-height1) * (time2-time1) * 0.5);					
                }
            }
            // Keep track of what the largest peak is
            if (surface > maximumSurface) maximumSurface = surface;
            
            if (top != start && top != end && surface > 0.0) { // Sanity check
                                                               // Add peak
                [self addPeakFromScan:start toScan:end];
 //               JKPeakRecord *record = [[JKPeakRecord alloc] init];
//                [record setDocument:[self document]];
//                [record setValue:[NSNumber numberWithInt:peakCount] forKey:@"peakID"];
//                [record setValue:[NSNumber numberWithInt:start] forKey:@"start"];
//                [record setValue:[NSNumber numberWithInt:top] forKey:@"top"];
//                [record setValue:[NSNumber numberWithInt:end] forKey:@"end"];
//                [record setValue:[NSNumber numberWithFloat:baselineAtStart] forKey:@"baselineLeft"];
//                [record setValue:[NSNumber numberWithFloat:baselineAtEnd] forKey:@"baselineRight"];
//                
//                [record setValue:[NSNumber numberWithFloat:height] forKey:@"height"];
//                [record setValue:[NSNumber numberWithFloat:surface] forKey:@"surface"];
//                
//                retentionIndex = topTime * [[[self document] retentionIndexSlope] floatValue] + [[[self document] retentionIndexRemainder] floatValue];
//                [record setValue:[NSNumber numberWithFloat:retentionIndex] forKey:@"retentionIndex"];
//                                
//                [record setSpectrum:[[self document] spectrumForScan:top]];
//                [record setModel:[self model]];
//                [self insertObject:record inPeaksAtIndex:[[self peaks] count]];
//                [[self document] insertObject:record inPeaksAtIndex:[[[self document] peaks] count]];
                peakCount++;
//                [record release]; 
            }
            
            // Continue looking for peaks from end of this peak
            i = end;			
        }
    }
    
    // Walk through the found peaks to calculate a normalized surface area and normalized height
//    peakCount = [[self peaks] count];
//    for (i = 0; i < peakCount; i++) {
//        [[[self peaks] objectAtIndex:i] setValue:[NSNumber numberWithFloat:[[[[self peaks] objectAtIndex:i] valueForKey:@"height"] floatValue]*100/maximumHeight] forKey:@"normalizedHeight"];
//        [[[self peaks] objectAtIndex:i] setValue:[NSNumber numberWithFloat:[[[[self peaks] objectAtIndex:i] valueForKey:@"surface"] floatValue]*100/maximumSurface] forKey:@"normalizedSurface"];
//    }
}

- (void)addPeakFromScan:(int)startScan toScan:(int)endScan {
    // Baseline check
    if ([[self baselinePoints] count] <= 0) {
       NSRunInformationalAlertPanel(NSLocalizedString(@"No Baseline Set",@""),NSLocalizedString(@"No baseline have yet been identified in the chromatogram. Use the 'Identify Baseline' option first.",@""),NSLocalizedString(@"OK",@"OK"),nil,nil);
        return;
    }
    if (startScan > endScan) {
        int temp = startScan;
        startScan = endScan;
        endScan = temp;
    }
    JKPeakRecord *newPeak = [[JKPeakRecord alloc] init];
    [newPeak setStart:startScan];
    [newPeak setEnd:endScan];
    [newPeak setChromatogram:self];
    [newPeak setValue:[NSNumber numberWithFloat:[self baselineValueAtScan:startScan]] forKey:@"baselineLeft"];
    [newPeak setValue:[NSNumber numberWithFloat:[self baselineValueAtScan:endScan]] forKey:@"baselineRight"];
    [self insertObject:newPeak inPeaksAtIndex:[[self peaks] count]];
    [[self document] insertObject:newPeak inPeaksAtIndex:[[[self document] peaks] count]];
    [newPeak release];     
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
    [[self document] willChangeValueForKey:@"peaks"];
    for (i = 0; i < peakCount; i++) {
        if (i != indexForCombinedPeak) {
            [[self peaks] removeObject:[peaksToCombine objectAtIndex:i]];
            [[[self document] peaks] removeObject:[peaksToCombine objectAtIndex:i]];
        }
    }
    [self didChangeValueForKey:@"peaks"];
    [[self document] didChangeValueForKey:@"peaks"];
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
            return i;
        }
    }
    return numberOfPoints-1;
}

- (NSUndoManager *)undoManager {
    return [[self document] undoManager];
}

#pragma mark NSCODING

- (void)encodeWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
		[coder encodeInt:1 forKey:@"version"];
		[coder encodeConditionalObject:document forKey:@"document"];
		[coder encodeObject:model forKey:@"model"];
		[coder encodeObject:baselinePoints forKey:@"baselinePoints"];
        [coder encodeObject:peaks forKey:@"peaks"];
        [coder encodeInt:numberOfPoints forKey:@"numberOfPoints"];
		[coder encodeBytes:(void *)time length:numberOfPoints*sizeof(float) forKey:@"time"];
		[coder encodeBytes:(void *)totalIntensity length:numberOfPoints*sizeof(float) forKey:@"totalIntensity"];
        
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ( [coder allowsKeyedCoding] ) {
        document = [coder decodeObjectForKey:@"document"];            
        model = [[coder decodeObjectForKey:@"model"] retain];
        baselinePoints = [[coder decodeObjectForKey:@"baselinePoints"] retain];
        peaks = [[coder decodeObjectForKey:@"peaks"] retain];
         
        numberOfPoints = [coder decodeIntForKey:@"numberOfPoints"];
        
        const uint8_t *temporary = NULL; //pointer to a temporary buffer returned by the decoder.
        unsigned int length;
        time = (float *) malloc(1*sizeof(float));
        totalIntensity = (float *) malloc(1*sizeof(float));
        
        temporary	= [coder decodeBytesForKey:@"time" returnedLength:&length];
        [self setTime:(float *)temporary withCount:numberOfPoints];
        
        temporary	= [coder decodeBytesForKey:@"totalIntensity" returnedLength:&length];
        [self setTotalIntensity:(float *)temporary withCount:numberOfPoints];
 	} 
    return self;
}

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

// Mutable To-Many relationship baselinePoints
- (NSMutableArray *)baselinePoints {
	return baselinePoints;
}

- (void)setBaselinePoints:(NSMutableArray *)inValue {
    [inValue retain];
    [baselinePoints release];
    baselinePoints = inValue;
}

- (int)countOfBaselinePoints {
    return [[self baselinePoints] count];
}

- (NSMutableDictionary *)objectInBaselinePointsAtIndex:(int)index {
    return [[self baselinePoints] objectAtIndex:index];
}

- (void)getBaselinePoint:(NSMutableDictionary **)someBaselinePoints range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [baselinePoints getObjects:someBaselinePoints range:inRange];
}

- (void)insertObject:(NSMutableDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromBaselinePointsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert BaselinePoint",@"")];
	}
	
	// Add aBaselinePoint to the array baselinePoints
	[baselinePoints insertObject:aBaselinePoint atIndex:index];
}

- (void)removeObjectFromBaselinePointsAtIndex:(int)index{
	NSMutableDictionary *aBaselinePoint = [baselinePoints objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aBaselinePoint inBaselinePointsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete BaselinePoint",@"")];
	}
	
	// Remove the peak from the array
	[baselinePoints removeObjectAtIndex:index];
}

- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSMutableDictionary *)aBaselinePoint{
	NSMutableDictionary *replacedBaselinePoint = [baselinePoints objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedBaselinePoint];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace BaselinePoint",@"")];
	}
	
	// Replace the peak from the array
	[baselinePoints replaceObjectAtIndex:index withObject:aBaselinePoint];
}

- (BOOL)validateBaselinePoint:(NSMutableDictionary **)aBaselinePoint error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end baselinePoints

// Mutable To-Many relationship peaks
- (NSMutableArray *)peaks {
	return peaks;
}

- (void)setPeaks:(NSMutableArray *)inValue {
    [inValue retain];
    [peaks release];
    peaks = inValue;
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
	[peaks insertObject:aPeak atIndex:index];
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
	[peaks removeObjectAtIndex:index];
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
	[peaks replaceObjectAtIndex:index withObject:aPeak];
}

- (BOOL)validatePeak:(JKPeakRecord **)aPeak error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end peaks


#pragma mark OBSOLETE ?!

//-(void)getChromatogramData
//{
//    int		num_pts;
//    float	*x;
//    float 	*y;
//    int     	dummy, dimid, varid_scanaqtime, varid_totintens;
//    BOOL	hasVarid_scanaqtime;
//    
//    // NSDate *startT;
//    // startT = [NSDate date];
//    hasVarid_scanaqtime = YES;
//
//    if ([[[self document] dataModel] hasSpectra]) {
//        // GCMS file
//        dummy = nc_inq_dimid([self ncid], "scan_number", &dimid);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension failed. Report error #%d.", dummy); return; }
//
//        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_number dimension length failed. Report error #%d.", dummy); return;}
//        
//        dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return;}
//
//        dummy = nc_inq_varid([self ncid], "total_intensity", &varid_totintens);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting total_intensity variable failed. Report error #%d.", dummy);  return;}
//        
//    } else {
//        // GC file
//        dummy = nc_inq_dimid([self ncid], "point_number", &dimid);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension failed. Report error #%d.", dummy); return;}
//
//        dummy = nc_inq_dimlen([self ncid], dimid, (void *) &num_pts);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting point_number dimension length failed. Report error #%d.", dummy); return;}
//        
//        dummy = nc_inq_varid([self ncid], "raw_data_retention", &varid_scanaqtime);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting raw_data_retention variable failed. Report error #%d.", dummy); hasVarid_scanaqtime = NO;}
//        
//        dummy = nc_inq_varid([self ncid], "ordinate_values", &varid_totintens);
//        if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting ordinate_values variable failed. Report error #%d.", dummy);            return;}
//    }
//
//    // stored as floats in file, but I need floats which can be converted automatically by NetCDF so no worry!
//    x = (float *) malloc(num_pts*sizeof(float));
//    y = (float *) malloc(num_pts*sizeof(float));
//
//     dummy = nc_get_var_float([self ncid], varid_scanaqtime, x);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scanaqtime variables failed. Report error #%d.", dummy); return;}
//     minTime = 0.0; maxTime = 3600.0; // replace with sensible times
//     
//     dummy = nc_get_var_float([self ncid], varid_totintens, y);
//     if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting totintens variables failed. Report error #%d.", dummy); return;}
//     minTotalIntensity = 0.0; maxTotalIntensity = 1e8; // replace with sensible values
//
//     [self setTime:x withCount:num_pts];
//     [self setTotalIntensity:y withCount:num_pts];
//
//    //    JKLogDebug(@"Read time: %g seconds", -[startT timeIntervalSinceNow]);
//}
    

//-(float)maxTime {
//    return maxTime;
//}
//
//-(float)minTime {
//    return minTime;
//}
//
//-(float)maxTotalIntensity {
//    return maxTotalIntensity;
//}
//
//-(float)minTotalIntensity {
//    return minTotalIntensity;
//}


//-(float)timeForScan:(int)scan {
//    int dummy, varid_scanaqtime;
//    float   x;
//    
//    dummy = nc_inq_varid([self ncid], "scan_acquisition_time", &varid_scanaqtime);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_acquisition_time variable failed. Report error #%d.", dummy); return -1.0;}
//    
//    dummy = nc_get_var1_float([self ncid], varid_scanaqtime, (void *) &scan, &x);
//    
//    return x;
//}

//-(float *)xValuesSpectrum:(int)scan {
//    int i, dummy, start, end, varid_mass_value;
//    float 	xx;
//    float 	*x;
//    int		num_pts;
//    
//    dummy = nc_inq_varid([self ncid], "mass_values", &varid_mass_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting mass_value variable failed. Report error #%d.", dummy);        return x;}
//    
//    start = [self startValuesSpectrum:scan];
//    end = [self endValuesSpectrum:scan];
//    num_pts = end - start;
//    
//    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
//    x = (float *) malloc((num_pts+1)*sizeof(float));
//    
//    for(i = start; i < end; i++) {
//        dummy = nc_get_var1_float([self ncid], varid_mass_value, (void *) &i, &xx);
//        *(x + (i-start)) = xx;
//        if(maxXValuesSpectrum < xx) {
//            maxXValuesSpectrum = xx;
//        }
//        if(minXValuesSpectrum > xx || i == start) {
//            minXValuesSpectrum = xx;
//        }
//        
//    }
//    
//    return x;    
//}
//
//-(float *)yValuesSpectrum:(int)scan {
//    int i, dummy, start, end, varid_intensity_value;
//    float     	yy;
//    float 	*y;
//    int		num_pts;
//    
//    dummy = nc_inq_varid([self ncid], "intensity_values", &varid_intensity_value);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting intensity_value variable failed. Report error #%d.", dummy); return y;}
//    
//    start = [self startValuesSpectrum:scan];
//    end = [self endValuesSpectrum:scan];
//    num_pts = end - start;
//    
//    JKLogDebug(@"start= %d, end = %d, count = %d",start, end, num_pts);
//    y = (float *) malloc((num_pts)*sizeof(float));
//    
//    //    dummy = nc_get_vara_float([self ncid], varid_intensity_value, start, num_pts, y);
//    //    minYValuesSpectrum = 0.0; minYValuesSpectrum = 80000.0;
//    
//    for(i = start; i < end; i++) {
//        dummy = nc_get_var1_float([self ncid], varid_intensity_value, (void *) &i, &yy);
//        *(y + (i-start)) = yy;
//        if(maxYValuesSpectrum < yy) {
//            maxYValuesSpectrum = yy;
//        }
//        if(minYValuesSpectrum > yy || i == start) {
//            minYValuesSpectrum = yy;
//        }
//    };
//    
//    return y;
//}
//
//-(int)startValuesSpectrum:(int)scan {
//    int dummy, start, varid_scan_index;
//    
//    dummy = nc_inq_varid(ncid, "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//    
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &start);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//    
//    return start;
//}
//
//
//-(int)endValuesSpectrum:(int)scan {
//    int dummy, end, varid_scan_index;
//    
//    dummy = nc_inq_varid([self ncid], "scan_index", &varid_scan_index);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable failed. Report error #%d.", dummy); return 0;}
//    
//    scan++;
//    dummy = nc_get_var1_int(ncid, varid_scan_index, (void *) &scan, &end);
//    if(dummy != NC_NOERR) { NSBeep(); JKLogError(@"Getting scan_index variable at index %d failed. Report error #%d.", scan, dummy); return 0;}
//    
//    return end;
//}
//
//
//-(unsigned int)countOfSpectra {
//    // implementation specific code
//    return [self numberOfPoints]; 
//}
//
//-(JKSpectrum *)objectInSpectraAtIndex:(unsigned int)index {
//    // implementation specific code
//    return nil;
//}


@end

