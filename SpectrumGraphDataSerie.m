//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "SpectrumGraphDataSerie.h"

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
		[self setSeriesType:1];
		[self setShouldDrawLabels:YES];

		boundingRect = NSZeroRect;
		
		// Creeer de plot een eerste keer.
		[self constructPlotPath];
	}
    return self;
}


#pragma mark DRAWING ROUTINES
-(void)plotDataWithTransform:(NSAffineTransform *)trans {
	NSBezierPath *bezierpath;
//	if (!plotPath) {
//		[self constructPlotPath];
//	}
	// Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
	bezierpath = [trans transformBezierPath:[self plotPath]];
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[bezierpath setLineWidth:1.0];
	[[self seriesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[bezierpath stroke];
	
	if(shouldDrawLabels) {
		if (seriesType == 2) {
			[self drawLabelsWithTransform:trans];

		}
	}
}

-(void)constructPlotPath {
	int i, count;
	NSPoint pointInUnits, pointInUnits2;
	NSBezierPath *bezierpath = [[NSBezierPath alloc] init];
	
	count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}
	
	switch  (seriesType) {
		case 0: // Points
			break;
			
		case 1: // Line
				// Creeer het pad.
			[bezierpath moveToPoint:NSMakePoint([[[[self dataArray] objectAtIndex:0] valueForKey:keyForXValue] floatValue],
												[[[[self dataArray] objectAtIndex:0] valueForKey:keyForYValue] floatValue])];
			
			// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
			for (i=1; i<count; i++) {
				pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue],
										   [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]);
				[bezierpath lineToPoint:pointInUnits];
			}
				break;
			
		case 2: // Spectrum
				// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
			for (i=0; i<count; i++) {
				pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], 0.0);
				pointInUnits2 = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]);
				[bezierpath moveToPoint:pointInUnits];
				[bezierpath lineToPoint:pointInUnits2];
			}
			
	}
	[self setPlotPath:bezierpath];
	boundingRect = [bezierpath bounds];
	
	// Stuur een bericht naar de view dat deze serie opnieuw getekend wil worden.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphDataSerieDidChangeNotification" object:self];
	[bezierpath release];
}

-(void)drawLabelsWithTransform:(NSAffineTransform *)trans {
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
	
	// We should go through the values from highest intensity ('y') to lowest instead of along the x-axis.
	// It is more important to label the higher intensities.
	for (i=0; i<count; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, [[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue]] attributes:attrs];
		
		pointToDraw = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]);
		stringSize = [string size];
		pointToDraw = [trans transformPoint:pointToDraw]; // Transfrom to screen coords
		pointToDraw.x = pointToDraw.x - stringSize.width/2; // Center the label
		// Draw above or below depending on wether we have negative values
		if ([[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue] < 0.0 ){
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
//			boundingRect = NSUnionRect(boundingRect,labelRect);
		} else {
			// Try to see if we can draw the label if we move it to the left and up
			
			// Try to see if we can draw the label if we move it to the right and up
			
		}
		[string release];
	}
	free(rects);
}

#pragma mark HELPER ROUTINES
-(void)transposeAxes {
	// Deze routine wisselt de x-as met de y-as om
	NSString *tempString = [self keyForXValue];
	[self setKeyForXValue:[self keyForYValue]];
	[self setKeyForYValue:tempString];
	[self constructPlotPath];
}
-(NSRect)boundingRect {	
	return boundingRect;
}

#pragma mark KEY VALUE OBSERVING MANAGEMENT
- (void)startObservingData:(NSArray *)data
{
	if ([data isEqual:[NSNull null]]) {
		return;
	}
	
	// Register to observe each of the new datapoints, and each of their observable properties
	NSEnumerator *dataEnumerator = [data objectEnumerator];
	
	// Declare newDataPoint as NSObject * to get key value observing methods
    NSMutableDictionary *newDataPoint;
	// Register as observer
    while ((newDataPoint = [dataEnumerator nextObject])) {		
		//		NSArray *keys = [newDataPoint allKeys];
		//		// The problem here is that we don't can register for keys that aren't yet defined in the dictionary
		//		NSEnumerator *keyEnumerator = [keys objectEnumerator];
		//		NSString *key;
		//		while (key = [keyEnumerator nextObject]) {
		//			[newDataPoint addObserver:self
		//						 forKeyPath:key
		//							options:nil
		//							context:DictionaryObservationContext];
		//		}
		[newDataPoint addObserver:self
					   forKeyPath:keyForXValue
						  options:nil
						  context:DictionaryObservationContext];
		[newDataPoint addObserver:self
					   forKeyPath:keyForYValue
						  options:nil
						  context:DictionaryObservationContext];
		
	}
}

- (void)stopObservingData:(NSArray *)data {
	if ([data isEqual:[NSNull null]]) {
		return;
	}
	
	NSEnumerator *dataEnumerator = [data objectEnumerator];
	
    NSMutableDictionary *oldDataPoint;
    while ((oldDataPoint = [dataEnumerator nextObject])) {
		//		NSArray *keys = [oldDataPoint allKeys];
		//		NSEnumerator *keyEnumerator = [keys objectEnumerator];
		//		
		//		NSString *key;
		//		while (key = [keyEnumerator nextObject]) {
		//			[oldDataPoint removeObserver:self forKeyPath:key];
		//		}
		[oldDataPoint removeObserver:self forKeyPath:keyForXValue];
		[oldDataPoint removeObserver:self forKeyPath:keyForYValue];
		
	}
}

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

#pragma mark MISC
-(NSArray *)dataArrayKeys {
	return [[dataArray objectAtIndex:0] allKeys];
}

@end
