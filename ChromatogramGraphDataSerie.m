//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "ChromatogramGraphDataSerie.h"

static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
static void *PropertyObservationContext = (void *)1093;
static void *PeaksObservationContext = (void *)1094;
static void *PeaksSelectionIndexesObservationContext = (void *)1095;

@implementation ChromatogramGraphDataSerie

#pragma mark INITIALIZATION

+ (void)initialize 
{
	// Bindings support
	[self exposeBinding:@"peaks"];
	[self exposeBinding:@"peaksSelectionIndexes"];	
}	
- (NSArray *)exposedBindings 
{
	return [NSArray arrayWithObjects:@"peaks", @"peaksSelectionIndexes", nil];
}

- (id)init {
    self = [super init];
    if (self) {
 //       // Zet de standaardwaarden
//		[self setSeriesTitle:@"New Serie"];
//		[self setKeyForXValue:@"xValue"];
//		[self setKeyForYValue:@"yValue"];
		[self setSeriesColor:[NSColor blueColor]];
		[self setSeriesType:1];
		[self setShouldDrawPeaks:YES];
		[self setShouldDrawLabels:YES];
//				
//		// Voeg ons toe als observer voor veranderingen in de array met data, zoals toevoegingen en verwijderingen.
//		[self addObserver:self forKeyPath:@"dataArray" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:ArrayObservationContext];	
//		
//		// Voeg ons toe als observer voor veranderingen in de data zelf, bijv. de x-value veranderd.
//		//[self startObservingData:[self dataArray]];
//		
//		// Voeg ons toe als observer voor veranderingen in de properties.
//		[self addObserver:self forKeyPath:@"keyForXValue" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"keyForYValue" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"seriesColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"seriesType" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"seriesTitle" options:nil context:PropertyObservationContext];	
//		
//		// Creeer de plot een eerste keer.
//		[self constructPlotPath];
	}
    return self;
}


#pragma mark DRAWING ROUTINES
-(void)plotDataWithTransform:(NSAffineTransform *)trans {
	NSBezierPath *bezierpath;
	
	if (!plotPath) [self constructPlotPath];
	
	// Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
	bezierpath = [trans transformBezierPath:[self plotPath]];
	
	if(shouldDrawPeaks)
		[self drawPeaksWithTransform:trans];
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[bezierpath setLineWidth:1.0];
	[[self seriesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[bezierpath stroke];
	
	if(shouldDrawLabels)
		[self drawLabelsWithTransform:trans];
}

-(void)constructPlotPath {
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
	
	// Stuur een bericht naar de view dat deze serie opnieuw getekend wil worden.
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphDataSerieDidChangeNotification" object:self];
	[bezierpath release];
}

-(void)drawPeaksWithTransform:(NSAffineTransform *)trans {
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
	
	for (i=0; i < count; i++) {
		[peaksPath removeAllPoints];
		
		pointToDrawFirst = NSMakePoint([[[[self peaks] objectAtIndex:i] valueForKey:@"start"] floatValue],[[[[self peaks] objectAtIndex:i] valueForKey:@"baselineL"] floatValue]); // Only works for scan, not for time!!
		pointToDrawFirst = [trans transformPoint:pointToDrawFirst];

		[peaksPath moveToPoint:pointToDrawFirst];
		
		// fori over data points
		start = [[[[self peaks] objectAtIndex:i] valueForKey:@"start"] intValue];
		end   = [[[[self peaks] objectAtIndex:i] valueForKey:@"end"] intValue]+1;
		for (j=start; j < end; j++) {
			pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:j] valueForKey:keyForXValue] floatValue],
									   [[[[self dataArray] objectAtIndex:j] valueForKey:keyForYValue] floatValue]);
			pointInUnits  = [trans transformPoint:pointInUnits];
			[peaksPath lineToPoint:pointInUnits];
		}
		
		pointToDrawLast  = NSMakePoint([[[[self peaks] objectAtIndex:i] valueForKey:@"end"] floatValue],[[[[self peaks] objectAtIndex:i] valueForKey:@"baselineR"] floatValue]);// Only works for scan, not for time!!
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

	// Draw seleced peak!
	NSArray *selectedPeaks = [NSArray array];
	selectedPeaks = [[self peaks] objectsAtIndexes:[self peaksSelectionIndexes]];
	count = [selectedPeaks count];
	NSBezierPath *arrowPath = [[NSBezierPath alloc] init];
	
	for (i=0; i < count; i++) {
		[peaksPath removeAllPoints];
		
		pointToDrawFirst = NSMakePoint([[[selectedPeaks objectAtIndex:i] valueForKey:@"start"] floatValue],[[[selectedPeaks objectAtIndex:i] valueForKey:@"baselineL"] floatValue]); // Only works for scan, not for time!!
		pointToDrawFirst = [trans transformPoint:pointToDrawFirst];
		
		[peaksPath moveToPoint:pointToDrawFirst];
		
		// fori over data points
		start = [[[selectedPeaks objectAtIndex:i] valueForKey:@"start"] intValue];
		end   = [[[selectedPeaks objectAtIndex:i] valueForKey:@"end"] intValue]+1;
		for (j=start; j < end; j++) {
			pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:j] valueForKey:keyForXValue] floatValue],
									   [[[[self dataArray] objectAtIndex:j] valueForKey:keyForYValue] floatValue]);
			pointInUnits  = [trans transformPoint:pointInUnits];
			[peaksPath lineToPoint:pointInUnits];
		}
		
		pointToDrawLast  = NSMakePoint([[[selectedPeaks objectAtIndex:i] valueForKey:@"end"] floatValue],[[[selectedPeaks objectAtIndex:i] valueForKey:@"baselineR"] floatValue]);// Only works for scan, not for time!!
			pointToDrawLast  = [trans transformPoint:pointToDrawLast];
			
			[peaksPath lineToPoint:pointToDrawLast];
			[peaksPath lineToPoint:pointToDrawFirst]; // Close area
			
			// Add tooltip (plottingArea not available -> disabled for now)
			//[self addToolTipRect:NSMakeRect(pointToDraw1.x,plottingArea.origin.y,pointToDraw2.x-pointToDraw1.x,plottingArea.size.height) owner:self userData:i];
			
			// Set color
			[[NSColor selectedControlColor] set];
			
			// Draw
			[peaksPath fill];
			
			// Draw an triangle
			[arrowPath removeAllPoints];
			top = [[[selectedPeaks objectAtIndex:i] valueForKey:@"top"] intValue];
			pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:top] valueForKey:keyForXValue] floatValue],
									   [[[[self dataArray] objectAtIndex:top] valueForKey:keyForYValue] floatValue]);
			pointInUnits  = [trans transformPoint:pointInUnits];
			
			[arrowPath moveToPoint:pointInUnits];
			[arrowPath relativeMoveToPoint:NSMakePoint(0.0,18.0)];
//			[arrowPath relativeLineToPoint:NSMakePoint(-6.0,12.0)];
//			[arrowPath relativeLineToPoint:NSMakePoint(12.0,0.0)];
//			[arrowPath relativeLineToPoint:NSMakePoint(-6.0,-12.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-8.0,8.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(4.0,0.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(0.0,8.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(8.0,0.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(0.0,-8.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(4.0,0.0)];
			[arrowPath relativeLineToPoint:NSMakePoint(-8.0,-8.0)];
			[[self seriesColor] set];
			[arrowPath stroke];
			
	}
	
	[arrowPath release];
	[peaksPath release];
}

-(void)drawLabelsWithTransform:(NSAffineTransform *)trans {
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
	 
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	
	for (i=0; i<count; i++) {
		if ([[[self peaks] objectAtIndex:i] valueForKeyPath:@"symbol"] && ![[[[self peaks] objectAtIndex:i] valueForKeyPath:@"symbol"] isEqualToString:@""]) {
			string = [[NSMutableAttributedString alloc] initWithString:[[[self peaks] objectAtIndex:i] valueForKey:@"symbol"] attributes:attrs];
			drawVertical = NO; drawLabelAlways = YES;
		} else if ([[[self peaks] objectAtIndex:i] valueForKeyPath:@"label"] && ![[[[self peaks] objectAtIndex:i] valueForKeyPath:@"label"] isEqualToString:@""]) {
			string = [[NSMutableAttributedString alloc] initWithString:[[[self peaks] objectAtIndex:i] valueForKey:@"label"] attributes:attrs];
			drawVertical = YES; drawLabelAlways = NO;
		} else {
			string = [[NSMutableAttributedString alloc] initWithString:[[[[self peaks] objectAtIndex:i] valueForKey:@"peakID"] stringValue] attributes:attrs];
			drawVertical = NO; drawLabelAlways = NO;
		}
		
		// Where will it be drawn?
		pointToDraw = NSMakePoint([[[[self peaks] objectAtIndex:i] valueForKey:@"top"] floatValue], 
								  [[[[self dataArray] objectAtIndex:[[[[self peaks] objectAtIndex:i] valueForKey:@"top"] intValue]] valueForKey:keyForYValue] floatValue]);
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

#pragma mark HELPER ROUTINES
-(NSRect)boundingRect {
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

#pragma mark MISC
-(NSArray *)dataArrayKeys {
	return [[dataArray objectAtIndex:0] allKeys];
}

#pragma mark BINDINGS
- (NSMutableArray *)peaks
{
	return [peaksContainer valueForKeyPath:peaksKeyPath];
}
- (NSIndexSet *)peaksSelectionIndexes
{
	return [peaksSelectionIndexesContainer valueForKeyPath:peaksSelectionIndexesKeyPath];
}

- (void)bind:(NSString *)bindingName
	toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
	 options:(NSDictionary *)options
{
	
	if ([bindingName isEqualToString:@"peaks"])
	{
		[self setPeaksContainer:observableObject];
		[self setPeaksKeyPath:observableKeyPath];
		[peaksContainer addObserver:self
						 forKeyPath:peaksKeyPath
							options:nil
							context:PeaksObservationContext];
	}
	else if ([bindingName isEqualToString:@"peaksSelectionIndexes"])
	{
		[self setPeaksSelectionIndexesContainer:observableObject];
		[self setPeaksSelectionIndexesKeyPath:observableKeyPath];
		[peaksSelectionIndexesContainer addObserver:self
										 forKeyPath:peaksSelectionIndexesKeyPath
											options:nil
											context:PeaksSelectionIndexesObservationContext];
	}
	
	[super bind:bindingName
	   toObject:observableObject
	withKeyPath:observableKeyPath
		options:options];
	
}


- (void)unbind:(NSString *)bindingName {
	
	if ([bindingName isEqualToString:@"peaks"])
	{
		[peaksContainer removeObserver:self forKeyPath:peaksKeyPath];
		[self setPeaksContainer:nil];
		[self setPeaksKeyPath:nil];
	}
	else if ([bindingName isEqualToString:@"peaksSelectionIndexes"])
	{
		[peaksSelectionIndexesContainer removeObserver:self forKeyPath:peaksSelectionIndexesKeyPath];
		[self setPeaksSelectionIndexesContainer:nil];
		[self setPeaksSelectionIndexesKeyPath:nil];
	}

	[super unbind:bindingName];
}

- (NSObject *)peaksContainer
{
    return peaksContainer; 
}
- (void)setPeaksContainer:(NSObject *)aPeaksContainer
{
    if (peaksContainer != aPeaksContainer) {
        [peaksContainer release];
        peaksContainer = [aPeaksContainer retain];
    }
}
- (NSObject *)peaksSelectionIndexesContainer
{
    return peaksSelectionIndexesContainer; 
}
- (void)setPeaksSelectionIndexesContainer:(NSObject *)aPeaksSelectionIndexesContainer
{
    if (peaksSelectionIndexesContainer != aPeaksSelectionIndexesContainer) {
        [peaksSelectionIndexesContainer release];
        peaksSelectionIndexesContainer = [aPeaksSelectionIndexesContainer retain];
    }
}

- (NSString *)peaksKeyPath
{
    return peaksKeyPath; 
}
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath
{
    if (peaksKeyPath != aPeaksKeyPath) {
        [peaksKeyPath release];
        peaksKeyPath = [aPeaksKeyPath copy];
    }
}
- (NSString *)peaksSelectionIndexesKeyPath
{
    return peaksSelectionIndexesKeyPath; 
}
- (void)setPeaksSelectionIndexesKeyPath:(NSString *)aPeaksSelectionIndexesKeyPath
{
    if (peaksSelectionIndexesKeyPath != aPeaksSelectionIndexesKeyPath) {
        [peaksSelectionIndexesKeyPath release];
        peaksSelectionIndexesKeyPath = [aPeaksSelectionIndexesKeyPath copy];
    }
}

#pragma mark ACCESSORS
-(BOOL)shouldDrawPeaks
{
	return shouldDrawPeaks;
}
-(void)setShouldDrawPeaks:(BOOL)inValue 
{
    shouldDrawPeaks = inValue;
}

@end
