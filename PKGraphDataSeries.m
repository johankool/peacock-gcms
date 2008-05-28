//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKGraphDataSeries.h"
#import "PKGraphView.h"

static void *DictionaryObservationContext = (void *)1091;
static void *ArrayObservationContext = (void *)1092;
//static void *PropertyObservationContext = (void *)1093;

@implementation PKGraphDataSeries

#pragma mark Initialization & deallocation
- (id)init 
{
    self = [super init];
    if (self) {
        // Zet de standaardwaarden
        seriesTitle = [NSLocalizedString(@"New Serie",@"New series title") retain];
        keyForXValue = [@"xValue" retain];
        keyForYValue = [@"yValue" retain];
        keyForLabel = [@"label" retain];
        seriesColor = [[NSColor blueColor] retain];
        seriesType = 0;
        shouldDrawLabels = YES;
        verticalScale = [[NSNumber alloc] initWithFloat:1.0f];
        verticalOffset = [[NSNumber alloc] initWithFloat:0.0f];
        lineThickness = [[NSNumber alloc] initWithFloat:1.0f];
        dataArray = [[NSMutableArray alloc] init];

        _plotPath = [[NSBezierPath alloc] init];
        _previousTrans = nil;
        _needsReconstructingPlotPath = YES;
        observeData = NO;
        isVisible = YES;
	}
    return self;
}

- (void) dealloc {	
    if (observeData) {
        [self stopObservingData:[self dataArray]];
    }
    
    [seriesTitle release];
    [keyForXValue release];
    [keyForYValue release];
    [seriesColor release];
    [verticalScale release];
    [dataArray release];
    [_plotPath release];
    [_previousTrans release];
    [lineThickness release];
	[super dealloc];
}
#pragma mark -

#pragma mark NSCoding
- (id)initWithCoder:(NSCoder *)decoder
{
	[super init];
	shouldDrawLabels = [decoder decodeBoolForKey:@"shouldDrawLabels"];
	observeData = [decoder decodeBoolForKey:@"observeData"];
	seriesType = [decoder decodeIntForKey:@"seriesType"];
	seriesColor = [[decoder decodeObjectForKey:@"seriesColor"] retain];
	verticalScale = [[decoder decodeObjectForKey:@"verticalScale"] retain];
	seriesTitle = [[decoder decodeObjectForKey:@"seriesTitle"] retain];
    
	dataArray = [[decoder decodeObjectForKey:@"dataArray"] retain];

    keyForXValue = [[decoder decodeObjectForKey:@"keyForXValue"] retain];
	acceptableKeysForXValue = [[decoder decodeObjectForKey:@"acceptableKeysForXValue"] retain];

    keyForYValue = [[decoder decodeObjectForKey:@"keyForYValue"] retain];
	acceptableKeysForYValue = [[decoder decodeObjectForKey:@"acceptableKeysForYValue"] retain];

    keyForLabel = [[decoder decodeObjectForKey:@"keyForLabel"] retain];
	acceptableKeysForLabel = [[decoder decodeObjectForKey:@"acceptableKeysForLabel"] retain];

    _plotPath = [[NSBezierPath alloc] init];
    _previousTrans = nil;
    _needsReconstructingPlotPath = YES;
    
    if (observeData) {
        [self startObservingData:[self dataArray]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeInt:0 forKey:@"version"];
    [encoder encodeBool:shouldDrawLabels forKey:@"shouldDrawLabels"];
	[encoder encodeBool:observeData forKey:@"observeData"];
	[encoder encodeInt:seriesType forKey:@"seriesType"];
	[encoder encodeObject:seriesColor forKey:@"seriesColor"];
	[encoder encodeObject:verticalScale forKey:@"verticalScale"];
	[encoder encodeObject:seriesTitle forKey:@"seriesTitle"];

    [encoder encodeObject:dataArray forKey:@"dataArray"];
    
    [encoder encodeObject:keyForXValue forKey:@"keyForXValue"];
	[encoder encodeObject:acceptableKeysForXValue forKey:@"acceptableKeysForXValue"];

    [encoder encodeObject:keyForYValue forKey:@"keyForYValue"];
	[encoder encodeObject:acceptableKeysForYValue forKey:@"acceptableKeysForYValue"];

    [encoder encodeObject:keyForLabel forKey:@"keyForLabel"];
	[encoder encodeObject:acceptableKeysForLabel forKey:@"acceptableKeysForLabel"];
}
#pragma mark -

#pragma mark Reading Data
- (void)loadDataPoints:(int)npts withXValues:(float *)xpts andYValues:(float *)ypts {
    if (npts < 1) {
        return;
    }
	int i;
	NSMutableArray *mutArray = [[NSMutableArray alloc] init];
    for(i=0;i<npts;i++){
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithFloat:xpts[i]], keyForXValue,
																		  [NSNumber numberWithFloat:ypts[i]], keyForYValue, nil];
		[mutArray addObject:dict];      
		[dict release];
    }
	[self setDataArray:mutArray];
    [mutArray release];
    
    [self constructPlotPath];
}
#pragma mark -

#pragma mark Drawing Routines
- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view
{
    _graphView = view;
 
    if (!isVisible) {
        return;
    }
    
    NSBezierPath *bezierpath;
    
    
    switch  ([self seriesType]) {
		case 0: // Points
            [self setOldTrans:trans];
            _needsReconstructingPlotPath = YES;
            [self constructPlotPath];
         
            [[self seriesColor] set];
            
            // Met stroke wordt de bezierpath getekend.
            [_plotPath fill];
            [_plotPath stroke];
			break;
        case 1:
        case 2:
        default:       
            [self constructPlotPath];

            // Hier gaan we van dataserie-coordinaten naar scherm-coordinaten.
            bezierpath = [trans transformBezierPath:_plotPath];

            // Hier stellen we in hoe de lijnen eruit moeten zien.
            [bezierpath setLineWidth:[self.lineThickness floatValue]];
            [[self seriesColor] set];
            
            // Met stroke wordt de bezierpath getekend.
            [bezierpath stroke];
            
            break;
    }
	
	
	if(shouldDrawLabels) {
        [self drawLabelsWithTransform:trans inView:view];
	}
}

- (void)constructPlotPath {
    if (!_needsReconstructingPlotPath) {
        return;
    }

	int i, count;
	NSPoint pointInUnits, pointInUnits2, pointInScreen;
    
	// Keeping track of the bounds rect, because NSBezierPath can't handle that for circles?!!!!
	_boundsRect = NSZeroRect;
    
	count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}

    NSBezierPath *bezierpath = [[NSBezierPath alloc] init];

	switch  (seriesType) {
		case 0: // Points
            _lowestX = 0.0f;
            _highestX = 0.0f;
            _lowestY = 0.0f;
            _highestY = 0.0f;
			for (i=0; i<count; i++) {    
                pointInUnits = NSMakePoint([[[[self dataArray] objectAtIndex:i] valueForKey:keyForXValue] floatValue],
                                           [[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue]);
                if ([self oldTrans]) {
                    pointInScreen = [[self oldTrans] transformPoint:pointInUnits];
                    NSRect pointRect = NSMakeRect(pointInScreen.x-1.5f, pointInScreen.y-1.5f, 3.0f, 3.0f);
  //                  _boundsRect = NSUnionRect(pointRect,_boundsRect);
                    if (pointInScreen.x < _lowestX) {
                        _lowestX = pointInScreen.x;
                    }
                    if (pointInScreen.x > _highestX) {
                        _highestX = pointInScreen.x;
                    }
                    if (pointInScreen.y < _lowestX) {
                        _lowestY = pointInScreen.y;
                    }
                    if (pointInScreen.y > _highestY) {
                        _highestY = pointInScreen.y;
                    }
                    [bezierpath appendBezierPathWithOvalInRect:pointRect];                   
                } else {
                    NSRect pointRect = NSMakeRect(pointInUnits.x-1.5f, pointInUnits.y-1.5f, 3.0f, 3.0f);
                    _boundsRect = NSUnionRect(pointRect,_boundsRect);
                    [bezierpath appendBezierPathWithOvalInRect:pointRect];                   
                }
			}
            
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
	
	// Stuur een bericht naar de view dat deze serie opnieuw getekend wil worden.
	[_graphView setNeedsDisplayInRect:[_graphView plottingArea]];
	[bezierpath release];
    _needsReconstructingPlotPath = NO;
}

- (void)drawLabelsWithTransform:(NSAffineTransform *)trans inView:(PKGraphView *)view {
    _graphView = view;
	int count = [[self dataArray] count];
	if (count <= 0) {	
		return;
	}
				
	NSMutableAttributedString *string;
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	int i,j;
	BOOL drawLabel;
//    PKLogDebug([[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"drawLabelsAlways"]);
    BOOL drawLabelAlways = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"drawLabelsAlways"] intValue];
//    if (drawLabelAlways) {
//        PKLogInfo(@"Will draw labels always");
//    }
	NSSize stringSize;
	NSPoint pointToDraw;
//	NSString *formatString = @"%.f";
	NSRect labelRect;
	
	int rectCount = [[self dataArray] count];

	NSRectArray rects;
	rects = (NSRectArray) calloc(rectCount, sizeof(NSRect));
	 
	[attrs setValue:[view labelFont] forKey:NSFontAttributeName];
	
	// We should go through the values from highest intensity ('y') to lowest instead of along the x-axis.
	// It is more important to label the higher intensities.
	for (i=0; i<count; i++) {
        id label =[[[self dataArray] objectAtIndex:i] valueForKey:keyForLabel];
//       PKLogDebug([label description]);
        if (!label) {
            PKLogWarning(@"No label");
            continue;
        }
        if ([label respondsToSelector:@selector(stringValue)]) {
            string = [[NSMutableAttributedString alloc] initWithString:[label stringValue] attributes:attrs];          
        } else {
            string = [[NSMutableAttributedString alloc] initWithString:(NSString *)label attributes:attrs];          
        }
		
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
        if (!drawLabelAlways) {
            for (j = 0; j < rectCount; j++) {
                if (NSIntersectsRect(labelRect,rects[j])) {
                    drawLabel = NO;
                }
            }            
        
            if (!drawLabel && seriesType == 0) {
                if ([[[[self dataArray] objectAtIndex:i] valueForKey:keyForYValue] floatValue] >= 0.0 ){
                    pointToDraw.y = pointToDraw.y - stringSize.height - 4;
                } else {
                    pointToDraw.y = pointToDraw.y + 4;
                }		
                
                labelRect = NSMakeRect(pointToDraw.x,pointToDraw.y,stringSize.width,stringSize.height); // The rect for the label to draw
                
                // Only draw label if it doesn't run over another one
                drawLabel = YES;
                if (!drawLabelAlways) {
                    for (j = 0; j < rectCount; j++) {
                        if (NSIntersectsRect(labelRect,rects[j])) {
                            drawLabel = NO;
                        }
                    }     
                }
            }
        }
		if (drawLabel) {
			[string drawAtPoint:pointToDraw];
			rects[i] = labelRect;		
		} else {
			// Try to see if we can draw the label if we move it to the left and up
			
			// Try to see if we can draw the label if we move it to the right and up
			
		}
        [string release];

	}
}
#pragma mark -

#pragma mark Helper Routines
- (void)transposeAxes {
	// Deze routine wisselt de x-as met de y-as om
	NSString *tempString = [self keyForXValue];
	[self setKeyForXValue:[self keyForYValue]];
	[self setKeyForYValue:tempString];
	_needsReconstructingPlotPath = YES;
}
- (NSRect)boundingRect {
//    return NSMakeRect(-1.0f,-1.0f,2.0f,2.0f);
    [self constructPlotPath];
    if (seriesType == 0) {
        NSAffineTransform *invertedTransform = [[self oldTrans] copy];
        [invertedTransform invert];
        NSRect bounds = [[invertedTransform transformBezierPath:[self plotPath]] bounds];
        [invertedTransform release];
        return bounds;
    }
//            NSMakeRect(_lowestX, _lowestY, _highestX-_lowestX, _highestY-_lowestY);
    return [_plotPath bounds];
}
#pragma mark -

#pragma mark Key Value Observing Management
- (void)startObservingData:(NSArray *)data{
	if ([data isEqual:[NSNull null]]) {
		return;
	}
	
    if (observeData) {
        // Register to observe each of the new datapoints, and each of their observable properties
        
        // Declare newDataPoint as NSObject * to get key value observing methods
        NSMutableDictionary *newDataPoint;
        
        // Register as observer
        for (newDataPoint in data) {		
            [newDataPoint addObserver:self
                           forKeyPath:keyForXValue
                              options:0
                              context:DictionaryObservationContext];
            [newDataPoint addObserver:self
                           forKeyPath:keyForYValue
                              options:0
                              context:DictionaryObservationContext];
            [newDataPoint addObserver:self
                           forKeyPath:keyForLabel
                              options:0
                              context:DictionaryObservationContext];		
        }        
    }
}

- (void)stopObservingData:(NSArray *)data {
	if ([data isEqual:[NSNull null]]) {
		return;
	}
	if (observeData) {
        
        NSMutableDictionary *oldDataPoint;
        for (oldDataPoint in data) {
            [oldDataPoint removeObserver:self forKeyPath:keyForXValue];
            [oldDataPoint removeObserver:self forKeyPath:keyForYValue];
            [oldDataPoint removeObserver:self forKeyPath:keyForLabel];		
        }        
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	
    if (context == ArrayObservationContext)
	{
        if (observeData) {
            NSArray *newData = [self dataArray];
            [self stopObservingData:_oldData];
            [self startObservingData:newData];
            
            [self setOldData:newData];            
        }
		
		_needsReconstructingPlotPath = YES;
		return;
    }
}
#pragma mark -

#pragma mark Accessors
- (NSMutableArray *)dataArray {
	return dataArray;
}
- (void)setDataArray:(NSMutableArray *)inValue {
    if (inValue != dataArray) {
        [inValue retain];
        [dataArray autorelease];
        dataArray = inValue;  
        _needsReconstructingPlotPath = YES;
    }
}

- (NSString *)seriesTitle {
	return seriesTitle;
}
- (void)setSeriesTitle:(NSString *)inValue {
	if (inValue != seriesTitle) {
        [inValue retain];
        [seriesTitle autorelease];
        seriesTitle = inValue;
        [_graphView setNeedsDisplayInRect:[_graphView legendArea]];
    }
}

- (NSString *)keyForXValue {
	return keyForXValue;
}
- (void)setKeyForXValue:(NSString *)inValue {
	if (inValue != keyForXValue) {
        [self stopObservingData:[self dataArray]];
        [inValue retain];
        [keyForXValue autorelease];
        keyForXValue = inValue;
        [self startObservingData:[self dataArray]];
        _needsReconstructingPlotPath = YES;
        [_graphView setNeedsDisplay:YES];
    }
}
- (NSArray *)acceptableKeysForXValue {
	return acceptableKeysForXValue;
}
- (void)setAcceptableKeysForXValue:(NSArray *)aAcceptableKeysForXValue {
    if (aAcceptableKeysForXValue != acceptableKeysForXValue) {
        [acceptableKeysForXValue autorelease];
        acceptableKeysForXValue = [aAcceptableKeysForXValue retain];        
    }
}

- (NSString *)keyForYValue {
	return keyForYValue;
}
- (void)setKeyForYValue:(NSString *)inValue {
	if (inValue != keyForYValue) {
        [inValue retain];
        [keyForYValue autorelease];
        keyForYValue = inValue;
        _needsReconstructingPlotPath = YES;
        [_graphView setNeedsDisplay:YES];
    }
}

- (NSArray *)acceptableKeysForYValue {
	return acceptableKeysForYValue;
}
- (void)setAcceptableKeysForYValue:(NSArray *)aAcceptableKeysForYValue {
    if (aAcceptableKeysForYValue != acceptableKeysForYValue) {
        [acceptableKeysForYValue autorelease];
        acceptableKeysForYValue = [aAcceptableKeysForYValue retain];        
    }
}

- (NSString *)keyForLabel {
	return keyForLabel;
}
- (void)setKeyForLabel:(NSString *)inValue {
	if (inValue != keyForLabel) {
        [inValue retain];
        [keyForLabel autorelease];
        keyForLabel = inValue;
        [_graphView setNeedsDisplayInRect:[_graphView plottingArea]];
    }
}

- (NSArray *)acceptableKeysForLabel {
	return acceptableKeysForLabel;
}
- (void)setAcceptableKeysForLabel:(NSArray *)aAcceptableKeysForLabel {
    if (aAcceptableKeysForLabel != acceptableKeysForLabel) {
        [acceptableKeysForLabel autorelease];
        acceptableKeysForLabel = [aAcceptableKeysForLabel retain];        
    }
}

- (NSColor *)seriesColor {
	return seriesColor;
}
- (void)setSeriesColor:(NSColor *)inValue {
    if (inValue != seriesColor) {
        [inValue retain];
        [seriesColor autorelease];
        seriesColor = inValue;
        [_graphView setNeedsDisplayInRect:[_graphView plottingArea]];        
    }
}

- (int)seriesType {
	return seriesType;
}
- (void)setSeriesType:(int)inValue {
    if (inValue != seriesType) {
        seriesType = inValue;
        _needsReconstructingPlotPath = YES;
        [_graphView setNeedsDisplayInRect:[_graphView plottingArea]];
    }
}

- (NSBezierPath *)plotPath {
	return _plotPath;
}
- (void)setPlotPath:(NSBezierPath *)inValue {
    if (inValue != _plotPath) {
        [inValue retain];
        [_plotPath autorelease];
        _plotPath = inValue;        
    }
}

- (BOOL)shouldDrawLabels {
	return shouldDrawLabels;
}
- (void)setShouldDrawLabels:(BOOL)inValue {
    if (inValue != shouldDrawLabels) {
        shouldDrawLabels = inValue;
        [_graphView setNeedsDisplay:YES];
    }
}

- (NSNumber *)verticalScale {
	return verticalScale;
}
- (void)setVerticalScale:(NSNumber *)inValue {
    if (inValue != verticalScale) {
        [inValue retain];
        [verticalScale autorelease];
        verticalScale = inValue;
        _needsReconstructingPlotPath = YES;
        [_graphView setNeedsDisplayInRect:[_graphView plottingArea]];
    }
}

- (NSNumber *)verticalOffset {
	return verticalOffset;
}
- (void)setVerticalOffset:(NSNumber *)inValue {
    if (inValue != verticalOffset) {
        [inValue retain];
        [verticalOffset autorelease];
        verticalOffset = inValue;
        _needsReconstructingPlotPath = YES;
        [_graphView setNeedsDisplayInRect:[_graphView plottingArea]];
    }
}

- (NSArray *)oldData { 
	return _oldData; 
}
- (void)setOldData:(NSArray *)anOldData {
	[anOldData retain];
	[_oldData autorelease];
	_oldData = anOldData;
}

- (NSAffineTransform *)oldTrans { 
	return _previousTrans; 
}
- (void)setOldTrans:(NSAffineTransform *)anOldTrans {
    if (anOldTrans != _previousTrans) {
        [anOldTrans retain];
        [_previousTrans autorelease];
        _previousTrans = anOldTrans;
        _needsReconstructingPlotPath = YES;
    }
}
@synthesize _graphView;
@synthesize observeData;
@synthesize _plotPath;
@synthesize _previousTrans;
@synthesize _oldData;
@synthesize _needsReconstructingPlotPath;
@synthesize isVisible;
@synthesize verticalOffset;
@synthesize lineThickness;
@end
