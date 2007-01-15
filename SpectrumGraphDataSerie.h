//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

@class JKSpectrum;

@interface SpectrumGraphDataSerie : MyGraphDataSerie {
	NSRect boundingRect;
	BOOL drawUpsideDown;
	BOOL normalizeYData;
}

- (id)initWithSpectrum:(JKSpectrum *)spectrum;

#pragma mark ACCESSORS
- (BOOL)drawUpsideDown;
- (void)setDrawUpsideDown:(BOOL)inValue;
- (BOOL)normalizeYData;
- (void)setNormalizeYData:(BOOL)inValue;
@end
