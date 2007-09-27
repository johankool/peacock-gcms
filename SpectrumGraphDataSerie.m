//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "SpectrumGraphDataSerie.h"

#import "JKSpectrum.h"
#import "JKComparableProtocol.h"


static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
static void *PropertyObservationContext = (void *)1093;

@implementation SpectrumGraphDataSerie

#pragma mark INITIALIZATION
- (id)init {
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
		[self setSeriesTitle:NSLocalizedString(@"New Spectrum Serie",@"New spectrum serie")];
		[self setKeyForXValue:@"Mass"];
		[self setKeyForYValue:@"Intensity"];
		[self setSeriesColor:[NSColor blueColor]];
		[self setSeriesType:2];
		[self setShouldDrawLabels:YES];
		drawUpsideDown = NO;
		normalizeYData = NO;
		_boundingRect = NSZeroRect;
		
		_needsReconstructingPlotPath = YES;
	}
    return self;
}

- (id)initWithSpectrum:(NSObject <JKComparableProtocol>*)aSpectrum {
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
        // set in superclass
		[self setSeriesTitle:[aSpectrum model]];
		[self setKeyForXValue:@"Mass"];
		[self setKeyForYValue:@"Intensity"];
		[self setSeriesColor:[NSColor blueColor]];
		[self setSeriesType:2];
		[self setShouldDrawLabels:YES];
        
		drawUpsideDown = NO;
		normalizeYData = NO;
		_boundingRect = NSZeroRect;

        spectrum = [aSpectrum retain];
        [self setKeyForXValue:NSLocalizedString(@"Mass",@"")];
        [self setKeyForYValue:NSLocalizedString(@"Intensity",@"")];
        [self loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
        
        _needsReconstructingPlotPath = YES;
    }
    return self;
}

- (void)dealloc {
    [spectrum release];
    [super dealloc];
}

#pragma mark DRAWING ROUTINES
- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view {
    _graphView = view;
	NSBezierPath *bezierpath;
	if (_needsReconstructingPlotPath) {
		[self constructPlotPath];
	}
	// Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
	bezierpath = [trans transformBezierPath:[self plotPath]];
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[bezierpath setLineWidth:1.0];
	[[self seriesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[bezierpath stroke];
	
	if(shouldDrawLabels) {
		if (seriesType == 2) {
			[self drawLabelsWithTransform:trans inView:view];

		}
	}
}

- (void)constructPlotPath {
	int i, count;
	NSPoint pointInUnits, pointInUnits2;
	NSBezierPath *bezierpath = [[NSBezierPath alloc] init];
	
	count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}

	float maxYValue = 0.0;
	if (normalizeYData) {
		for (i=0; i<count; i++) {
			if (maxYValue < [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]) {
				maxYValue = [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue];
			}
		}		
	} else {
		maxYValue = 1.0;
	}
	
	// Spectrum
	// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
	for (i=0; i<count; i++) {
		pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], 0.0);
		if (drawUpsideDown) {
			pointInUnits2 = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], -[[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]/maxYValue);
		} else {
			pointInUnits2 = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]/maxYValue);
		}
		[bezierpath moveToPoint:pointInUnits];
		[bezierpath lineToPoint:pointInUnits2];
	}
			
	
	[self setPlotPath:bezierpath];
	_boundingRect = [bezierpath bounds];
	
	// Stuur een bericht naar de view dat deze serie opnieuw getekend wil worden.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphDataSerieDidChangeNotification" object:self];
	[bezierpath release];
    _needsReconstructingPlotPath = NO;
}

- (void)drawLabelsWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view{
    _graphView = view;
    BOOL belowZero;
	int count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}
				
	NSMutableAttributedString *string;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	int i,j;
	BOOL drawLabel;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%.f";
	NSRect labelRect;
	
	int rectCount = [[self dataArray] count];

	NSRectArray rects;
	rects = (NSRectArray) calloc(rectCount, sizeof(NSRect));
	 
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	float maxYValue = 0.0;
	if (normalizeYData) {
		for (i=0; i<count; i++) {
			if (maxYValue < [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]) {
				maxYValue = [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue];
			}
		}		
	} else {
		maxYValue = 1.0;
	}
	
	// We should go through the values from highest intensity ('y') to lowest instead of along the x-axis.
	// It is more important to label the higher intensities.
	for (i=0; i<count; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, [[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue]] attributes:attrs];
		
		if (drawUpsideDown) {
			pointToDraw = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], -[[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]/maxYValue);
		} else {
			pointToDraw = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]/maxYValue);
		}
        if (pointToDraw.y < 0.0 ) {
            belowZero = YES;
        } else {
            belowZero = NO;
        }
		stringSize = [string size];
		pointToDraw = [trans transformPoint:pointToDraw]; // Transfrom to screen coords
		pointToDraw.x = pointToDraw.x - stringSize.width/2; // Center the label
		// Draw above or below depending on wether we have negative values
		if (belowZero) {
			pointToDraw.y = pointToDraw.y - stringSize.height - 4;
		} else {
			pointToDraw.y = pointToDraw.y + 4;
		}		
		
		labelRect = NSMakeRect(pointToDraw.x,pointToDraw.y,stringSize.width,stringSize.height); // The rect for the label to draw
		
		// Only draw label if it doesn't run over another one
		drawLabel = YES;
		for (j = 0; j < rectCount; j++) {
			if (NSIntersectsRect(labelRect,rects[j])) {
				drawLabel = NO;
			}
		}
		if (drawLabel) {
			[string drawAtPoint:pointToDraw];
			rects[i] = labelRect;		
//			labelRect.size = [ transformSize:stringSize];
//			_boundingRect = NSUnionRect(_boundingRect,labelRect);
		} else {
			// Try to see if we can draw the label if we move it to the left and up
			
			// Try to see if we can draw the label if we move it to the right and up
			
		}
		[string release];
	}
	free(rects);
}

//#pragma mark MISC
//- (NSArray *)dataArrayKeys {
//    return [NSArray arrayWithObjects:NSLocalizedString(@"Mass", @""), NSLocalizedString(@"Intensity", @""), nil];
//}

#pragma mark HELPER ROUTINES
- (void)transposeAxes {
	// Deze routine wisselt de x-as met de y-as om
	NSString *tempString = [self keyForXValue];
	[self setKeyForXValue:[self keyForYValue]];
	[self setKeyForYValue:tempString];
	_needsReconstructingPlotPath = YES;
}

- (NSRect)boundingRect {
    return [[self plotPath] bounds];
	return _boundingRect;
}

#pragma mark KEY VALUE OBSERVING MANAGEMENT

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
    if (context == ArrayObservationContext)
	{
		//		NSArray *newData = [self dataArray];
		////		NSMutableArray *onlyNew = [newData mutableCopy];
		////		[onlyNew removeObjectsInArray:oldData];
		////		[self startObservingData:onlyNew];
		////		[onlyNew release];
		////		
		////		NSMutableArray *removed = [oldData mutableCopy];
		////		[removed removeObjectsInArray:newData];
		////		[self stopObservingData:removed];
		////		[removed release];
		//		
		//		// Slordig, kan veel slimmer, maar dit is veel sneller dan wat hierboven staat!
		//		[self stopObservingData:oldData];
		//		[self startObservingData:newData];
		//		
		//		[self setOldData:newData];
		
		_needsReconstructingPlotPath = YES;
		return;
    }
	
	if (context == DictionaryObservationContext)
	{		
		// We hoeven de plot alleen opnieuw te tekenen als de waarde voor de x of de y key veranderde.
		if ([keyPath isEqualToString:[self keyForXValue]] || [keyPath isEqualToString:[self keyForYValue]]) {
			_needsReconstructingPlotPath = YES;
			return;
		} 
		return;
	}
	if (context == PropertyObservationContext)
	{		
		// Een verandering in kleur of titel vereist niet het opnieuw samenstellen van de plotpath.
		if ([keyPath isEqualTo:@"seriesColor"] || [keyPath isEqualTo:@"seriesTitle"]) {
			// Stuur een bericht naar de view dat deze serie opnieuw getekend wil worden.
			[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphDataSerieDidChangeNotification" object:self];
			return;
		}
		_needsReconstructingPlotPath = YES;
		return;
	}
}

- (JKSpectrum *)spectrum {
    return spectrum;
}

- (void)setSpectrum:(JKSpectrum *)aSpectrum {
    if (aSpectrum != spectrum) {
        [aSpectrum retain];
        [spectrum autorelease];
        spectrum = aSpectrum;     
        [self setKeyForXValue:NSLocalizedString(@"Mass",@"")];
        [self setKeyForYValue:NSLocalizedString(@"Intensity",@"")];
        [self loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
    }    
}

- (BOOL)drawUpsideDown {
	return drawUpsideDown;
}
- (void)setDrawUpsideDown:(BOOL)inValue {
    drawUpsideDown = inValue;
	_needsReconstructingPlotPath = YES;
    [_graphView setNeedsDisplay:YES];
}
- (BOOL)normalizeYData{
	return normalizeYData;
}

- (void)setNormalizeYData:(BOOL)inValue{
	normalizeYData = inValue;
	_needsReconstructingPlotPath = YES;
    [_graphView setNeedsDisplay:YES];
}


@end
