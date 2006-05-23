//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

@interface SpectrumGraphDataSerie : MyGraphDataSerie {
	NSRect boundingRect;
	BOOL drawUpsideDown;
	BOOL normalizeYData;
}

#pragma mark DRAWING ROUTINES
- (void)plotDataWithTransform:(NSAffineTransform *)trans;
- (void)drawLabelsWithTransform:(NSAffineTransform *)trans;
- (void)constructPlotPath;

#pragma mark HELPER ROUTINES
- (void)transposeAxes;
- (NSRect)boundingRect;

#pragma mark KEY VALUE OBSERVING MANAGEMENT
- (void)startObservingData:(NSArray *)data;
- (void)stopObservingData:(NSArray *)data;

#pragma mark MISC
- (NSArray *)dataArrayKeys;

#pragma mark ACCESSORS
- (BOOL)drawUpsideDown;
- (void)setDrawUpsideDown:(BOOL)inValue;
- (BOOL)normalizeYData;
- (void)setNormalizeYData:(BOOL)inValue;
@end
