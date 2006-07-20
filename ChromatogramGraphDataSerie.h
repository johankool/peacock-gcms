//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

@interface ChromatogramGraphDataSerie : MyGraphDataSerie {
	BOOL shouldDrawPeaks;
	
	NSArrayController *peaksContainer;
    NSString *peaksKeyPath;	
}

#pragma mark DRAWING ROUTINES
- (void)plotDataWithTransform:(NSAffineTransform *)trans;
- (void)drawLabelsWithTransform:(NSAffineTransform *)trans;
- (void)drawPeaksWithTransform:(NSAffineTransform *)trans;
- (void)constructPlotPath;

#pragma mark HELPER ROUTINES
- (NSRect)boundingRect;

#pragma mark KEY VALUE OBSERVING MANAGEMENT

#pragma mark MISC
- (NSArray *)dataArrayKeys;

#pragma mark BINDINGS
- (NSMutableArray *)peaks;
- (NSObject *)peaksContainer;
- (void)setPeaksContainer:(NSObject *)aPeaksContainer;
- (NSString *)peaksKeyPath;
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath;

#pragma mark ACCESSORS
- (BOOL)shouldDrawPeaks;
- (void)setShouldDrawPeaks:(BOOL)inValue;
@end
