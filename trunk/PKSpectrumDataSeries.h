//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGraphDataSeries.h"

#import "JKComparableProtocol.h"

@class JKSpectrum;

@interface PKSpectrumDataSeries : PKGraphDataSeries {
    JKSpectrum *spectrum;
	BOOL drawUpsideDown;
	BOOL normalizeYData;

    @private
	NSRect _boundingRect;
}

- (id)initWithSpectrum:(NSObject <JKComparableProtocol>*)aSpectrum;

#pragma mark ACCESSORS
- (JKSpectrum *)spectrum;
- (void)setSpectrum:(JKSpectrum *)aSpectrum;
- (BOOL)drawUpsideDown;
- (void)setDrawUpsideDown:(BOOL)inValue;
- (BOOL)normalizeYData;
- (void)setNormalizeYData:(BOOL)inValue;
@property (getter=drawUpsideDown,setter=setDrawUpsideDown:) BOOL drawUpsideDown;
@property (getter=normalizeYData,setter=setNormalizeYData:) BOOL normalizeYData;
@end
