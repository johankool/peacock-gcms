//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "ChromatogramGraphDataSerie.h"
#import "JKChromatogram.h"
#import "MyGraphView.h"
#import "JKPeakRecord.h"

static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
static void *PropertyObservationContext = (void *)1093;

@implementation ChromatogramGraphDataSerie

#pragma mark INITIALIZATION

- (id)init {
    return [self initWithChromatogram:nil];
}

- (id)initWithChromatogram:(JKChromatogram *)aChromatogram {
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
		[self setSeriesColor:[NSColor blueColor]];
		[self setSeriesType:1];
		[self setShouldDrawPeaks:YES];
		[self setShouldDrawLabels:YES];
        [self setVerticalScale:[NSNumber numberWithFloat:1.0]];
        [self setChromatogram:aChromatogram];
        [self setSeriesTitle:[aChromatogram model]];
		// Creeer de plot een eerste keer.
		[self constructPlotPath];
	}
    return self;
}

#pragma mark DRAWING ROUTINES
- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view{
    _graphView = view;
	NSBezierPath *bezierpath;
	
	if (!plotPath) [self constructPlotPath];
	
    if ((![[view keyForXValue] isEqualToString:keyForXValue]) | (![[view keyForYValue] isEqualToString:keyForYValue])) {
        [self setKeyForXValue:[view keyForXValue]];
        [self setKeyForYValue:[view keyForYValue]];
    }
    
	// Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
	bezierpath = [trans transformBezierPath:[self plotPath]];
	
	if(shouldDrawPeaks)
        [self drawPeaksWithTransform:trans inView:view];
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [bezierpath setLineWidth:1.0];        
    } else {
        [bezierpath setLineWidth:0.5];
    }
	[[view baselineColor] set];
    [[trans transformBezierPath:[self baselineBezierPath]] stroke];
    
	[[self seriesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[bezierpath stroke];
	
	if(shouldDrawLabels)
		[self drawLabelsWithTransform:trans inView:view];
}

- (void)constructPlotPath {
	int i, count;
	NSPoint pointInUnits;
	NSBezierPath *bezierpath = [[NSBezierPath alloc] init];
	
	count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}
	
	// Creeer het pad.
	[bezierpath moveToPoint:NSMakePoint([[[[self dataArray] objectAtIndex:0] valueForKey:keyForXValue] floatValue],
										[[[[self dataArray] objectAtIndex:0] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue])];
	
	// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
	for (i=1; i<count; i++) {
		pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue],
								   [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
		[bezierpath lineToPoint:pointInUnits];
	}

	[self setPlotPath:bezierpath];
	
	[bezierpath release];
}

- (NSBezierPath *)baselineBezierPath {
	int i, count;
	NSPoint pointInUnits;
	NSBezierPath *bezierpath = [[[NSBezierPath alloc] init] autorelease];
	
	count = [[[self chromatogram] baselinePoints] count];
	if (count <= 0) {	
		return bezierpath;
	}
	
	// Creeer het pad.
	[bezierpath moveToPoint:NSMakePoint([[[[[self chromatogram] baselinePoints] objectAtIndex:0] valueForKey:keyForXValue] floatValue],
										[[[[[self chromatogram] baselinePoints] objectAtIndex:0] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue])];
	
	// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
	for (i=1; i<count; i++) {
		pointInUnits = NSMakePoint([[[[[self chromatogram] baselinePoints] objectAtIndex:i] valueForKey:keyForXValue] floatValue],
								   [[[[[self chromatogram] baselinePoints] objectAtIndex:i] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
		[bezierpath lineToPoint:pointInUnits];
	}
 // 	NSLog([bezierpath description]);
	return bezierpath;
}

- (void)drawPeaksWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view{
    _graphView = view;
	int i, count;

	// Get peaks count
	count = [[self peaks] count];

	if (count <= 0)
		return;
	
	// Get colorlist
	NSColorList *peakColors;
	NSArray *peakColorsArray;
	
	peakColors = [NSColorList colorListNamed:@"Peacock"];
	if (peakColors == nil) {
		peakColors = [NSColorList colorListNamed:@"Crayons"]; // Crayons should always be there, as it can't be removed through the GUI
	}
	peakColorsArray = [peakColors allKeys];
	int peakColorsArrayCount = [peakColorsArray count];
	
	// Reset tooltips
	//[self removeAllToolTips];

	// Draw unselected peaks (all peaks actually)
	NSBezierPath *peaksPath = [[NSBezierPath alloc] init];
	NSPoint pointToDrawFirst, pointToDrawLast, pointInUnits;
	int j, start, end, top;
    if(shouldDrawPeaks) {
        for (i=0; i < count; i++) {
            [peaksPath removeAllPoints];
            
            pointToDrawFirst = NSMakePoint([[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[[self peaks] objectAtIndex:i] start]] valueForKey:keyForXValue] floatValue],
                                               [[[[self peaks] objectAtIndex:i] valueForKey:@"baselineLeft"] floatValue]*[verticalScale floatValue]); 
            pointToDrawFirst = [trans transformPoint:pointToDrawFirst];
            
            [peaksPath moveToPoint:pointToDrawFirst];
            
            // fori over data points
            start = [(JKPeakRecord *)[[self peaks] objectAtIndex:i] start];
            end   = [(JKPeakRecord *)[[self peaks] objectAtIndex:i] end]+1;
            for (j=start; j < end; j++) {
                pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:j] valueForKey:keyForXValue] floatValue],
                                           [[[[self dataArray] objectAtIndex:j] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
                pointInUnits  = [trans transformPoint:pointInUnits];
                [peaksPath lineToPoint:pointInUnits];
            }
            
            pointToDrawLast  = NSMakePoint([[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[[self peaks] objectAtIndex:i] end]] valueForKey:keyForXValue] floatValue],
                                           [[[[self peaks] objectAtIndex:i] valueForKey:@"baselineRight"] floatValue]*[verticalScale floatValue]);
            pointToDrawLast  = [trans transformPoint:pointToDrawLast];
                
                [peaksPath lineToPoint:pointToDrawLast];
                [peaksPath lineToPoint:pointToDrawFirst]; // Close area
                
                // Add tooltip (plottingArea not available -> disabled for now)
                //[self addToolTipRect:NSMakeRect(pointToDraw1.x,plottingArea.origin.y,pointToDraw2.x-pointToDraw1.x,plottingArea.size.height) owner:self userData:i];
                
                // Set color
                [[peakColors colorWithKey:[peakColorsArray objectAtIndex:i%peakColorsArrayCount]] set];
                
                // Draw
                [peaksPath fill];
        }
    }

	// Draw seleced peak!
	NSMutableArray *selectedPeaks = [NSMutableArray array];
    NSEnumerator *enumerator = [[self peaks] objectEnumerator];
    JKPeakRecord *aPeak;

    while ((aPeak = [enumerator nextObject]) != nil) {
    	if ([[[view peaksContainer] selectedObjects] containsObject:aPeak]) {
            [selectedPeaks addObject:aPeak];
        } 
    }
	count = [selectedPeaks count];
	NSBezierPath *arrowPath = [[NSBezierPath alloc] init];
	
	for (i=0; i < count; i++) {
		[peaksPath removeAllPoints];
		
		pointToDrawFirst = NSMakePoint([[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[selectedPeaks objectAtIndex:i] start]] valueForKey:keyForXValue] floatValue],
									   [[[selectedPeaks objectAtIndex:i] valueForKey:@"baselineLeft"] floatValue]*[verticalScale floatValue]);
		pointToDrawFirst = [trans transformPoint:pointToDrawFirst];
		
		[peaksPath moveToPoint:pointToDrawFirst];
		
		// fori over data points
		start = [(JKPeakRecord *)[selectedPeaks objectAtIndex:i] start];
		end   = [(JKPeakRecord *)[selectedPeaks objectAtIndex:i] end]+1;
		for (j=start; j < end; j++) {
			pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:j] valueForKey:keyForXValue] floatValue],
									   [[[[self dataArray] objectAtIndex:j] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
			pointInUnits  = [trans transformPoint:pointInUnits];
			[peaksPath lineToPoint:pointInUnits];
		}
		
		pointToDrawLast  = NSMakePoint([[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[selectedPeaks objectAtIndex:i] end]] valueForKey:keyForXValue] floatValue],
									   [[[selectedPeaks objectAtIndex:i] valueForKey:@"baselineRight"] floatValue]*[verticalScale floatValue]);
        pointToDrawLast  = [trans transformPoint:pointToDrawLast];
			
			[peaksPath lineToPoint:pointToDrawLast];
			[peaksPath lineToPoint:pointToDrawFirst]; // Close area
			
			// Add tooltip (plottingArea not available -> disabled for now)
			//[self addToolTipRect:NSMakeRect(pointToDraw1.x,plottingArea.origin.y,pointToDraw2.x-pointToDraw1.x,plottingArea.size.height) owner:self userData:i];
			
			// Set color
            if ([[view window] firstResponder] == view) {
                [[NSColor selectedControlColor] set];
            } else {
                [[NSColor secondarySelectedControlColor] set];
            }
//			[[NSColor selectedControlColor] set];
			
			// Draw
			[peaksPath fill];
			
			// Draw an arrow
            if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
                [arrowPath removeAllPoints];
                top = [(JKPeakRecord *)[selectedPeaks objectAtIndex:i] top];
                pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:top] valueForKey:keyForXValue] floatValue],
                                           [[[[self dataArray] objectAtIndex:top] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
                pointInUnits  = [trans transformPoint:pointInUnits];
                
                [arrowPath moveToPoint:pointInUnits];
                [arrowPath relativeMoveToPoint:NSMakePoint(0.0,18.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(-8.0,8.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(4.0,0.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(0.0,8.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(8.0,0.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(0.0,-8.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(4.0,0.0)];
                [arrowPath relativeLineToPoint:NSMakePoint(-8.0,-8.0)];
                if ([[view window] firstResponder] == view) {
                    [[NSColor alternateSelectedControlColor] setStroke];
                    [[[NSColor alternateSelectedControlColor] colorWithAlphaComponent:0.3] setFill];
                } else {
                    [[NSColor secondarySelectedControlColor] setStroke];
                    [[[NSColor secondarySelectedControlColor] colorWithAlphaComponent:0.9] setFill];
                }
                [arrowPath fill];
                [arrowPath stroke];			                
            }
	}
	
	[arrowPath release];
	[peaksPath release];
}

- (void)drawLabelsWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view{
    _graphView = view;
	int count = [[self peaks] count];
	if (count <= 0)		
		return;
	
	NSMutableAttributedString *string;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	int i,j;
	BOOL drawLabel, drawVertical, drawLabelAlways;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSRect labelRect;
	
	// Array that holds all rects for the labels to check for overlaps
	int rectCount = [[self peaks] count];
	NSRectArray rects;
	rects = (NSRectArray) calloc(rectCount, sizeof(NSRect));
	 
    if ([[NSGraphicsContext currentContext] isDrawingToScreen]) {
        [attrs setValue:[view labelFont] forKey:NSFontAttributeName];
//        [attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	} else {
        [attrs setValue:[view labelFont] forKey:NSFontAttributeName];
//        [attrs setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];        
    }
    
	for (i=0; i<count; i++) {
		if ([[[self peaks] objectAtIndex:i] valueForKeyPath:@"symbol"] && ![[[[self peaks] objectAtIndex:i] valueForKeyPath:@"symbol"] isEqualToString:@""] && [[[[self peaks] objectAtIndex:i] valueForKeyPath:@"identified"] boolValue]) {
			string = [[NSMutableAttributedString alloc] initWithString:[[[self peaks] objectAtIndex:i] valueForKey:@"symbol"] attributes:attrs];
			drawVertical = NO; drawLabelAlways = YES;
		} else if ([[[self peaks] objectAtIndex:i] valueForKeyPath:@"label"] && ![[[[self peaks] objectAtIndex:i] valueForKeyPath:@"label"] isEqualToString:@""]) {
			string = [[NSMutableAttributedString alloc] initWithString:[[[self peaks] objectAtIndex:i] valueForKey:@"label"] attributes:attrs];
			drawVertical = YES; drawLabelAlways = YES;
		} else {
			string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"#%d",[(JKPeakRecord *)[[self peaks] objectAtIndex:i] peakID]] attributes:attrs];
			drawVertical = YES; drawLabelAlways = NO;
		}
		
		// Where will it be drawn?
		pointToDraw = NSMakePoint([[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[[self peaks] objectAtIndex:i] top]] valueForKey:keyForXValue] floatValue], 
								  [[[[self dataArray] objectAtIndex:[(JKPeakRecord *)[[self peaks] objectAtIndex:i] top]] valueForKey:keyForYValue] floatValue]*[verticalScale floatValue]);
		stringSize = [string size];
		pointToDraw = [trans transformPoint:pointToDraw]; // Transfrom to screen coords
		
		// What rect is that?
		if (drawVertical) {
			labelRect = NSMakeRect(pointToDraw.x - stringSize.height/2,pointToDraw.y+4,stringSize.height,stringSize.width); // The rect for the label to draw
		} else {
			pointToDraw.x = pointToDraw.x - stringSize.width/2; // Center the label
			pointToDraw.y = pointToDraw.y + 4;
			labelRect = NSMakeRect(pointToDraw.x,pointToDraw.y,stringSize.width,stringSize.height); // The rect for the label to draw
		}
		
		// Debug
//		[[NSColor yellowColor] set];
//		NSRectFill(labelRect);

		// Only draw label if it doesn't run over another one, symbols we always draw
		drawLabel = YES;
		if (!drawLabelAlways) {
			for (j = 0; j < rectCount; j++) {
				if (NSIntersectsRect(labelRect,rects[j])) {
					drawLabel = NO;
				}
			}			
		}
		
		if (drawLabel) {
			if (drawVertical){
				[NSGraphicsContext saveGraphicsState];	
				NSAffineTransform *transform = [NSAffineTransform transform];
				[transform translateXBy:pointToDraw.x yBy:pointToDraw.y];
				[transform rotateByDegrees:90.0];
				[transform concat];
				// Some adjustments to get it to draw on the right place
				pointToDraw = NSZeroPoint;
				pointToDraw.y = - stringSize.height/2;
				pointToDraw.x = 4;
				[string drawAtPoint:pointToDraw];
				[NSGraphicsContext restoreGraphicsState];				
			} else {
				[string drawAtPoint:pointToDraw];
			}
			
			rects[i] = labelRect;	

		} else {
			// Try to see if we can draw the label if we move it to the left and up
			
			// Try to see if we can draw the label if we move it to the right and up
			
		}
		[string release];

	}
	
	free(rects);
}

// Additions for Peacock
//- (void)drawBaseline  
//{
//	int i, count, count2;
//	count2 = 0;
//	NSBezierPath *baselinePath = [[NSBezierPath alloc] init];
//	NSPoint pointToDraw;
//	NSMutableArray *baselinePoints;
//	NSArray *baselinePointsSelected = [NSArray array];
//	
//    baselinePoints = [self baseline];
//	count = [baselinePoints count];
//	if ([baselineContainer selectionIndexes]) {
//		baselinePointsSelected = [[self baseline] objectsAtIndexes:[baselineContainer selectionIndexes]];
//		count2 = [baselinePointsSelected count];
//	}
//	
//    // Draw inside the legendArea
//    [NSGraphicsContext saveGraphicsState];	
//	[[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
//	
//	// De baseline.
//    
//	if (count > 0) {
//		pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:0] valueForKey:keyForXValue] floatValue],[[[baselinePoints objectAtIndex:0] valueForKey:@"Total Intensity"] floatValue]);
//		[baselinePath moveToPoint:[[self transformGraphToScreen] transformPoint:pointToDraw]];  	
//		for (i=1;i<count; i++) {
//			pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:i] valueForKey:keyForXValue] floatValue],[[[baselinePoints objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
//			[baselinePath lineToPoint:[[self transformGraphToScreen] transformPoint:pointToDraw]];			
//		}
//	}
//    
//	if (count2 > 0) {
//		for (i=0;i<count2; i++) {
//			pointToDraw = NSMakePoint([[[baselinePointsSelected objectAtIndex:i] valueForKey:keyForXValue] floatValue],[[[baselinePointsSelected objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
//			pointToDraw = [[self transformGraphToScreen] transformPoint:pointToDraw];
//			[baselinePath appendBezierPathWithRect:NSMakeRect(pointToDraw.x-2.5,pointToDraw.y-2.5,5.0,5.0)];			
//		}
//	}
//	
//	// Hier stellen we in hoe de lijnen eruit moeten zien.
//	[baselinePath setLineWidth:1.0];
//	[[self baselineColor] set];
//	
//	// Met stroke wordt de bezierpath getekend.
//	[baselinePath stroke];
//	
//	[NSGraphicsContext restoreGraphicsState];
//	[baselinePath release];
//}
//

#pragma mark HELPER ROUTINES
- (NSRect)boundingRect {
	return [[self plotPath] bounds];
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
		
		[self constructPlotPath];
		return;
    }
	
	if (context == DictionaryObservationContext)
	{		
		// We hoeven de plot alleen opnieuw te tekenen als de waarde voor de x of de y key veranderde.
		if ([keyPath isEqualToString:[self keyForXValue]] || [keyPath isEqualToString:[self keyForYValue]]) {
			[self constructPlotPath];
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
		[self constructPlotPath];
		return;
	}
}

#pragma mark CONVENIENCE METHODS
- (NSArray *)peaks{
	return [[self chromatogram] peaks];
}

#pragma mark ACCESSORS
- (JKChromatogram *)chromatogram {
    return chromatogram;
}

- (void)setChromatogram:(JKChromatogram *)aChromatogram {
    if (aChromatogram != chromatogram) {
        [aChromatogram retain];
        [chromatogram autorelease];
        chromatogram = aChromatogram;     
        [self setKeyForXValue:NSLocalizedString(@"Time",@"")];
        [self setKeyForYValue:NSLocalizedString(@"Total Intensity", @"")];
        [self loadDataPoints:[chromatogram numberOfPoints] withXValues:[chromatogram time] andYValues:[chromatogram totalIntensity]];
    }    
}

- (BOOL)shouldDrawPeaks{
	return shouldDrawPeaks;
}
- (void)setShouldDrawPeaks:(BOOL)inValue {
    shouldDrawPeaks = inValue;
}

@end
