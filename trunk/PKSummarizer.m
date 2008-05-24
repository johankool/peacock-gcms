//
//  JKSummarizer.m
//  Peacock
//
//  Created by Johan Kool on 28-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKSummarizer.h"

#import "PKPeakRecord.h"
#import "PKCombinedPeak.h"
#import "PKRatio.h"
#import "PKDocumentController.h"

@implementation PKSummarizer
- (id) init
{
    self = [super init];
    if (self != nil) {
        combinedPeaks = [[NSMutableArray alloc] init];
        ratios = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConfirmPeak:) name:@"JKDidConfirmPeak" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnconfirmPeak:) name:@"JKDidUnconfirmPeak" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];
//        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupRatios) name:NSUserDefaultsDidChangeNotification object:nil];
		[self setupRatios];
    }
    return self;
}

- (void)setupRatios
{
    [ratios removeAllObjects];
 	NSArray *prefRatios = [[NSUserDefaults standardUserDefaults] valueForKey:@"ratios"];
    NSString *ratioType;
    int tag = [[[NSUserDefaults standardUserDefaults] valueForKey:@"ratiosValueType"] intValue];
    switch (tag) {
        case 0:
            ratioType = @"surface";
            break;
        case 1:
            ratioType = @"normalizedSurface";
            break;
        case 2:
            ratioType = @"normalizedSurface2";
            break;
        case 3:
            ratioType = @"height";
            break;
        default:
            break;
    }
    if (prefRatios) {
        NSDictionary *aRatio;
        
        for (aRatio in prefRatios) {
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[ratios count]];
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"ratios"];
            PKRatio *newRatio = [[PKRatio alloc] initWithString:@""];
            [newRatio setFormula:[aRatio valueForKey:@"formula"]];
            [newRatio setName:[aRatio valueForKey:@"label"]];
            [newRatio setValueType:ratioType];
            [ratios addObject:newRatio];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"ratios"];
        }
    }
 }

- (void)didConfirmPeak:(NSNotification *)aNotification
{
    PKPeakRecord *peak = [aNotification object];
    PKCombinedPeak *combinedPeak = [self combinedPeakForPeak:peak];
    if (!combinedPeak) {
        combinedPeak = [[PKCombinedPeak alloc] init];
        NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[combinedPeaks count]];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"combinedPeaks"];
        [combinedPeaks addObject:combinedPeak];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"combinedPeaks"];
        [combinedPeak release];
    }
    [combinedPeak addConfirmedPeak:peak];
}

- (void)didUnconfirmPeak:(NSNotification *)aNotification
{
    PKPeakRecord *peak = [aNotification object];
    PKCombinedPeak *combinedPeak = [self combinedPeakForPeak:peak];
    [combinedPeak removeUnconfirmedPeak:peak];
    if ([combinedPeak countOfPeaks] == 0) {
        if ([combinedPeaks indexOfObject:combinedPeak] != NSNotFound) {
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[combinedPeaks indexOfObject:combinedPeak]];
            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"combinedPeaks"];
            [combinedPeaks removeObject:combinedPeak];
            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"combinedPeaks"];            
        }
   }
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    PKGCMSDocument *document = [aNotification object];
  	for (PKPeakRecord *peak in [document peaks]) {
        if ([peak confirmed]) {
            PKCombinedPeak *combinedPeak = [self combinedPeakForPeak:peak];
            if (!combinedPeak) {
                combinedPeak = [[PKCombinedPeak alloc] init];
                NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[combinedPeaks count]];
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"combinedPeaks"];
                [combinedPeaks addObject:combinedPeak];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"combinedPeaks"];
                [combinedPeak release];
            }
            [combinedPeak addConfirmedPeak:peak];
        }
    }
}

- (void)documentUnloaded:(NSNotification *)aNotification
{
    NSString *key = [[aNotification object] uuid];
    PKCombinedPeak *combinedPeak;
    NSMutableArray *objectsToRemove = [NSMutableArray array];
    for (combinedPeak in combinedPeaks) {
        [combinedPeak setValue:nil forKey:key];
        if ([combinedPeak countOfPeaks] == 0) {
            [objectsToRemove addObject:combinedPeak];
//            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[combinedPeaks indexOfObject:combinedPeak]];
//            [self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"combinedPeaks"];
//            [combinedPeaks removeObject:combinedPeak];
//            [self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"combinedPeaks"];            
        }        
    }
   [self willChangeValueForKey:@"combinedPeaks"];
    [combinedPeaks removeObjectsInArray:objectsToRemove];
    [self didChangeValueForKey:@"combinedPeaks"];
}


- (PKCombinedPeak *)combinedPeakForPeak:(PKPeakRecord *)peak
{
    PKCombinedPeak *combinedPeak;
    
    // Check using library hit
    for (combinedPeak in [self combinedPeaks]) {
        if ([combinedPeak isCombinedPeakForPeak:peak]) {
            return combinedPeak;
        }       
    }   
    
    // Check using peak label
    for (combinedPeak in [self combinedPeaks]) {
        if ([combinedPeak isCompound:[peak label]]) {
            return combinedPeak;
        }       
    }    
    
    return nil;
}

- (NSMutableArray *)combinedPeaks {
	return combinedPeaks;
}

- (void)setCombinedPeaks:(NSMutableArray *)inValue {
    [inValue retain];
    [combinedPeaks release];
    combinedPeaks = inValue;
}

- (NSMutableArray *)ratios {
	return ratios;
}

- (void)setRatios:(NSMutableArray *)inValue {
    [inValue retain];
    [ratios release];
    ratios = inValue;
}

- (void)setUniqueSymbols 
{
    BOOL groupSymbols = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"groupSymbols"] intValue];
    int j;
    int compoundCount;
    NSNumber *countForGroup;
    PKCombinedPeak *compound;
    NSMutableDictionary *uniqueDict = [NSMutableDictionary dictionary];
    NSMutableArray *uniqueSymbolArray = [NSMutableArray array];
//    NSMutableArray *peaks = [[statisticsWindowController combinedPeaks] mutableCopy];
    
    // Reset all peaks
    [[[PKDocumentController sharedDocumentController] managedDocuments] makeObjectsPerformSelector:@selector(resetSymbols)];
    
    // Sort array on retention index
    NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
                                                                            ascending:YES];
    NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
    NSArray *sortedCombinedPeaks = [[self combinedPeaks] sortedArrayUsingDescriptors:sortDescriptors];
    [retentionIndexDescriptor release];
    
    compoundCount = [sortedCombinedPeaks count];
    
    if (groupSymbols) {
        // Compound symbol
        for (j=0; j < compoundCount; j++) {
            compound = [sortedCombinedPeaks objectAtIndex:j];
            // ensure symbol is set
            if (([[compound libraryEntry] symbol]) && (![[[compound libraryEntry] symbol] isEqualToString:@""]) && ([uniqueSymbolArray indexOfObjectIdenticalTo:[[compound libraryEntry] symbol]] == NSNotFound)) {
                [compound setSymbol:[[compound libraryEntry] symbol]];
                [uniqueSymbolArray addObject:[[compound libraryEntry] symbol]];
                continue;
            }
            if (![compound group] || [[compound group] isEqualToString:@""]) {
                [compound setGroup:@"X"];
            }
            
            // replace odd characters
            // ensure symbol starts with letter
            //        if ([[compound group] rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == 0) {
            //            NSString *newGroup = [NSString stringWithFormat:@"X%@", [compound group]];
            //            [compound setGroup:newGroup];
            //        }
            // get countForSymbol 
            countForGroup = [uniqueDict valueForKey:[compound group]];
            if (!countForGroup) {
                countForGroup = [NSNumber numberWithInt:1];
            } else if (countForGroup) {
                countForGroup = [NSNumber numberWithInt:[countForGroup intValue]+1];
            }
            [uniqueDict setValue:countForGroup forKey:[compound group]];
            if ([[[compound group] substringFromIndex:[[compound group] length]-1] rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].length == 1) { // group ends with a number
                if ([countForGroup intValue] == 1) {
                    [compound setSymbol:[NSString stringWithFormat:@"%@", [compound group]]];              
                } else {
                    [compound setSymbol:[NSString stringWithFormat:@"%@-%d", [compound group], [countForGroup intValue]]];            
                }
            } else {
                // must be unique (note that a few cases are missed here, e.g. when a group is named X (and gets count 11 and another X1 and gets count 1)
                [compound setSymbol:[NSString stringWithFormat:@"%@%d", [compound group], [countForGroup intValue]]];            
            }
            [uniqueSymbolArray addObject:[compound symbol]];
        }
        
    } else {
        // Compound symbol
        for (j=0; j < compoundCount; j++) {
            compound = [sortedCombinedPeaks objectAtIndex:j];
            [compound setSymbol:[NSString stringWithFormat:@"%d", j+1]];            
        }
    }
    
    
}

@end
