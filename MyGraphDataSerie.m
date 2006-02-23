//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "MyGraphDataSerie.h"

static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
static void *PropertyObservationContext = (void *)1093;

@implementation MyGraphDataSerie

#pragma mark INITIALIZATION
- (id)init {
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
		[self setSeriesTitle:NSLocalizedString(@"New Serie",@"New series title")];
		[self setKeyForXValue:@"xValue"];
		[self setKeyForYValue:@"yValue"];
		[self setSeriesColor:[NSColor blueColor]];
		[self setSeriesType:1];
		[self setShouldDrawLabels:YES];
		[self setVerticalScale:[NSNumber numberWithFloat:1.0]];		
		
		// Voeg ons toe als observer voor veranderingen in de array met data, zoals toevoegingen en verwijderingen.
		[self addObserver:self forKeyPath:@"dataArray" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:ArrayObservationContext];	
		
		// Voeg ons toe als observer voor veranderingen in de data zelf, bijv. de x-value veranderd.
		//[self startObservingData:[self dataArray]];
		
		// Voeg ons toe als observer voor veranderingen in de properties.
		[self addObserver:self forKeyPath:@"keyForXValue" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"keyForYValue" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"seriesColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"seriesType" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"seriesTitle" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"verticalScale" options:nil context:PropertyObservationContext];	
		
		// Creeer de plot een eerste keer.
		[self constructPlotPath];
	}
    return self;
}

- (void) dealloc {
	// Voeg ons toe als observer voor veranderingen in de array met data, zoals toevoegingen en verwijderingen.
	[self removeObserver:self forKeyPath:@"dataArray"];
	
	// Voeg ons toe als observer voor veranderingen in de properties.
	[self removeObserver:self forKeyPath:@"keyForXValue"];	
	[self removeObserver:self forKeyPath:@"keyForYValue"];	
	[self removeObserver:self forKeyPath:@"seriesColor"];	
	[self removeObserver:self forKeyPath:@"seriesType"];	
	[self removeObserver:self forKeyPath:@"seriesTitle"];	
	[self removeObserver:self forKeyPath:@"verticalScale"];	
	
	[super dealloc];
}

-(void)loadDataPoints:(int)npts withXValues:(double *)xpts andYValues:(double *)ypts {
	int i;
	NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for(i=0;i<npts;i++){
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithDouble:xpts[i]], keyForXValue,
																		  [NSNumber numberWithDouble:ypts[i]], keyForYValue, nil];
		[mutArray addObject:dict];      
		[dict release];
//		NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
//		[mutDict setValue:[NSNumber numberWithDouble:xpts[i]] forKey:[self keyForXValue]];
//		[mutDict setValue:[NSNumber numberWithDouble:ypts[i]] forKey:[self keyForYValue]];
//		[mutArray addObject:mutDict];      
//		[mutDict release];
    }
	[self setDataArray:mutArray];
}


#pragma mark DRAWING ROUTINES
-(void)plotDataWithTransform:(NSAffineTransform *)trans {
	NSBezierPath *bezierpath;
	
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
			[bezierpath moveToPoint:NSMakePoint([[[[self dataArray] objectAtIndex:0] valueForKey:keyForXValue] doubleValue],
												[[[[self dataArray] objectAtIndex:0] valueForKey:keyForYValue] doubleValue]*[verticalScale doubleValue])];
			
			// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
			for (i=1; i<count; i++) {
				pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] doubleValue],
										   [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] doubleValue]*[verticalScale doubleValue]);
				[bezierpath lineToPoint:pointInUnits];
			}
				break;
			
		case 2: // Spectrum
				// We zouden eigenlijk moet controleren of de x- en y-waarden beschikbaar zijn.
			for (i=0; i<count; i++) {
				pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] doubleValue], 0.0);
				pointInUnits2 = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] doubleValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] doubleValue]*[verticalScale doubleValue]);
				[bezierpath moveToPoint:pointInUnits];
				[bezierpath lineToPoint:pointInUnits2];
			}
			
	}
	[self setPlotPath:bezierpath];
	
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
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, [[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] doubleValue]] attributes:attrs];
		
		pointToDraw = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] doubleValue], [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] doubleValue]);
		stringSize = [string size];
		pointToDraw = [trans transformPoint:pointToDraw]; // Transfrom to screen coords
		pointToDraw.x = pointToDraw.x - stringSize.width/2; // Center the label
		// Draw above or below depending on wether we have negative values
		if ([[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] doubleValue] < 0.0 ){
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
			[string release];
			rects[i] = labelRect;		
		} else {
			// Try to see if we can draw the label if we move it to the left and up
			
			// Try to see if we can draw the label if we move it to the right and up
			
		}
	}
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
	return [[self plotPath] bounds];
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
    while (newDataPoint = [dataEnumerator nextObject]) {		
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
    while (oldDataPoint = [dataEnumerator nextObject]) {
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

#pragma mark ACCESSORS
-(NSMutableArray *)dataArray {
	return dataArray;
}
-(void)setDataArray:(NSMutableArray *)inValue {
	[inValue retain];
    [dataArray autorelease];
    dataArray = inValue;
}

-(NSString *)seriesTitle {
	return seriesTitle;
}
-(void)setSeriesTitle:(NSString *)inValue {
	[inValue retain];
    [seriesTitle autorelease];
    seriesTitle = inValue;
}
-(NSString *)keyForXValue {
	return keyForXValue;
}
-(void)setKeyForXValue:(NSString *)inValue {
	[inValue retain];
    [keyForXValue autorelease];
    keyForXValue = inValue;
}
-(NSString *)keyForYValue {
	return keyForYValue;
}
-(void)setKeyForYValue:(NSString *)inValue {
	[inValue retain];
    [keyForYValue autorelease];
    keyForYValue = inValue;
}
-(NSColor *)seriesColor {
	return seriesColor;
}
-(void)setSeriesColor:(NSColor *)inValue {
	[inValue retain];
    [seriesColor autorelease];
    seriesColor = inValue;
}
-(int)seriesType {
	return seriesType;
}
-(void)setSeriesType:(int)inValue {
    seriesType = inValue;
}
-(NSBezierPath *)plotPath {
	return plotPath;
}
-(void)setPlotPath:(NSBezierPath *)inValue {
	[inValue retain];
    [plotPath autorelease];
    plotPath = inValue;
}

-(BOOL)shouldDrawLabels {
	return shouldDrawLabels;
}
-(void)setShouldDrawLabels:(BOOL)inValue {
    shouldDrawLabels = inValue;
}

-(NSNumber *)verticalScale {
	return verticalScale;
}
-(void)setVerticalScale:(NSNumber *)inValue {
	[inValue retain];
	[verticalScale autorelease];
	verticalScale = inValue;
}

- (NSArray *)oldData { 
	return oldData; 
}
- (void)setOldData:(NSArray *)anOldData {
	[anOldData retain];
	[oldData autorelease];
	oldData = anOldData;
}
@end