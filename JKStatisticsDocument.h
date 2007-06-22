//
//  JKStatisticsDocument.h
//  Peacock
//
//  Created by Johan Kool on 19-3-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKStatisticsWindowController;
@class JKStatisticsPrintView;

@interface JKStatisticsDocument : NSDocument {
    JKStatisticsWindowController *statisticsWindowController;
    NSDictionary *_documentProxy;
    NSArray *loadingsDataSeries;
    NSArray *scoresDataSeries;
    int numberOfFactors;
    
    JKStatisticsPrintView *printView;
}

- (JKStatisticsWindowController *)statisticsWindowController;

- (NSArray *)loadingsDataSeries;
- (void)setLoadingsDataSeries:(NSArray *)loadingsDataSeries;
- (NSArray *)scoresDataSeries;
- (void)setScoresDataSeries:(NSArray *)aScoresDataSeries;
- (int)numberOfFactors;
- (void)setNumberOfFactors:(int)numberOfFactors;
- (void)setUniqueSymbols;
- (BOOL)performFactorAnalysis;
@end
