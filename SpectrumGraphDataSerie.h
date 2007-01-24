//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

@class JKSpectrum;

@interface SpectrumGraphDataSerie : MyGraphDataSerie {
    JKSpectrum *spectrum;
	BOOL drawUpsideDown;
	BOOL normalizeYData;

    @private
	NSRect _boundingRect;
}

- (id)initWithSpectrum:(JKSpectrum *)spectrum;

#pragma mark ACCESSORS
- (JKSpectrum *)spectrum;
- (void)setSpectrum:(JKSpectrum *)aSpectrum;
- (BOOL)drawUpsideDown;
- (void)setDrawUpsideDown:(BOOL)inValue;
- (BOOL)normalizeYData;
- (void)setNormalizeYData:(BOOL)inValue;
@end
