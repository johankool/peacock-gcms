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

@implementation JKSummarizer
- (id) init
{
    self = [super init];
    if (self != nil) {
        summary = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didConfirmPeak:) name:@"JKDidConfirmPeak" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUnconfirmPeak:) name:@"JKDidUnconfirmPeak" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentLoaded:) name:@"JKGCMSDocument_DocumentLoadedNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUnloaded:) name:@"JKGCMSDocument_DocumentUnloadedNotification" object:nil];

    }
    return self;
}

- (void)didConfirmPeak:(NSNotification *)aNotification
{
    JKPeakRecord *peak = [aNotification object];
    JKCombinedPeak *combinedPeak = [self combinedPeakForLabel:[peak label]];
    if (!combinedPeak) {
        combinedPeak = [[JKCombinedPeak alloc] init];
        [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[summary count]] forKey:@"summary"];
        [summary addObject:combinedPeak];
        [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[summary count]-1] forKey:@"summary"];
        [combinedPeak release];
    }
    [combinedPeak addConfirmedPeak:peak];
}

- (void)didUnconfirmPeak:(NSNotification *)aNotification
{
    JKPeakRecord *peak = [aNotification object];
    JKCombinedPeak *combinedPeak = [self combinedPeakForLabel:[peak label]];
    [combinedPeak removeUnconfirmedPeak:peak];
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
                [self willChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[summary count]] forKey:@"summary"];
                [summary addObject:combinedPeak];
                [self didChange:NSKeyValueChangeInsertion valuesAtIndexes:[NSIndexSet indexSetWithIndex:[summary count]-1] forKey:@"summary"];
                [combinedPeak release];
            }
            [combinedPeak addConfirmedPeak:peak];
        }
    }
}

- (void)documentUnloaded:(NSNotification *)aNotification
{
    NSString *key = [[aNotification object] uuid];
    NSEnumerator *enumerator = [summary objectEnumerator];
    JKCombinedPeak *combinedPeak;
    
    while ((combinedPeak = [enumerator nextObject])) {
        [combinedPeak setValue:nil forKey:key];
    }
}


- (JKCombinedPeak *)combinedPeakForLabel:(NSString *)label
{
    JKCombinedPeak *combinedPeak;
    
    for (combinedPeak in summary) {
        if ([combinedPeak isIdenticalToCompound:label]) {
            return combinedPeak;
        }
    }
    return nil;
}

- (NSArray *)summary
{
    return summary;
}

@end
