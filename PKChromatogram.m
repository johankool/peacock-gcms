//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
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

#import "PKChromatogram.h"

#import "NSCoder+CArrayEncoding.h"
#import "NSString+ModelCompare.h"
#import "PKAppDelegate.h"
#import "PKChromatogramDataSeries.h"
#import "PKGCMSDocument.h"
#import "PKPeakRecord.h"
#import "PKPluginProtocol.h"
#import "PKSpectrum.h"
#import "netcdf.h"
#import "pk_statistics.h"

@implementation PKChromatogram

#pragma mark Initialization & deallocation
- (id)init {
    return [self initWithModel:@"TIC"];
}

- (id)initWithModel:(NSString *)inModel {
    // Designated initializer
    if ((self = [super init])) {
        model = [inModel retain];
        time = (float *) malloc(1*sizeof(float));
        totalIntensity = (float *) malloc(1*sizeof(float));

        peaks = [[NSMutableArray alloc] init];
        baselinePoints = [[NSMutableArray alloc] init];
        
        baselinePointsCount = 0;
        baselinePointsScans = (int *) malloc(sizeof(int));
        baselinePointsIntensities = (float *) malloc(sizeof(float));
        _baselinePointsCacheUpToDate = NO;
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
    [baselinePoints release];
    [super dealloc];
}
#pragma mark -

#pragma mark Action PlugIn style
- (BOOL)detectBaselineAndReturnError:(NSError **)error {
    PKLogEnteringMethod();
    NSString *baselineDetectionMethod = [[self document] baselineDetectionMethod];
    if (!baselineDetectionMethod || [baselineDetectionMethod isEqualToString:@""]) {
        // Error 805
        // Baseline Detection Method not set
        NSString *errorString = NSLocalizedString(@"Baseline Detection Method not set", @"Baseline Detection Method not set error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:805
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;             
        return NO;
    }
    
    NSObject <PKPluginProtocol> *plugIn = [[[NSApp delegate] baselineDetectionMethods] valueForKey:baselineDetectionMethod];
    if (plugIn) {
        NSObject <PKBaselineDetectionMethodProtocol> *object = [plugIn sharedObjectForMethod:baselineDetectionMethod];
        if (object) {
            // Restore method settings
            [object setSettings:[[self document] baselineDetectionSettingsForMethod:baselineDetectionMethod]];
            [object prepareForAction];
            NSMutableArray *newBaseline = [[object baselineForChromatogram:self error:error] mutableCopy];
            [object cleanUpAfterAction];
            if (newBaseline) {
                [self setBaselinePoints:newBaseline];
                [newBaseline release];
                // Save method settings on success
                [[self document] setBaselineDetectionSettings:[object settings] forMethod:baselineDetectionMethod];
                return YES;
            } else {
                [newBaseline release];
                return NO;
            }
         } else {
            // Error 801
            // Invalid Plugin
             NSString *errorString = NSLocalizedString(@"PlugIn does not implement method as claimed", @"PlugIn does not implement method as claimed error");
             NSDictionary *userInfoDict =
             [NSDictionary dictionaryWithObject:errorString
                                         forKey:NSLocalizedDescriptionKey];
             NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                          code:801
                                                      userInfo:userInfoDict] autorelease];
             *error = anError;             
             return NO;
        }
    } else {
        // Error 800
        // Plugin failed to initialize
        NSString *errorString = NSLocalizedString(@"PlugIn Unloaded/Method not currently available", @"PlugIn Unloaded/Method not currently available error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:800
                                                 userInfo:userInfoDict] autorelease];
        *error = anError;                     
        return NO;
    }
}

- (BOOL)detectPeaksAndReturnError:(NSError **)error {
    NSString *peakDetectionMethod = [[self document] peakDetectionMethod];
    if (!peakDetectionMethod || [peakDetectionMethod isEqualToString:@""]) {
        // Error 806
        // Peak Detection Method not set
        NSString *errorString = NSLocalizedString(@"Peak Detection Method not set", @"Peak Detection Method not set error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:806
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;             
        return NO;
    }
    
    NSObject <PKPluginProtocol> *plugIn = [[[NSApp delegate] peakDetectionMethods] valueForKey:peakDetectionMethod];
    if (plugIn) {
        NSObject <PKPeakDetectionMethodProtocol> *object = [plugIn sharedObjectForMethod:peakDetectionMethod];
        if (object) {
            // Restore method settings
            [object setSettings:[[self document] peakDetectionSettingsForMethod:peakDetectionMethod]];
            [object prepareForAction];
            NSArray *newPeaks = [object peaksForChromatogram:self error:error];
            [object cleanUpAfterAction];
            if (newPeaks) {
                // Add peaks, not replacing any that are already there!
                for (PKPeakRecord *newPeak in newPeaks) {
                    [self insertObject:newPeak inPeaksAtIndex:[self countOfPeaks]];
                }
                // Save method settings on success
                [[self document] setPeakDetectionSettings:[object settings] forMethod:peakDetectionMethod];
                return YES;
            } else {
                return NO;
            }
        } else {
            // Error 801
            // Invalid Plugin
            NSString *errorString = NSLocalizedString(@"PlugIn does not implement method as claimed", @"PlugIn does not implement method as claimed error");
            NSDictionary *userInfoDict =
            [NSDictionary dictionaryWithObject:errorString
                                        forKey:NSLocalizedDescriptionKey];
            NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                           code:801
                                                       userInfo:userInfoDict] autorelease];
            *error = anError;             
            return NO;
        }
    } else {
        // Error 800
        // Plugin failed to initialize
        NSString *errorString = NSLocalizedString(@"PlugIn Unloaded/Method not currently available", @"PlugIn Unloaded/Method not currently available error");
        NSDictionary *userInfoDict =
        [NSDictionary dictionaryWithObject:errorString
                                    forKey:NSLocalizedDescriptionKey];
        NSError *anError = [[[NSError alloc] initWithDomain:@"Peacock"
                                                       code:800
                                                   userInfo:userInfoDict] autorelease];
        *error = anError;                     
        return NO;
    }
}
#pragma mark -

#pragma mark Actions
- (float)baselineValueAtScan:(int)inValue {
    NSAssert(inValue >= 0, @"Scan must be equal or larger than zero");
    
    if (!_baselinePointsCacheUpToDate)
        [self cacheBaselinePoints];
    
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
    
    if (!_baselinePointsCacheUpToDate)
        [self cacheBaselinePoints];
    
	int i = 0;
	
	while (inValue > baselinePointsScans[i] && i < baselinePointsCount) {
		i++;
	} 
	
	return i; 
}

- (void)cacheBaselinePoints {
    baselinePointsCount = [self countOfBaselinePoints];
    baselinePointsScans = (int *) realloc(baselinePointsScans, baselinePointsCount*sizeof(int));
    baselinePointsIntensities = (float *) realloc(baselinePointsIntensities, baselinePointsCount*sizeof(float));
 
    int i;
    NSDictionary *baselinePoint;
    for (i = 0; i < baselinePointsCount; i++) {
        baselinePoint = [[self baselinePoints] objectAtIndex:i];
        baselinePointsScans[i] = [[baselinePoint valueForKey:@"scan"] intValue];
        baselinePointsIntensities[i] = [[baselinePoint valueForKey:@"intensity"] floatValue];
    }
    _baselinePointsCacheUpToDate = YES;
}

- (PKPeakRecord *)peakFromScan:(int)startScan toScan:(int)endScan {
    // Baseline check
    if (baselinePointsCount <= 0) {
        NSError *error;
        if (![self detectBaselineAndReturnError:&error]) {
            [[self document] presentError:error];
        }
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
    
	for (PKPeakRecord *peak in [self peaks]) {
    	if (([peak start] == startScan) && ([peak end] == endScan)) {
            return peak;
        }
    }
    PKPeakRecord *newPeak = [[PKPeakRecord alloc] init];
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
    PKPeakRecord *peak;
    
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

    	if ([peak start] < [(PKPeakRecord *)[peaksToCombine objectAtIndex:indexForStart] start]) {
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
    [peak setStart:[(PKPeakRecord *)[peaksToCombine objectAtIndex:indexForStart] start]];
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
    
	for (PKPeakRecord *peak in [self peaks]) {
    	if ([[peak height] floatValue] > highestPeakHeight) {
            highestPeakHeight = [[peak height] floatValue];
        }
    }
    
    return highestPeakHeight;
}

- (float)largestPeakSurface {
    largestPeakSurface = 0.0f;
     
    for (PKPeakRecord *peak in [self peaks]) {
    	if ([[peak surface] floatValue] > largestPeakSurface) {
            largestPeakSurface = [[peak surface] floatValue];
        }
    }
    
    return largestPeakSurface;
}

- (void)removeUnidentifiedPeaks
{    
    NSMutableArray *peaksToSave = [NSMutableArray array];
	for (PKPeakRecord *peak in [self peaks]) {
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

- (NSComparisonResult)sortOrderComparedTo:(PKChromatogram *)otherChromatogram
{
    if ([[self model] isEqualToModelString:[otherChromatogram model]]) {
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

		[coder encodeInt:3 forKey:@"version"];
		[coder encodeObject:model forKey:@"model"];
        [coder encodeObject:peaks forKey:@"peaks"];
        
        [coder encodeFloatArray:time withCount:numberOfPoints forKey:@"time"];
        [coder encodeFloatArray:totalIntensity withCount:numberOfPoints forKey:@"totalIntensity"];
        
        [coder encodeObject:baselinePoints forKey:@"baselinePoints"];
//        [coder encodeIntArray:baselinePointsScans withCount:baselinePointsCount forKey:@"baselinePointsScans"];
//        [coder encodeFloatArray:baselinePointsIntensities withCount:baselinePointsCount forKey:@"baselinePointsIntensities"];
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
        PKPeakRecord *peak;
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

        } else if (version == 2) {
            unsigned int length;
  
            time = [coder decodeFloatArrayForKey:@"time" returnedCount:&length];
            numberOfPoints = length;

            totalIntensity = [coder decodeFloatArrayForKey:@"totalIntensity" returnedCount:&length];

            baselinePointsScans= [coder decodeIntArrayForKey:@"baselinePointsScans" returnedCount:&length];
            baselinePointsCount = length;
            
            baselinePointsIntensities = [coder decodeFloatArrayForKey:@"baselinePointsIntensities" returnedCount:&length];           
        } else {
            unsigned int length;
            
            time = [coder decodeFloatArrayForKey:@"time" returnedCount:&length];
            numberOfPoints = length;
            
            totalIntensity = [coder decodeFloatArrayForKey:@"totalIntensity" returnedCount:&length];

            baselinePoints = [[coder decodeObjectForKey:@"baselinePoints"] retain];
            
            // just so these get malloced, used as cache otherwise
            baselinePointsScans = (int *) malloc(2*sizeof(int));
            baselinePointsIntensities = (float *) malloc(2*sizeof(float));

        }
 	} 
    return self;
}
#pragma mark -

#pragma mark <#label#>
- (NSString *)legendEntry {
    return model;
}
#pragma mark -

#pragma mark Document
- (PKGCMSDocument *)document
{
    return (PKGCMSDocument *)[self container];
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

#pragma mark (to many relationships)
// Mutable To-Many relationship peaks
- (NSMutableArray *)peaks {
	return peaks;
}

- (void)setPeaks:(NSMutableArray *)inValue {
    [[self container] willChangeValueForKey:@"peaks"];
    PKPeakRecord *peak;
    if (inValue != peaks) {
   
        for (peak in peaks) {
            [peak setContainer:nil];
        }
        
        [inValue retain];
        [peaks release];

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

- (PKPeakRecord *)objectInPeaksAtIndex:(int)index {
    return [[self peaks] objectAtIndex:index];
}

- (void)getPeak:(PKPeakRecord **)somePeaks range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [peaks getObjects:somePeaks range:inRange];
}

- (void)insertObject:(PKPeakRecord *)aPeak inPeaksAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromPeaksAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Peak",@"")];
	}
	
	// Add aPeak to the array peaks
    [[self container] willChangeValueForKey:@"peaks"];
    if (!peaks)
        peaks = [[NSMutableArray alloc] init];
	[peaks insertObject:aPeak atIndex:index];
    [aPeak setContainer:self];
    [[self container] didChangeValueForKey:@"peaks"];
}

- (void)removeObjectFromPeaksAtIndex:(int)index{
    if (index >= [peaks count] || index < 0) {
        PKLogError(@"No peak at out-of-bounds index %d.", index);
        return;
    }
	PKPeakRecord *aPeak = [peaks objectAtIndex:index];
    if (!aPeak) {
        PKLogError(@"No peak found at index %d.", index);
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

- (void)replaceObjectInPeaksAtIndex:(int)index withObject:(PKPeakRecord *)aPeak{
	PKPeakRecord *replacedPeak = [peaks objectAtIndex:index];
	
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

- (BOOL)validatePeak:(PKPeakRecord **)aPeak error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end peaks

// Mutable To-Many relationship baselinePoints
- (NSMutableArray *)baselinePoints {
	return baselinePoints;
}

- (void)setBaselinePoints:(NSMutableArray *)inValue {
    [[self container] willChangeValueForKey:@"baselinePoints"];
    if (inValue != baselinePoints) {
        
        [inValue retain];
        [baselinePoints release];
        
        baselinePoints = inValue;
        _baselinePointsCacheUpToDate = NO;
    }
    
    [[self container] didChangeValueForKey:@"baselinePoints"];
}

- (int)countOfBaselinePoints {
    return [[self baselinePoints] count];
}

- (NSDictionary *)objectInBaselinePointsAtIndex:(int)index {
    return [[self baselinePoints] objectAtIndex:index];
}

- (void)getBaselinePoint:(NSDictionary **)someBaselinePoints range:(NSRange)inRange {
    // Return the objects in the specified range in the provided buffer.
    [baselinePoints getObjects:someBaselinePoints range:inRange];
}

- (void)insertObject:(NSDictionary *)aBaselinePoint inBaselinePointsAtIndex:(int)index {
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] removeObjectFromBaselinePointsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Insert Baseline Point",@"")];
	}
	
	// Add aBaselinePoint to the array baselinePoints
    [[self container] willChangeValueForKey:@"baselinePoints"];
    if (!baselinePoints)
        baselinePoints = [[NSMutableArray alloc] init];
	[baselinePoints insertObject:aBaselinePoint atIndex:index];
    _baselinePointsCacheUpToDate = NO;

    [[self container] didChangeValueForKey:@"baselinePoints"];
}

- (void)removeObjectFromBaselinePointsAtIndex:(int)index{
    if (index >= [baselinePoints count] || index < 0) {
        PKLogError(@"No baselinePoint at out-of-bounds index %d.", index);
        return;
    }
	NSDictionary *aBaselinePoint = [baselinePoints objectAtIndex:index];
    if (!aBaselinePoint) {
        PKLogError(@"No baselinePoint found at index %d.", index);
        return;
    }

	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] insertObject:aBaselinePoint inBaselinePointsAtIndex:index];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Delete Baseline Point",@"")];
	}
	
	// Remove the baselinePoint from the array
    [[self container] willChangeValueForKey:@"baselinePoints"];
	[baselinePoints removeObjectAtIndex:index];
    _baselinePointsCacheUpToDate = NO;

    [[self container] didChangeValueForKey:@"baselinePoints"];
}

- (void)replaceObjectInBaselinePointsAtIndex:(int)index withObject:(NSDictionary *)aBaselinePoint{
	NSDictionary *replacedBaselinePoint = [baselinePoints objectAtIndex:index];
	
	// Add the inverse action to the undo stack
	NSUndoManager *undo = [self undoManager];
	[[undo prepareWithInvocationTarget:self] replaceObjectAtIndex:index withObject:replacedBaselinePoint];
	
	if (![undo isUndoing]) {
		[undo setActionName:NSLocalizedString(@"Replace BaselinePoint",@"")];
	}
	
	// Replace the baselinePoint from the array
    [[self container] willChangeValueForKey:@"baselinePoints"];
	[baselinePoints replaceObjectAtIndex:index withObject:aBaselinePoint];
    _baselinePointsCacheUpToDate = NO;
    [[self container] didChangeValueForKey:@"baselinePoints"];
}

- (BOOL)validateBaselinePoint:(NSDictionary **)aBaselinePoint error:(NSError **)outError {
    // Implement validation here...
    return YES;
} // end baselinePoints


#pragma mark -

#pragma mark Convenience methods

-(float)maxTime {
    return pk_stats_float_max(time, numberOfPoints);
}

-(float)minTime {
    return pk_stats_float_min(time, numberOfPoints);
}

-(float)maxTotalIntensity {
    return pk_stats_float_max(totalIntensity, numberOfPoints);
}

-(float)minTotalIntensity {
    return pk_stats_float_min(totalIntensity, numberOfPoints);
}


@synthesize numberOfPoints;
@synthesize time;
@synthesize totalIntensity;
@synthesize baselinePoints;

@end

