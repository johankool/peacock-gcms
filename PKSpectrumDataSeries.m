//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "PKSpectrumDataSeries.h"

#import "PKSpectrum.h"
#import "PKComparableProtocol.h"


static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
static void *PropertyObservationContext = (void *)1093;

@implementation PKSpectrumDataSeries

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

- (id)initWithSpectrum:(NSObject <PKComparableProtocol>*)aSpectrum {
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
        // set in superclass
		[self setSeriesTitle:[aSpectrum legendEntry]];
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
    [self setSeriesTitle:nil];
    [self setKeyForXValue:nil];
    [self setKeyForYValue:nil];
    [self setKeyForXValue:nil];
    [self setKeyForYValue:nil];
    [self setSeriesColor:nil];
    
    [spectrum release];
    [super dealloc];
}

#pragma mark DRAWING ROUTINES
- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view {
    _graphView = view;
    
    if (!isVisible) {
        return;
    }
    
	NSBezierPath *bezierpath;
	if (_needsReconstructingPlotPath) {
		[self constructPlotPath];
	}
	// Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
	bezierpath = [trans transformBezierPath:[self plotPath]];
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
    [bezierpath setLineWidth:[self.lineThickness floatValue]];
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
        [self setPlotPath:bezierpath];
        [bezierpath release];
		return;
	}
	if (count == 1) {
        PKLogWarning(@"Plotting a one point spectrum");
		//return;
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

- (void)drawLabelsWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view{
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
    if ([self plotPath]) {
        return [[self plotPath] bounds];
    } else {
        return NSZeroRect;
    }
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

- (PKSpectrum *)spectrum {
    return spectrum;
}

- (void)setSpectrum:(PKSpectrum *)aSpectrum {
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
