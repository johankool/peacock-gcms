//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGraphDataSeries.h"

#import "PKComparableProtocol.h"

@class PKSpectrum;

@interface PKSpectrumDataSeries : PKGraphDataSeries {
    PKSpectrum *spectrum;
	BOOL drawUpsideDown;
	BOOL normalizeYData;

    @private
	NSRect _boundingRect;
}

- (id)initWithSpectrum:(NSObject <PKComparableProtocol>*)aSpectrum;

#pragma mark ACCESSORS
- (PKSpectrum *)spectrum;
- (void)setSpectrum:(PKSpectrum *)aSpectrum;
- (BOOL)drawUpsideDown;
- (void)setDrawUpsideDown:(BOOL)inValue;
- (BOOL)normalizeYData;
- (void)setNormalizeYData:(BOOL)inValue;
@property (getter=drawUpsideDown,setter=setDrawUpsideDown:) BOOL drawUpsideDown;
@property (getter=normalizeYData,setter=setNormalizeYData:) BOOL normalizeYData;
@end
