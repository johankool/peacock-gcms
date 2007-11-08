//
//  JKSummarizer.m
//  Peacock
//
//  Created by Johan Kool on 28-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKSummarizer.h"

#import "JKPeakRecord.h"
#import "JKCombinedPeak.h"
#import "JKRatio.h"
#import "PKDocumentController.h"

@implementation JKSummarizer
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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupRatios) name:NSUserDefaultsDidChangeNotification object:nil];
		[self setupRatios];
    }
    return self;
}

- (void)setupRatios
{
    [ratios removeAllObjects];
 	NSArray *prefRatios = [[NSUserDefaults standardUserDefaults] valueForKey:@"ratios"];
    if (prefRatios) {
        NSDictionary *aRatio;
        
        for (aRatio in prefRatios) {
            NSIndexSet *indexes = [NSIndexSet indexSetWithIndex:[ratios count]];
            [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"ratios"];
            JKRatio *newRatio = [[JKRatio alloc] initWithString:@""];
            [newRatio setFormula:[aRatio valueForKey:@"formula"]];
            [newRatio setName:[aRatio valueForKey:@"label"]];
            [ratios addObject:newRatio];
            [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:indexes forKey:@"ratios"];
        }
    }
 }

- (void)didConfirmPeak:(NSNotification *)aNotification
{
    JKPeakRecord *peak = [aNotification object];
    JKCombinedPeak *combinedPeak = [self combinedPeakForLabel:[peak label]];
    if (!combinedPeak) {
        combinedPeak = [[JKCombinedPeak alloc] init];
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
    JKPeakRecord *peak = [aNotification object];
    JKCombinedPeak *combinedPeak = [self combinedPeakForLabel:[peak label]];
    [combinedPeak removeUnconfirmedPeak:peak];
//    if ([combinedPeak countOfPeaks] == 0) {
//        [combinedPeaks removeObject:combinedPeak];
//    }
}

- (void)documentLoaded:(NSNotification *)aNotification
{
    JKGCMSDocument *document = [aNotification object];
    NSEnumerator *enumerator = [[document peaks] objectEnumerator];
    JKPeakRecord *peak;

    while ((peak = [enumerator nextObject])) {
        if ([peak confirmed]) {
            JKCombinedPeak *combinedPeak = [self combinedPeakForLabel:[peak label]];
            if (!combinedPeak) {
                combinedPeak = [[JKCombinedPeak alloc] init];
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
    JKCombinedPeak *combinedPeak;
    
    for (combinedPeak in combinedPeaks) {
        [combinedPeak setValue:nil forKey:key];
//        if ([combinedPeak countOfPeaks] == 0) {
//            [combinedPeaks removeObject:combinedPeak];
//        }        
    }
}


- (JKCombinedPeak *)combinedPeakForLabel:(NSString *)label
{
    JKCombinedPeak *combinedPeak;
    
    for (combinedPeak in combinedPeaks) {
        if ([combinedPeak isIdenticalToCompound:label]) {
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
    JKCombinedPeak *compound;
    NSMutableDictionary *uniqueDict = [NSMutableDictionary dictionary];
    NSMutableArray *uniqueSymbolArray = [NSMutableArray array];
//    NSMutableArray *peaks = [[statisticsWindowController combinedPeaks] mutableCopy];
    
    // Reset all peaks
    [[[PKDocumentController sharedDocumentController] managedDocuments] makeObjectsPerformSelector:@selector(resetSymbols)];
    
    // Sort array on retention index
    NSSortDescriptor *retentionIndexDescriptor =[[NSSortDescriptor alloc] initWithKey:@"averageRetentionIndex" 
                                                                            ascending:YES];
    NSArray *sortDescriptors=[NSArray arrayWithObjects:retentionIndexDescriptor,nil];
    [[self combinedPeaks] sortUsingDescriptors:sortDescriptors];
    [retentionIndexDescriptor release];
    
    compoundCount = [combinedPeaks count];
    
    if (groupSymbols) {
        // Compound symbol
        for (j=0; j < compoundCount; j++) {
            compound = [combinedPeaks objectAtIndex:j];
            // ensure symbol is set
            if (![compound group] || [[compound group] isEqualToString:@""]) {
                [compound setGroup:@"X"];
            }
//            if (([compound symbol]) && (![[compound symbol] isEqualToString:@""]) && ([uniqueSymbolArray indexOfObjectIdenticalTo:[compound symbol]] == NSNotFound)) {
//                [compound setSymbol:[compound symbol]];
//                [uniqueSymbolArray addObject:[compound symbol]];
//                continue;
//            }
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
            compound = [combinedPeaks objectAtIndex:j];
            [compound setSymbol:[NSString stringWithFormat:@"%d", j+1]];            
        }
    }
    
    
}

@end
