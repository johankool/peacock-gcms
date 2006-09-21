//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2006 Johan Kool. All rights reserved.
//


#import "MyGraphView.h"
#import "MyGraphDataSerie.h"
#import "ChromatogramGraphDataSerie.h"
#import "SpectrumGraphDataSerie.h"

static void *DataSeriesObservationContext = (void *)1092;
static void *PeaksObservationContext = (void *)1093;
static void *PropertyObservationContext = (void *)1094;
static void *FrameObservationContext = (void *)1095;
static void *DataObservationContext = (void *)1096;
static void *BaselineObservationContext = (void *)1097;

NSString *const MyGraphView_DidBecomeFirstResponderNotification = @"MyGraphView_DidBecomeFirstResponderNotification"; 
NSString *const MyGraphView_DidResignFirstResponderNotification = @"MyGraphView_DidResignFirstResponderNotification";

@implementation MyGraphView

#pragma mark INITIALIZATION
+ (void)initialize 
{
	// Bindings support
	[self exposeBinding:@"dataSeries"];
	[self exposeBinding:@"peaks"];
	[self exposeBinding:@"baseline"];
	
	// Dependent keys
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMaximum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMaximum"];	
}

- (NSArray *)exposedBindings 
{
	return [NSArray arrayWithObjects:@"dataSeries", @"peaks", @"baseline", nil];
}

- (id)initWithFrame:(NSRect)frame 
{
	self = [super initWithFrame:frame];
    if (self) {
		// Support transparency
		[NSColor setIgnoresAlpha:NO];

        // Defaults
		[self setOrigin:NSMakePoint(50.5,50.5)];
		[self setPixelsPerXUnit:[NSNumber numberWithFloat:20.0]];
		[self setPixelsPerYUnit:[NSNumber numberWithFloat:10]];
		[self setMinimumPixelsPerMajorGridLine:[NSNumber numberWithFloat:25]];
		[self setPlottingArea:NSMakeRect(50.5,20.5,[self bounds].size.width-60.5,[self bounds].size.height-25.5)];
		[self setLegendArea:NSMakeRect([self bounds].size.width-200-10-10,[self bounds].size.height-18-10-5,200,18)];
		[self setSelectedRect:NSMakeRect(0,0,0,0)];
		
		[self setShouldDrawAxes:NO];
		[self setShouldDrawFrame:YES];
		[self setShouldDrawMajorTickMarks:YES];
		[self setShouldDrawMinorTickMarks:YES];
		[self setShouldDrawGrid:YES];
		[self setShouldDrawLabels:NO];
		[self setShouldDrawLegend:YES];
		[self setShouldDrawLabelsOnFrame:YES];
		
		[self setBackColor:[NSColor clearColor]];
		[self setPlottingAreaColor:[NSColor whiteColor]];
		[self setAxesColor:[NSColor blackColor]];
		[self setFrameColor:[NSColor clearColor]];
		[self setGridColor:[NSColor gridColor]];
		[self setLabelsColor:[NSColor blackColor]];
		[self setLabelsOnFrameColor:[NSColor blackColor]];
		[self setLegendAreaColor:[NSColor whiteColor]];
		[self setLegendFrameColor:[NSColor whiteColor]];
				
//		// Observe changes for what values to draw
//		[self addObserver:self forKeyPath:@"keyForXValue" options:nil context:DataObservationContext];
//		[self addObserver:self forKeyPath:@"keyForYValue" options:nil context:DataObservationContext];
//		[self addObserver:self forKeyPath:@"dataSeries" options:nil context:DataObservationContext];
//		
//		// Observe changes for plotting area
//		[self addObserver:self forKeyPath:@"origin" options:nil context:PropertyObservationContext];
//		[self addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:FrameObservationContext];	
//
//		// Observe changes for what to draw
//		[self addObserver:self forKeyPath:@"shouldDrawAxes" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawMajorTickMarks" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawMinorTickMarks" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawLegend" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawGrid" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawLabels" options:nil context:PropertyObservationContext];
//		[self addObserver:self forKeyPath:@"shouldDrawLabelsOnFrame" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawLegend" options:nil context:PropertyObservationContext];	
//		
//		// Observe changes for color
//		[self addObserver:self forKeyPath:@"backColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"plottingAreaColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"axesColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"gridColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"labelsColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"labelsOnFrameColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"legendAreaColor" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"legendFrameColor" options:nil context:PropertyObservationContext];	
//		
//		// Observe changes for zooming
//		[self addObserver:self forKeyPath:@"minimumPixelsPerMajorGridLine" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"pixelsPerXUnit" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"pixelsPerYUnit" options:nil context:PropertyObservationContext];
//		
//		// Observe changes for text
//		[self addObserver:self forKeyPath:@"titleString" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"xAxisLabelString" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"yAxisLabelString" options:nil context:PropertyObservationContext];	

		// Additions for Peacock
		[self setShouldDrawBaseline:NO];
		[self setShouldDrawPeaks:YES];
        [self setSelectedScan:0];
        
//		[self addObserver:self forKeyPath:@"baseline" options:nil context:PropertyObservationContext];			
//		[self addObserver:self forKeyPath:@"shouldDrawBaseline" options:nil context:PropertyObservationContext];	
//		[self addObserver:self forKeyPath:@"shouldDrawPeaks" options:nil context:PropertyObservationContext];	
	}
	return self;
}

- (void)dealloc
{
	[self unbind:@"baseline"];
	[self unbind:@"peaks"];
	[self unbind:@"dataSeries"];
//	[self removeObserver:self forKeyPath:@"dataSeries"];

//	// Observe changes for what values to draw
//	[self removeObserver:self forKeyPath:@"keyForXValue"];
//	[self removeObserver:self forKeyPath:@"keyForYValue"];
//	
//	// Observe changes for plotting area
//	[self removeObserver:self forKeyPath:@"origin"];
//	[self removeObserver:self forKeyPath:@"frame"];	
//	
//	// Observe changes for what to draw
//	[self removeObserver:self forKeyPath:@"shouldDrawAxes"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawMajorTickMarks"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawMinorTickMarks"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawLegend"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawGrid"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawLabels"];
//	[self removeObserver:self forKeyPath:@"shouldDrawLabelsOnFrame"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawLegend"];	
//	
//	// Observe changes for color
//	[self removeObserver:self forKeyPath:@"backColor"];	
//	[self removeObserver:self forKeyPath:@"plottingAreaColor"];	
//	[self removeObserver:self forKeyPath:@"axesColor"];	
//	[self removeObserver:self forKeyPath:@"gridColor"];	
//	[self removeObserver:self forKeyPath:@"labelsColor"];	
//	[self removeObserver:self forKeyPath:@"labelsOnFrameColor"];	
//	[self removeObserver:self forKeyPath:@"legendAreaColor"];	
//	[self removeObserver:self forKeyPath:@"legendFrameColor"];	
//	
//	// Observe changes for zooming
//	[self removeObserver:self forKeyPath:@"minimumPixelsPerMajorGridLine"];	
//	[self removeObserver:self forKeyPath:@"pixelsPerXUnit"];	
//	[self removeObserver:self forKeyPath:@"pixelsPerYUnit"];
//	
//	// Observe changes for text
//	[self removeObserver:self forKeyPath:@"titleString"];	
//	[self removeObserver:self forKeyPath:@"xAxisLabelString"];	
//	[self removeObserver:self forKeyPath:@"yAxisLabelString"];	
//	
//	// Additions for Peacock
//	[self removeObserver:self forKeyPath:@"baseline"];			
//	[self removeObserver:self forKeyPath:@"shouldDrawBaseline"];	
//	[self removeObserver:self forKeyPath:@"shouldDrawPeaks"];	
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];
}



#pragma mark DRAWING ROUTINES

- (void)drawRect:(NSRect)rect  
{
	[self calculateCoordinateConversions];
        
	// Fancy schaduw effecten...
	NSShadow *noShadow = [[NSShadow alloc] init];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:10];
	[shadow setShadowOffset:NSMakeSize(6,-6)];
		
	// Achtergrondkleur
	[noShadow set];
	[[self backColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] fill];

	// Achtergrondkleur plottingArea (met schaduw)
	// Draw shadow with focusring color if firstResponder
	if (([[self window] isKeyWindow]) && ([[self window] firstResponder] == self) && ([[NSGraphicsContext currentContext] isDrawingToScreen])) {
		[shadow setShadowColor:[NSColor keyboardFocusIndicatorColor]];
    }
	[shadow set]; 	    
    [[self plottingAreaColor] set];        
    
	if (NSIntersectsRect([self plottingArea],rect))
		[[NSBezierPath bezierPathWithRect:[self plottingArea]] fill];
	
	// Frame om plottingArea	
	[noShadow set];
	[[self frameColor] set];
	if (NSIntersectsRect([self plottingArea],rect))
		[[NSBezierPath bezierPathWithRect:[self plottingArea]] stroke];

    // Draw plotting inside the plotting area
    if (NSIntersectsRect([self plottingArea],rect)) {
        [NSGraphicsContext saveGraphicsState];	
        [[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
        
        if ([self shouldDrawGrid])
            [self drawGrid];
        if ([self shouldDrawAxes]) {
            [self drawAxes];
            if ([self shouldDrawMajorTickMarks]) {
                [self drawMajorTickMarks];
                if ([self shouldDrawMinorTickMarks])
                    [self drawMinorTickMarks];
            }
        }
        
        
        if ([self shouldDrawLabels])
            [self drawLabels];
        
        // Additions for Peacock
        if ([self shouldDrawBaseline])
            [self drawBaseline];
        
        // In plaats van een loop kunnen we ook deze convenient method gebruiken om iedere dataserie zich te laten tekenen.
        //NSAssert([[self dataSeries] count] >= 1, @"No dataSeries to draw.");
        NSEnumerator *enumerator = [[self dataSeries] objectEnumerator];
        id object;
        
        while ((object = [enumerator nextObject])) {
            // do something with object...
            //	NSLog([object description]);
            if ([object respondsToSelector:@selector(plotDataWithTransform:)]) {
                [object plotDataWithTransform:[self transformGraphToScreen]];
            }
        }  
        
        // Draw line for selected scan
        if (([self selectedScan] > 0) && ([[NSGraphicsContext currentContext] isDrawingToScreen])) {
            [[NSColor blackColor] set];
            NSPoint point = [[self transformGraphToScreen] transformPoint:NSMakePoint([self selectedScan]*1.0, 0)];
            
            NSBezierPath *selectedScanBezierPath = [NSBezierPath bezierPath];
            [selectedScanBezierPath moveToPoint:NSMakePoint(point.x, [self plottingArea].origin.y)];
            [selectedScanBezierPath lineToPoint:NSMakePoint(point.x, [self plottingArea].origin.y+[self plottingArea].size.height)];
            [selectedScanBezierPath stroke];        
        }
        
    }
    
	[NSGraphicsContext restoreGraphicsState];
    
	if ([self shouldDrawFrame]) {
        [self drawFrame];
        if ([self shouldDrawMajorTickMarks]) {
            [self drawMajorTickMarksOnFrame];
            if ([self shouldDrawMinorTickMarks])
                [self drawMinorTickMarksOnFrame];
        }
    }
    
	if ([self shouldDrawLabelsOnFrame])
		[self drawLabelsOnFrame];
	if (([self shouldDrawLegend]) && ([self needsToDrawRect:[self legendArea]]))
		[self drawLegend];
	[self drawTitles];
	
    if (NSIntersectsRect([self selectedRect],rect)) {
        [[[NSColor selectedControlColor] colorWithAlphaComponent:0.4] set];
        [[NSBezierPath bezierPathWithRect:[self selectedRect]] fill];
        [[NSColor selectedControlColor] set];
        [[NSBezierPath bezierPathWithRect:[self selectedRect]] stroke];        
    }

	[shadow release];
	[noShadow release];
}

- (void)drawGrid  
{
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSBezierPath *gridPath = [[NSBezierPath alloc] init];
		
	// Verticale gridlijnen
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	start = -[self origin].x/stepInPixels;
	end = start + [self frame].size.width/stepInPixels+1;
	for (i=start; i <= end; i++) {
		[gridPath moveToPoint:NSMakePoint(i*stepInPixels+[self origin].x,0.)];
		[gridPath lineToPoint:NSMakePoint(i*stepInPixels+[self origin].x,[self frame].size.height)];
	}
	
	// En de horizontale gridlijnen
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
	
	start = -[self origin].y/stepInPixels;
	end = start + [self frame].size.height/stepInPixels +1;
	for (i=start; i <= end; i++) {
		[gridPath moveToPoint:NSMakePoint(0.,i*stepInPixels+[self origin].y)];
		[gridPath lineToPoint:NSMakePoint([self frame].size.width, i*stepInPixels+[self origin].y)];
	}	
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[gridPath setLineWidth:0.5];
	[[NSColor gridColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[gridPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [gridPath release];
}

- (void)drawMinorTickMarks  
{
	int i, start, end;
	float stepInUnits, stepInPixels;
	float tickMarksWidth = 2.5;
	int tickMarksPerUnit = 5;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	start = (-[self origin].x/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.width/stepInPixels)*tickMarksPerUnit+1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
	
	start = (-[self origin].y/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.height/stepInPixels)*tickMarksPerUnit +1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint([self origin].x,i*stepInPixels/tickMarksPerUnit+[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint([self origin].x+tickMarksWidth, i*stepInPixels/tickMarksPerUnit+[self origin].y)];
	}	
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:.5];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMajorTickMarks  
{
	int i, start, end;
	float stepInUnits, stepInPixels;
	float tickMarksWidth = 5.0;
	int tickMarksPerUnit = 1;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	start = (-[self origin].x/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.width/stepInPixels)*tickMarksPerUnit+1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
	
	start = (-[self origin].y/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.height/stepInPixels)*tickMarksPerUnit +1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint([self origin].x,i*stepInPixels/tickMarksPerUnit+[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint([self origin].x+tickMarksWidth, i*stepInPixels/tickMarksPerUnit+[self origin].y)];
	}	
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:.5];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMinorTickMarksOnFrame
{
	int i, start, end;
	float stepInUnits, stepInPixels;
	float tickMarksWidth = 2.5;
	int tickMarksPerUnit = 5;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	start = (([self plottingArea].origin.x-[self origin].x)/stepInPixels)*tickMarksPerUnit;
	end = start + ([self plottingArea].size.width/stepInPixels)*tickMarksPerUnit;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self plottingArea].origin.y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self plottingArea].origin.y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
	
	start = (([self plottingArea].origin.y-[self origin].y)/stepInPixels)*tickMarksPerUnit;
	end = start + ([self plottingArea].size.height/stepInPixels)*tickMarksPerUnit;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint([self plottingArea].origin.x,i*stepInPixels/tickMarksPerUnit+[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint([self plottingArea].origin.x+tickMarksWidth, i*stepInPixels/tickMarksPerUnit+[self origin].y)];
	}	
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:.5];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMajorTickMarksOnFrame
{
	int i, start, end;
	float stepInUnits, stepInPixels;
	float tickMarksWidth = 5.0;
	int tickMarksPerUnit = 1;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	start = (([self plottingArea].origin.x-[self origin].x)/stepInPixels)*tickMarksPerUnit;
	end = start + ([self plottingArea].size.width/stepInPixels)*tickMarksPerUnit;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self plottingArea].origin.y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self plottingArea].origin.y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
	
	start = (([self plottingArea].origin.y-[self origin].y)/stepInPixels)*tickMarksPerUnit;
	end = start + ([self plottingArea].size.height/stepInPixels)*tickMarksPerUnit;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint([self plottingArea].origin.x,i*stepInPixels/tickMarksPerUnit+[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint([self plottingArea].origin.x+tickMarksWidth, i*stepInPixels/tickMarksPerUnit+[self origin].y)];
	}	
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:.5];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawLegend  
{
	unsigned int i;
	NSMutableAttributedString *string; // = [[NSMutableAttributedString alloc] init];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSSize stringSize;
	NSPoint pointToDraw;

	// Fancy schaduw effecten...
	NSShadow *noShadow = [[NSShadow alloc] init];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:10];
	[shadow setShadowOffset:NSMakeSize(6,-6)];
	
	// Achtergrondkleur legendArea (met schaduw)
	[shadow set]; 	
	[[self legendAreaColor] setFill];
	[[NSBezierPath bezierPathWithRect:[self legendArea]] fill];

	[noShadow set];

    // Draw inside the legendArea
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self legendArea]] addClip];
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    NSBezierPath *line = [NSBezierPath bezierPath];
		
	if ([[self dataSeries] count] > 0) {
		for (i=0;i<[[self dataSeries] count]; i++) {
            [line removeAllPoints];
			string = [[NSMutableAttributedString alloc] initWithString:[[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesTitle"] attributes:attrs];
			stringSize = [string size];
			pointToDraw = [self legendArea].origin;
			pointToDraw.x = pointToDraw.x + 24;
			pointToDraw.y = pointToDraw.y - stringSize.height*(i+1) + [self legendArea].size.height - (4*i) - 4;
//			if ([[dataSeriesContainer selectionIndexes] containsIndex:i]) {
//				[[NSColor selectedMenuItemColor] set];
//				[[NSBezierPath bezierPathWithRect:NSMakeRect(pointToDraw.x-4, pointToDraw.y-4,[self legendArea].size.width, stringSize.height+8)] fill];
//			}
			[string drawAtPoint:pointToDraw];
			[string release];
    
            [[[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesColor"] set];
            [line moveToPoint:NSMakePoint(pointToDraw.x-20,pointToDraw.y+stringSize.height/2)];
            [line lineToPoint:NSMakePoint(pointToDraw.x-4,pointToDraw.y+stringSize.height/2)];
			[line stroke];
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];

	// Frame om legendArea
	[[self legendFrameColor] setStroke];
	[[NSBezierPath bezierPathWithRect:[self legendArea]] stroke];
	
	// Cleaning up
	[noShadow release];
	[shadow release];
}

- (void)drawTitles  
{
	
	// Werkt, maar nu niet direct een schoonheidsprijs waard!! ;-)
	[[self titleString] drawAtPoint:NSMakePoint(([self bounds].size.width - [[self titleString] size].width)/2,([self bounds].size.height - NSMaxY([self plottingArea]))/2 - [[self titleString] size].height/2 + NSMaxY([self plottingArea]))];
	if ([self shouldDrawLabelsOnFrame]) {
		[[self xAxisLabelString] drawAtPoint:NSMakePoint(NSMaxX([self plottingArea])-[[self xAxisLabelString] size].width,NSMinY([self plottingArea])-[[self xAxisLabelString] size].height-20)];
	} else {
		[[self xAxisLabelString] drawAtPoint:NSMakePoint(NSMaxX([self plottingArea])-[[self xAxisLabelString] size].width,NSMinY([self plottingArea])-[[self xAxisLabelString] size].height)];
	}
	
	// Y axis label
	[NSGraphicsContext saveGraphicsState];	

	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:90.0];
    [transform concat];
	if ([self shouldDrawLabelsOnFrame]) {
		[[self yAxisLabelString] drawAtPoint:NSMakePoint(NSMaxY([self plottingArea])-[[self yAxisLabelString] size].width,-NSMinX([self plottingArea])+20)]; // i.p.v. 20 eigenlijk liever grootte van labels on frame + 4
	} else {
		[[self yAxisLabelString] drawAtPoint:NSMakePoint(NSMaxY([self plottingArea])-[[self yAxisLabelString] size].width,-NSMinX([self plottingArea]))];
	}

	[NSGraphicsContext restoreGraphicsState];
	
}

- (void)drawLabels  
{
	NSMutableAttributedString *string;// = [[NSMutableAttributedString alloc] init];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%g";
	NSMutableString *label;
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    [attrs2 setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
    [attrs2 setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];
    
	// Labels op X-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	
	// Nog in te voegen: waarden groter dan 1E6 met notatie 1,0 x 10^6  en hetzelfde voor waarden kleiner dan 1E-6.
	// Nul moet altijd gewoon "0" zijn.
	// Als we ver van de oorspong gaan, dan moeten de waarden ook anders genoteerd worden, 1,10,100,1000,1e4 1,0001e4,1,0002e4 of 10.001, 10.002, of toch niet?!
	// Duizendtal markers
	
	start = -[self origin].x/stepInPixels;
	end = start + [self frame].size.width/stepInPixels+1;
	for (i=start; i <= end; i++) {
        label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
        if ([label rangeOfString:@"e"].location != NSNotFound) {
            [label replaceOccurrencesOfString:@"e+0" withString:@"e" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e-0" withString:@"e-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e" withString:[NSString stringWithUTF8String:"\u22c510"] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];                
            [label replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs]; 
            NSRange tenRange = [label rangeOfString:[NSString stringWithUTF8String:"\u22c510"]];
            NSRange superRange = NSMakeRange(tenRange.location+tenRange.length, [label length]-tenRange.location-tenRange.length);
            [string setAttributes:attrs2 range:superRange];
        } else {
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs];            
        }
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(i*stepInUnits,0.)];
		pointToDraw.x = pointToDraw.x - stringSize.width/2;
		pointToDraw.y = pointToDraw.y - stringSize.height - 4;
		[string drawAtPoint:pointToDraw];
		[string release];
        // Ugly fix for overlap
        if (stringSize.width > stepInPixels) {
            i++;
        }
        
	}

	// Labels op Y-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];

	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	
	start = -[self origin].y/stepInPixels;
	end = start + [self frame].size.height/stepInPixels+1;
	for (i=start; i <= end; i++) {
        label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
        if ([label rangeOfString:@"e"].location != NSNotFound) {
            [label replaceOccurrencesOfString:@"e+0" withString:@"e" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e-0" withString:@"e-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e" withString:[NSString stringWithUTF8String:"\u22c510"] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];                
            [label replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs]; 
            NSRange tenRange = [label rangeOfString:[NSString stringWithUTF8String:"\u22c510"]];
            NSRange superRange = NSMakeRange(tenRange.location+tenRange.length, [label length]-tenRange.location-tenRange.length);
            [string setAttributes:attrs2 range:superRange];
        } else {
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs];            
        }
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(0.,i*stepInUnits)];
		pointToDraw.x = pointToDraw.x - stringSize.width - 4;
		pointToDraw.y = pointToDraw.y - stringSize.height/2;
		[string drawAtPoint:pointToDraw];
		[string release];
        // Ugly fix for overlap
        if (stringSize.width > stepInPixels) {
            i++;
        }
        
	}
}

- (void)drawLabelsOnFrame  
{
	NSMutableAttributedString *string;// = [[NSMutableAttributedString alloc] init];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%g";
	NSMutableString *label;
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
    [attrs2 setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
    [attrs2 setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];

	// Labels op X-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
	
	// Nog in te voegen: waarden groter dan 1E6 met notatie 1,0 x 10^6  en hetzelfde voor waarden kleiner dan 1E-6.
	// Nul moet altijd gewoon "0" zijn. Of de "O" in italics van Oorsprong/Origin.
	// Als we ver van de oorspong gaan, dan moeten de waarden ook anders genoteerd worden, 1,10,100,1000,1e4 1,0001e4,1,0002e4 of 10.001, 10.002, of toch niet?!
	// Duizendtal markers

	start = ceil((-[self origin].x + [self plottingArea].origin.x)/stepInPixels);
	end = floor((-[self origin].x + [self plottingArea].origin.x + [self plottingArea].size.width)/stepInPixels);
	for (i=start; i <= end; i++) {  
        label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
        if ([label rangeOfString:@"e"].location != NSNotFound) {
            [label replaceOccurrencesOfString:@"e+0" withString:@"e" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e-0" withString:@"e-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e" withString:[NSString stringWithUTF8String:"\u22c510"] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];                
            [label replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs]; 
            NSRange tenRange = [label rangeOfString:[NSString stringWithUTF8String:"\u22c510"]];
            NSRange superRange = NSMakeRange(tenRange.location+tenRange.length, [label length]-tenRange.location-tenRange.length);
            [string setAttributes:attrs2 range:superRange];
        } else {
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs];            
        }
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(i*stepInUnits,0.)];
		pointToDraw.x = pointToDraw.x - stringSize.width/2;
		pointToDraw.y = [self plottingArea].origin.y - stringSize.height - 4;
		[string drawAtPoint:pointToDraw];
		[string release];
        // Ugly fix for overlap
        if (stringSize.width > stepInPixels) {
            i++;
        }
	}
	
	// Labels op Y-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
		
	start = ceil((-[self origin].y + [self plottingArea].origin.y)/stepInPixels);
	end = floor((-[self origin].y + [self plottingArea].origin.y + [self plottingArea].size.height)/stepInPixels);
	for (i=start; i <= end; i++) {
        label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
        if ([label rangeOfString:@"e"].location != NSNotFound) {
            [label replaceOccurrencesOfString:@"e+0" withString:@"e" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e-0" withString:@"e-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            [label replaceOccurrencesOfString:@"e" withString:[NSString stringWithUTF8String:"\u22c510"] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];                
            [label replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs]; 
            NSRange tenRange = [label rangeOfString:[NSString stringWithUTF8String:"\u22c510"]];
            NSRange superRange = NSMakeRange(tenRange.location+tenRange.length, [label length]-tenRange.location-tenRange.length);
            [string setAttributes:attrs2 range:superRange];
        } else {
            string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs];            
        }
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(0.,i*stepInUnits)];
		pointToDraw.x = [self plottingArea].origin.x - stringSize.width - 4;
		pointToDraw.y = pointToDraw.y - stringSize.height/2;
		[string drawAtPoint:pointToDraw];
		[string release];
        // Ugly fix for overlap
        if (stringSize.height > stepInPixels) {
            i++;
        }
        
	}
}

- (void)drawAxes  
{
	NSBezierPath *axesPath = [[NSBezierPath alloc] init];
	
	// De X as.
    [axesPath moveToPoint:NSMakePoint(0.,[self origin].y)];
    [axesPath lineToPoint:NSMakePoint([self frame].size.width,[self origin].y)];
	
	// En de Y as.
    [axesPath moveToPoint:NSMakePoint([self origin].x,0.)];
    [axesPath lineToPoint:NSMakePoint([self origin].x,[self frame].size.height)];

	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[axesPath setLineWidth:1.0];
	[[NSColor blackColor] set];

	// Met stroke wordt de bezierpath getekend.
	[axesPath stroke];

	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [axesPath release];
}

- (void)drawFrame
{
    NSBezierPath *framesPath = [[NSBezierPath alloc] init];
	
	// De X as.
    [framesPath moveToPoint:[self plottingArea].origin];
    [framesPath lineToPoint:NSMakePoint([self plottingArea].origin.x+[self plottingArea].size.width,[self plottingArea].origin.y)];
	
	// En de Y as.
    [framesPath moveToPoint:[self plottingArea].origin];
    [framesPath lineToPoint:NSMakePoint([self plottingArea].origin.x,[self plottingArea].origin.y+[self plottingArea].size.height)];
    
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[framesPath setLineWidth:1.0];
	[[NSColor blackColor] set];
    
	// Met stroke wordt de bezierpath getekend.
	[framesPath stroke];
    
	// We hebben framesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [framesPath release];    
}

// Additions for Peacock
- (void)drawBaseline  
{
	int i, count, count2;
	count2 = 0;
	NSBezierPath *baselinePath = [[NSBezierPath alloc] init];
	NSPoint pointToDraw;
	NSMutableArray *baselinePoints;
	NSArray *baselinePointsSelected = [NSArray array];
	
	baselinePoints = [self baseline];
	count = [baselinePoints count];
	if ([baselineContainer selectionIndexes]) {
		baselinePointsSelected = [[self baseline] objectsAtIndexes:[baselineContainer selectionIndexes]];
		count2 = [baselinePointsSelected count];
	}
	
    // Draw inside the legendArea
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
	
	// De baseline.

	if (count > 0) {
		pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:0] valueForKey:@"Scan"] floatValue],[[[baselinePoints objectAtIndex:0] valueForKey:@"Total Intensity"] floatValue]);
		[baselinePath moveToPoint:[[self transformGraphToScreen] transformPoint:pointToDraw]];  	
		for (i=1;i<count; i++) {
			pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] floatValue],[[[baselinePoints objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
			[baselinePath lineToPoint:[[self transformGraphToScreen] transformPoint:pointToDraw]];			
		}
	}

	if (count2 > 0) {
		for (i=0;i<count2; i++) {
			pointToDraw = NSMakePoint([[[baselinePointsSelected objectAtIndex:i] valueForKey:@"Scan"] floatValue],[[[baselinePointsSelected objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
			pointToDraw = [[self transformGraphToScreen] transformPoint:pointToDraw];
			[baselinePath appendBezierPathWithRect:NSMakeRect(pointToDraw.x-2.5,pointToDraw.y-2.5,5.0,5.0)];			
		}
	}
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[baselinePath setLineWidth:1.0];
	[[NSColor greenColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[baselinePath stroke];
	
	[NSGraphicsContext restoreGraphicsState];
	[baselinePath release];
}


- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)tag
             point:(NSPoint)point
          userData:(void *)userData
{
	id peak = [[self peaks] objectAtIndex:(int)userData];
	return [NSString stringWithFormat:NSLocalizedString(@"Peak no. %d\n%@",@"Tiptool for peak number and label."), userData+1, [peak valueForKey:@"label"]];
}

- (void)refresh  
{
//	JKLogDebug(@"Refresh - %@",[self description]);
    [self setNeedsDisplay:YES];
}

#pragma mark ACTION ROUTINES
- (void)centerOrigin:(id)sender  
{
	NSPoint newOrigin;
	NSRect theFrame;
	theFrame = [self plottingArea];
	newOrigin.x = theFrame.origin.x + theFrame.size.width/2;
	newOrigin.y = theFrame.origin.y + theFrame.size.height/2;	
    [self setOrigin:newOrigin];
}
- (void)lowerLeftOrigin:(id)sender  
{
    [self setOrigin:[self plottingArea].origin];
}
- (void)squareAxes:(id)sender  
{
	float x,y,avg;
	x = [[self pixelsPerXUnit] floatValue];
	y = [[self pixelsPerYUnit] floatValue];
	avg = (x+y)/2;
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:avg]];
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:avg]];
}
- (void)showAll:(id)sender  
{
	int i, count;
	NSRect totRect, newRect;
	MyGraphDataSerie *mgds;
	
	// Voor iedere dataserie wordt de grootte in grafiek-coordinaten opgevraagd en de totaal omvattende rect bepaald
	count = [[self dataSeries] count];
	for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
		newRect = [mgds boundingRect];
        // A little exta room to make room for labels
        if ([mgds isKindOfClass:[ChromatogramGraphDataSerie class]]) {
            newRect.size.height = newRect.size.height*1.4;
        } else if ([mgds isKindOfClass:[SpectrumGraphDataSerie class]]) {
            newRect.size.height = newRect.size.height*1.3;
            if (newRect.origin.y < 0.0) {
                newRect.origin.y = newRect.origin.y * 1.3;
            }
        }
		totRect = NSUnionRect(totRect, newRect);
	}
    
    
	[self zoomToRect:totRect];
}
- (void)showMagnifyingGlass:(NSEvent *)theEvent  
{
	NSPoint mouseLocation = [theEvent locationInWindow];
		NSWindow *magnifyingGlassWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(mouseLocation.x,mouseLocation.y-250,250,250) styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
    [magnifyingGlassWindow setBackgroundColor: [NSColor clearColor]];
    [magnifyingGlassWindow setLevel: NSTornOffMenuWindowLevel];
    [magnifyingGlassWindow setAlphaValue:1.0];
    [magnifyingGlassWindow setOpaque:YES];
    [magnifyingGlassWindow setHasShadow: YES];
		
//	NSImageView *magnifiedView = [[NSImageView alloc] initWithFrame:[magnifyingGlassWindow frame]];
//	NSImage *magnifiedImage = [[NSImage alloc] init];
	
	MyGraphView *aView = [[MyGraphView alloc] init];
	[magnifyingGlassWindow setContentView:aView];
	[aView lockFocus];
		// In plaats van een loop kunnen we ook deze convenient method gebruiken om iedere dataserie zich te laten tekenen.
	[[self dataSeries] makeObjectsPerformSelector:@selector(plotDataWithTransform:) withObject:[self transformGraphToScreen]];
	[aView unlockFocus];
//	[magnifiedImage addRepresentation:[NSPDFImageRep imageRepWithData:[self dataWithPDFInsideRect:[magnifyingGlassWindow frame]]]];
//	[magnifiedView setImage:magnifiedImage];
	[[self window] addChildWindow:magnifyingGlassWindow ordered:NSWindowAbove];
	[magnifyingGlassWindow orderFront:self];
}

#pragma mark HELPER ROUTINES
- (void)calculateCoordinateConversions  
{
	NSAffineTransform *translationMatrix, *scalingMatrix, *transformationMatrix, *invertMatrix;
	
	// We rekenen eerst in twee aparte matrices uit hoe de verplaatsing en schaling gedaan moet worden.
	
	// Als de oorsprong elders ligt, moeten we daarvoor corrigeren.
    translationMatrix = [NSAffineTransform transform];
    [translationMatrix translateXBy:[self origin].x yBy:[self origin].y];
	
	// De waarden omrekeningen naar pixels op het scherm.
     scalingMatrix = [NSAffineTransform transform];
//	 NSAssert([[self pixelsPerXUnit] floatValue] > 0, @"pixelsPerXUnit = 0");
//	 NSAssert([[self pixelsPerYUnit] floatValue] > 0, @"pixelsPerYUnit = 0");
    [scalingMatrix scaleXBy:[[self pixelsPerXUnit] floatValue] yBy:[[self pixelsPerYUnit] floatValue]];
	
	// In transformationMatrix combineren we de matrices. Eerst de verplaatsing, dan schalen.
    transformationMatrix = [NSAffineTransform transform];
    [transformationMatrix appendTransform:scalingMatrix];
    [transformationMatrix appendTransform:translationMatrix];
    [self setTransformGraphToScreen:transformationMatrix];
    
	// We zullen ook terug van data serie coördinaten naar scherm-coördinaten willen rekenen. Het zou niet effectief zijn om dat iedere keer dat we dit nodig hebben de inverse matrix uit te rekenen. Daarom hier één keer en vervolgens bewaren.
    invertMatrix = [[transformationMatrix copy] autorelease];
    [invertMatrix invert];
    [self setTransformScreenToGraph:invertMatrix];
	
}

- (float)unitsPerMajorGridLine:(float)pixelsPerUnit  
{
	float amountAtMinimum, orderOfMagnitude, fraction;
	
	amountAtMinimum = [[self minimumPixelsPerMajorGridLine] floatValue]/pixelsPerUnit;	
	orderOfMagnitude = floor(log10(amountAtMinimum));
	fraction = amountAtMinimum / pow(10.0, orderOfMagnitude);
	
	if (fraction <= 2) {
		return 2 * pow(10.0, orderOfMagnitude);
	} else if (fraction <= 5) {
		return 5 * pow(10.0, orderOfMagnitude);
	} else {
		return 10 * pow(10.0, orderOfMagnitude);
	}
}

- (void)zoomToRect:(NSRect)aRect { // aRect in grafiek coördinaten
	NSPoint newOrig;

	[self setPixelsPerXUnit:[NSNumber numberWithFloat:(([self plottingArea].size.width  )/aRect.size.width)]];
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:(([self plottingArea].size.height )/aRect.size.height)]];

	newOrig.x = [self plottingArea].origin.x - aRect.origin.x * [[self pixelsPerXUnit] floatValue];
	newOrig.y = [self plottingArea].origin.y - aRect.origin.y * [[self pixelsPerYUnit] floatValue];
	[self setOrigin:newOrig];
	[self calculateCoordinateConversions];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];
}

- (void)zoomToRectInView:(NSRect)aRect { // aRect in view coördinaten
	NSRect newRect;
		
	newRect.origin = [[self transformScreenToGraph] transformPoint:aRect.origin];
	newRect.size = [[self transformScreenToGraph] transformSize:aRect.size];
	JKLogDebug(@"zoomToRectInView x %f, y %f, w %f, h %f",newRect.origin.x, newRect.origin.y, newRect.size.width, newRect.size.height);
	[self zoomToRect:newRect];

}

- (void)zoomIn
{
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] - xWidth/8]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] + xWidth/8]];
	
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] - yWidth/8]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] + yWidth/8]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)zoomOut  
{
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - xWidth/4]];
	
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] - yWidth/4]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)moveLeft  
{
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] - xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - xWidth/4]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)moveRight  
{
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] + xWidth/4]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)moveUp  
{
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] + yWidth/4]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)moveDown  
{
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] - yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] - yWidth/4]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"MyGraphViewSynchronizedZooming" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:[self xMinimum], @"newXMinimum", [self xMaximum], @"newXMaximum", nil]];

}

- (void)selectNextPeak  
{
    // deselect any baseline points
    [baselineContainer setSelectedObjects:nil];
	if (([peaksContainer selectionIndex] != NSNotFound) & ([peaksContainer selectionIndex] != [[self peaks] count]-1)) {
		[peaksContainer setSelectionIndex:[peaksContainer selectionIndex]+1];		
	} else {
		[peaksContainer setSelectionIndex:0];			
	}
	[self setNeedsDisplay:YES];
}

- (void)selectPreviousPeak  
{
    // deselect any baseline points
    [baselineContainer setSelectedObjects:nil];
	if (([peaksContainer selectionIndex] != NSNotFound) & ([peaksContainer selectionIndex] != 0)) {
		[peaksContainer setSelectionIndex:[peaksContainer selectionIndex]-1];
	} else {
		[peaksContainer setSelectionIndex:[[self peaks] count]-1];
	}
	[self setNeedsDisplay:YES];
}

- (void)selectNextScan  
{
    [self setSelectedScan:[self selectedScan]+1];
    if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
        [delegate showSpectrumForScan:[self selectedScan]];
    }     
	[self setNeedsDisplay:YES];
}

- (void)selectPreviousScan  
{
    [self setSelectedScan:[self selectedScan]-1];
    if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
        [delegate showSpectrumForScan:[self selectedScan]];
    }     
	[self setNeedsDisplay:YES];
}

- (void)moveUpwardsInComparisonView
{
	NSArray *subviews = [[self superview] subviews];
	if ([subviews count] == 1) {
		return;
	}	
	
	NSRect oldFrame = [self frame];
	NSRect newFrame = [self frame];
	newFrame.origin.y = newFrame.origin.y + 200;
	
	if (newFrame.origin.y == [[self superview] frame].size.height) {
		NSBeep();
		return;
	}
	
	NSEnumerator *enumerator = [subviews objectEnumerator];
	NSView *object;
	NSView *subview;
	
	while ((object = [enumerator nextObject])) {
		if ([object frame].origin.y == newFrame.origin.y) {
			subview = object;
		}
	}
	
	NSDictionary *animationForOtherView = [NSDictionary dictionaryWithObjectsAndKeys:subview, NSViewAnimationTargetKey, [NSValue valueWithRect:newFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:oldFrame], NSViewAnimationEndFrameKey, nil];
	NSDictionary *animationForThisView = [NSDictionary dictionaryWithObjectsAndKeys:self, NSViewAnimationTargetKey, [NSValue valueWithRect:oldFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey, nil];
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationForOtherView, animationForThisView, nil]] autorelease];
	[animation startAnimation];
	[self scrollRectToVisible:newFrame];
}

- (void)moveDownwardsInComparisonView //WithAnimation
{
	NSArray *subviews = [[self superview] subviews];
	if ([subviews count] == 1) {
		return;
	}	
	
	NSRect oldFrame = [self frame];
	NSRect newFrame = [self frame];
	newFrame.origin.y = newFrame.origin.y - 200;
	
	if (oldFrame.origin.y == 0.0) {
		NSBeep();
		return;
	}
		
	NSEnumerator *enumerator = [subviews objectEnumerator];
	NSView *object;
	NSView *subview;
	
	while ((object = [enumerator nextObject])) {
		if ([object frame].origin.y == newFrame.origin.y) {
			subview = object;
		}
	}
	
	NSDictionary *animationForOtherView = [NSDictionary dictionaryWithObjectsAndKeys:subview, NSViewAnimationTargetKey, [NSValue valueWithRect:newFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:oldFrame], NSViewAnimationEndFrameKey, nil];
	NSDictionary *animationForThisView = [NSDictionary dictionaryWithObjectsAndKeys:self, NSViewAnimationTargetKey, [NSValue valueWithRect:oldFrame], NSViewAnimationStartFrameKey, [NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey, nil];
	NSViewAnimation *animation = [[[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObjects:animationForOtherView, animationForThisView, nil]] autorelease];
	[animation startAnimation];
	[self scrollRectToVisible:newFrame];
}

#pragma mark MOUSE INTERACTION MANAGEMENT
- (void)resetCursorRects  
{
	[self addCursorRect:[self frame] cursor:[NSCursor arrowCursor]];
	[self addCursorRect:[self plottingArea] cursor:[NSCursor crosshairCursor]];
	if (shouldDrawLegend) [self addCursorRect:[self legendArea] cursor:[NSCursor openHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent  
{
	_didDrag = NO;
	_mouseDownAtPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	_oldOrigin = [self origin];
	_oldLegendOrigin = [self legendArea].origin;
	_startedInsidePlottingArea = [self mouse:_mouseDownAtPoint inRect:[self plottingArea]];
	_startedInsideLegendArea = [self mouse:_mouseDownAtPoint inRect:[self legendArea]];

}

- (void)mouseDragged:(NSEvent *)theEvent  
{
	_didDrag = YES;
	NSRect draggedRect;
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
	if (_startedInsideLegendArea & shouldDrawLegend) {
		[[NSCursor closedHandCursor] set];
		NSPoint newOrigin;
		newOrigin.x = _oldLegendOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
		newOrigin.y = _oldLegendOrigin.y + (mouseLocation.y - _mouseDownAtPoint.y);
		NSRect legendRect;
		legendRect = [self legendArea];
		legendRect.origin = newOrigin;
		[self setLegendArea:legendRect];	
		[self setNeedsDisplay:YES];
	} else if (_startedInsidePlottingArea) {
		if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
			//   combine spectrum
			JKLogDebug(@"combine spectrum");
		} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			draggedRect.origin.x = (_mouseDownAtPoint.x < mouseLocation.x ? _mouseDownAtPoint.x : mouseLocation.x);
			draggedRect.origin.y = (_mouseDownAtPoint.y < mouseLocation.y ? _mouseDownAtPoint.y : mouseLocation.y);
			draggedRect.size.width = fabs(mouseLocation.x-_mouseDownAtPoint.x);
			draggedRect.size.height = fabs(mouseLocation.y-_mouseDownAtPoint.y);
			[self setSelectedRect:draggedRect];
			[self setNeedsDisplay:YES];
		} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
			//   select baseline points
			draggedRect.origin.x = (_mouseDownAtPoint.x < mouseLocation.x ? _mouseDownAtPoint.x : mouseLocation.x);
			draggedRect.origin.y = (_mouseDownAtPoint.y < mouseLocation.y ? _mouseDownAtPoint.y : mouseLocation.y);
			draggedRect.size.width = fabs(mouseLocation.x-_mouseDownAtPoint.x);
			draggedRect.size.height = fabs(mouseLocation.y-_mouseDownAtPoint.y);
			[self setSelectedRect:draggedRect];
			[self setNeedsDisplay:YES];
		} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
			//   move chromatogram
			JKLogDebug(@"move chromatogram");
				
		} else {
			[[NSCursor closedHandCursor] set];
			NSPoint newOrigin;
			newOrigin.x = _oldOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
			newOrigin.y = _oldOrigin.y + (mouseLocation.y - _mouseDownAtPoint.y);
			[self setOrigin:newOrigin];
		}		
	} else {
		if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			NSCursor *zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom_in"] hotSpot:NSMakePoint(10,12)];
			[zoomCursor set];
			[zoomCursor release];
			draggedRect.origin.x = (_mouseDownAtPoint.x < mouseLocation.x ? _mouseDownAtPoint.x : mouseLocation.x);
			draggedRect.origin.y = plottingArea.origin.y;
			draggedRect.size.width = fabs(mouseLocation.x-_mouseDownAtPoint.x);
			draggedRect.size.height = plottingArea.size.height;
			[self setSelectedRect:draggedRect];
			[self setNeedsDisplay:YES];
		} else {
			[[NSCursor closedHandCursor] set];
			NSPoint newOrigin;
			newOrigin.x = _oldOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
			newOrigin.y = _oldOrigin.y;
			[self setOrigin:newOrigin];
		}		
	}

}

- (void)mouseUp:(NSEvent *)theEvent  
{
	BOOL foundPeakToSelect = NO;
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (!_didDrag) {
		if ([theEvent clickCount] == 1) { // Single click
            if (([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSShiftKeyMask)) {
				[self zoomOut];
			} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
				[self zoomIn];
			} else if ([theEvent modifierFlags] & NSCommandKeyMask ) {
                // deselect any baseline points
                [baselineContainer setSelectedObjects:nil];
				//  select additional peak(/select baseline point/select scan)
				NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:mouseLocation];
				int i, peaksCount;
				peaksCount = [[self peaks] count];
				id peak;
				foundPeakToSelect = NO;

				for (i=0; i < peaksCount; i++) {
					peak = [[self peaks] objectAtIndex:i];
					if (([[peak valueForKey:@"start"] floatValue] < graphLocation.x) & ([[peak valueForKey:@"end"] floatValue] > graphLocation.x)) {
						[peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndex:i]];
						_lastSelectedPeakIndex = i;
						foundPeakToSelect = YES;
					} 
				}
				if (!foundPeakToSelect) {
					_lastSelectedPeakIndex = -1;
				}
				
			} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
                // deselect any baseline points
                [baselineContainer setSelectedObjects:nil];
				//  select series of peaks(/select baseline point/select scan)
				NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:mouseLocation];
				int i, peaksCount;
				peaksCount = [[self peaks] count];
				id peak;
				foundPeakToSelect = NO;
				
				for (i=0; i < peaksCount; i++) {
					peak = [[self peaks] objectAtIndex:i];
					if (([[peak valueForKey:@"start"] floatValue] < graphLocation.x) & ([[peak valueForKey:@"end"] floatValue] > graphLocation.x)) {
						if (_lastSelectedPeakIndex > 0 ) {
							if (_lastSelectedPeakIndex < i) {
								[peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_lastSelectedPeakIndex+1,i-_lastSelectedPeakIndex)]];
								_lastSelectedPeakIndex = i;
								foundPeakToSelect = YES;
							} else {
								[peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i,_lastSelectedPeakIndex-i)]];
								_lastSelectedPeakIndex = i;
								foundPeakToSelect = YES;
							}
						} else {
							[peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndex:i]];
							_lastSelectedPeakIndex = i;
							foundPeakToSelect = YES;
						}
					} 
				}
				if (!foundPeakToSelect) {
					_lastSelectedPeakIndex = -1;
				}
				
			} else {
                // deselect any baseline points
                [baselineContainer setSelectedObjects:nil];

				//  select peak(/select baseline point/select scan)
				NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:mouseLocation];
				int i, peaksCount;
				peaksCount = [[self peaks] count];
				id peak;
				foundPeakToSelect = NO;

				for (i=0; i < peaksCount; i++) {
					peak = [[self peaks] objectAtIndex:i];
					if (([[peak valueForKey:@"start"] floatValue] < graphLocation.x) & ([[peak valueForKey:@"end"] floatValue] > graphLocation.x)) {
						[peaksContainer setSelectionIndexes:[NSIndexSet indexSetWithIndex:i]];
						_lastSelectedPeakIndex = i;
						foundPeakToSelect = YES;
					} 
				}
				if (!foundPeakToSelect) {
					_lastSelectedPeakIndex = -1;
				}
				
			}
		} else if ([theEvent clickCount] == 2) { // Float click
            if (([theEvent modifierFlags] & NSShiftKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
				[self showAll:self];
			} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
				//  add peak
				JKLogDebug(@"add peak");
			} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
                // deselect any peaks
                [peaksContainer setSelectedObjects:nil];
				//  add baseline point
				int i;
				NSPoint pointInReal = [[self transformScreenToGraph] transformPoint:mouseLocation];
				
				NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
				[mutDict setValue:[NSNumber numberWithFloat:pointInReal.x] forKey:@"Scan"];
				[mutDict setValue:[NSNumber numberWithFloat:pointInReal.y] forKey:@"Total Intensity"];
				// Time?!
                
                
				// Following works, but can fail in circumstances, need error checking!
				// if count 0 addObject
				i=0;
				while (pointInReal.x > [[[[self baseline] objectAtIndex:i] valueForKey:@"Scan"] intValue]) {
					i++;
				}
				// if i == count addObject
                [[self undoManager] registerUndoWithTarget:[self baselineContainer]
                                                  selector:@selector(removeObject:)
                                                    object:mutDict];
                [[self undoManager] setActionName:NSLocalizedString(@"Add Baseline Point",@"")];
                
				[(NSArrayController *)[self  baselineContainer] insertObject:mutDict atArrangedObjectIndex:i];
				[mutDict release];
			} else {
				//  select scan and show spectrum 
				JKLogDebug(@" select scan and show spectrum");
                if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
                    NSPoint pointInReal = [[self transformScreenToGraph] transformPoint:mouseLocation];
                    [self setSelectedScan:lroundf(pointInReal.x)];
                    [delegate showSpectrumForScan:[self selectedScan]];
                } 
            }
		} else {
			NSBeep();
		}
	} else if (_didDrag) {
		if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
			//   combine spectrum
			JKLogDebug(@"combine spectrum");
		} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			//   zoom in/move baseline point
			[self zoomToRectInView:[self selectedRect]];
		} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
            // deselect any peaks
            [peaksContainer setSelectedObjects:nil];
			//  select baselinpoints
            int i;
            float scanValue, intensityValue;
            NSPoint startPoint = [[self transformScreenToGraph] transformPoint:[self selectedRect].origin];
            NSSize selectedSize = [[self transformScreenToGraph] transformSize:[self selectedRect].size];
            NSMutableArray *mutArray = [NSMutableArray array];
            int count = [[self baseline] count];
            for (i=0; i< count; i++) {
                scanValue = [[[[self baseline] objectAtIndex:i] valueForKey:@"Scan"] floatValue];
                intensityValue = [[[[self baseline] objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue];
                if ((scanValue > startPoint.x) && (scanValue < startPoint.x+selectedSize.width)) {
                    if ((intensityValue > startPoint.y) && (intensityValue < startPoint.y+selectedSize.height)) {
                        [mutArray addObject:[[self baseline] objectAtIndex:i]];
                    }
                }
            }
            
            [(NSArrayController *)[self  baselineContainer] setSelectedObjects:mutArray];
            
		} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
		} else {
			// move chromatogram
			// handled in mouseDragged
		}
	}
	
	[self setSelectedRect:NSMakeRect(0,0,0,0)];

	[[NSCursor crosshairCursor] set];
	
	_didDrag = NO;
	[self resetCursorRects];
	[self setNeedsDisplay:YES];
}

- (void)scrollWheel:(NSEvent *)theEvent {
    if ([theEvent deltaY] > 0) {
        [self zoomIn];        
    } else {
        [self zoomOut];
    }
}

#pragma mark KEYBOARD INTERACTION MANAGEMENT
- (void)flagsChanged:(NSEvent *)theEvent  
{
	BOOL isInsidePlottingArea;
	NSPoint mouseLocation = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView:nil];
	
	// Waar is de muis?
	isInsidePlottingArea = [self mouse:mouseLocation inRect:[self plottingArea]];
	
	if (!_didDrag){
		if (isInsidePlottingArea) {		
			if (([theEvent modifierFlags] & NSAlternateKeyMask ) && ([theEvent modifierFlags] & NSShiftKeyMask )) {
				NSCursor *zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom_out"] hotSpot:NSMakePoint(12,10)];
				[zoomCursor set];
				[zoomCursor release];
			} else if ([theEvent modifierFlags] & NSAlternateKeyMask ) {
				NSCursor *zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom_in"] hotSpot:NSMakePoint(12,10)];
				[zoomCursor set];
				[zoomCursor release];
			} else {
				[[NSCursor crosshairCursor] set];
			}
		}		
	}
}

- (void)keyDown:(NSEvent *)theEvent  
{
	if ([[theEvent characters] isEqualToString:@"a"]) {
		[self showAll:self];
	} else if ([[theEvent characters] isEqualToString:@"b"]) {
		shouldDrawBaseline ? [self setShouldDrawBaseline:NO] : [self setShouldDrawBaseline:YES];
	} else if ([[theEvent characters] isEqualToString:@"f"]) {
		shouldDrawFrame ? [self setShouldDrawFrame:NO] : [self setShouldDrawFrame:YES];
	} else if ([[theEvent characters] isEqualToString:@"g"]) {
		shouldDrawGrid ? [self setShouldDrawGrid:NO] : [self setShouldDrawGrid:YES];
	} else if ([[theEvent characters] isEqualToString:@"l"]) {
		shouldDrawLegend ? [self setShouldDrawLegend:NO] : [self setShouldDrawLegend:YES];
	} else if ([[theEvent characters] isEqualToString:@"m"]) {
		shouldDrawMajorTickMarks ? [self setShouldDrawMajorTickMarks:NO] : [self setShouldDrawMajorTickMarks:YES];
	} else if ([[theEvent characters] isEqualToString:@"n"]) {
		shouldDrawMinorTickMarks ? [self setShouldDrawMinorTickMarks:NO] : [self setShouldDrawMinorTickMarks:YES];
	} else if ([[theEvent characters] isEqualToString:@"p"]) {
		shouldDrawPeaks ? [self setShouldDrawPeaks:NO] : [self setShouldDrawPeaks:YES];
	} else if ([[theEvent characters] isEqualToString:@"x"]) {
		shouldDrawAxes ? [self setShouldDrawAxes:NO] : [self setShouldDrawAxes:YES];
	} else if ([[theEvent characters] isEqualToString:@"z"]) {
		[self zoomOut];
	} else {
		NSString *keyString = [theEvent charactersIgnoringModifiers];
		unichar   keyChar = [keyString characterAtIndex:0];
		switch (keyChar) {
			case NSLeftArrowFunctionKey:
				if ([theEvent modifierFlags] & NSAlternateKeyMask) {
					[self moveLeft];
				} else {
					[self selectPreviousScan];
				}
				break;
			case NSRightArrowFunctionKey:
				if ([theEvent modifierFlags] & NSAlternateKeyMask) {
					[self moveRight];
				} else {
					[self selectNextScan];
				}
				break;
			case NSUpArrowFunctionKey:
				if ([theEvent modifierFlags] & NSAlternateKeyMask) {
					[self moveUp];
				} else if ([theEvent modifierFlags] & NSControlKeyMask) {
					[self moveUpwardsInComparisonView];
				} else {
					[self selectPreviousPeak];
				}
				break;
			case NSDownArrowFunctionKey:
				if ([theEvent modifierFlags] & NSAlternateKeyMask) {
					[self moveDown];
				} else if ([theEvent modifierFlags] & NSControlKeyMask) {
					[self moveDownwardsInComparisonView];
				} else {
					[self selectNextPeak];
				}
				break;
			case 0177: // Delete Key
			case NSDeleteFunctionKey:
			case NSDeleteCharFunctionKey:
				//[[self baseline] removeObjectsAtIndexes:[baselineContainer selectionIndexes]];
				//[peaksContainer removeObjectsAtArrangedObjectIndexes:[peaksContainer selectionIndexes]];
				//[[self peaks] removeObjectsAtIndexes:[peaksContainer selectionIndexes]];
				[peaksContainer removeObjects:[peaksContainer selectedObjects]];
				[self setNeedsDisplay:YES];
				break;
			default:
				[super keyDown:theEvent];
		}
	}
}

- (BOOL)canBecomeKeyView  
{
	return YES;
}
- (BOOL) acceptsFirstResponder 
{
    return YES;
}
- (BOOL) resignFirstResponder 
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidResignFirstResponderNotification object:self];
	[self setNeedsDisplay:YES];
    return YES;
}
- (BOOL) becomeFirstResponder 
{
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidBecomeFirstResponderNotification object:self];
	[self setNeedsDisplay:YES];
    return YES;
}

- (void)copy:(id)sender  
{
    NSData *data;
    NSArray *myPboardTypes;
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    //Declare types of data you'll be putting onto the pasteboard
    myPboardTypes = [NSArray arrayWithObject:NSPDFPboardType];
    [pb declareTypes:myPboardTypes owner:self];
    //Copy the data to the pastboard
    data = [self dataWithPDFInsideRect:[self bounds]];
    [pb setData:data forType:NSPDFPboardType];
}

- (void)delete:(id)sender {
    [baselineContainer removeObjects:[baselineContainer selectedObjects]];
    [peaksContainer removeObjects:[peaksContainer selectedObjects]];

}


#pragma mark KEY VALUE OBSERVING MANAGEMENT

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context 
{
    if (context == PeaksObservationContext)
	{
		[self setNeedsDisplay:YES];
	}
	else if (context == DataObservationContext) 
	{
		int i, count;
		// Als de inhoud van onze dataArray wijzigt, bijv. als er een dataserie wordt toegevoegd, dan willen we ons registreren voor wijzingen die de dataserie post. Eerst verwijderen we onszelf voor alle notificaties, en daarna registreren we voor de op dit moment beschikbare dataseries. Dit is eenvoudiger (en waarschijnlijk sneller) dan uitzoeken wat er precies veranderd is. 
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"MyGraphDataSerieDidChangeNotification" object:nil];
		count = [[self dataSeries] count];
		for (i=0;i<count; i++){
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"MyGraphDataSerieDidChangeNotification" object:[[self dataSeries] objectAtIndex:i]];
		}
        [self setNeedsDisplay:YES];
    } 
    else if (context == DataSeriesObservationContext) 
	{
        // resize legend area to fit all entries
        NSRect newLegendArea = [self legendArea];
        newLegendArea.size.height = [[self dataSeries] count] * 18;
        newLegendArea.origin.y = newLegendArea.origin.y - (newLegendArea.size.height - [self legendArea].size.height);
        [self setLegendArea:newLegendArea];
        
		[self setNeedsDisplay:YES];
    } 
    else if (context == BaselineObservationContext) 
	{
		[self setNeedsDisplay:YES];
    } 

}


#pragma mark BINDINGS
- (void)bind:(NSString *)bindingName
    toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
     options:(NSDictionary *)options
{
	
    if ([bindingName isEqualToString:@"dataSeries"])
	{		
		[self setDataSeriesContainer:observableObject];
		[self setDataSeriesKeyPath:observableKeyPath];
		[dataSeriesContainer addObserver:self
							  forKeyPath:dataSeriesKeyPath
								 options:(NSKeyValueObservingOptionNew |
										  NSKeyValueObservingOptionOld)
								 context:DataSeriesObservationContext];
		//[self startObservingGraphics:[graphicsContainer valueForKeyPath:graphicsKeyPath]];
		
    }
	else if ([bindingName isEqualToString:@"peaks"])
	{
		[self setPeaksContainer:observableObject];
		[self setPeaksKeyPath:observableKeyPath];
		[peaksContainer addObserver:self
						 forKeyPath:peaksKeyPath
							options:nil
							context:PeaksObservationContext];
	}
	else if ([bindingName isEqualToString:@"baseline"])
	{
		[self setBaselineContainer:observableObject];
		[self setBaselineKeyPath:observableKeyPath];
		[baselineContainer addObserver:self
							forKeyPath:baselineKeyPath
							   options:nil
							   context:BaselineObservationContext];
	}
	
	[super bind:bindingName
	   toObject:observableObject
	withKeyPath:observableKeyPath
		options:options];
	
    [self setNeedsDisplay:YES];
}


- (void)unbind:(NSString *)bindingName  
{
	
    if ([bindingName isEqualToString:@"dataSeries"])
	{
		[dataSeriesContainer removeObserver:self forKeyPath:dataSeriesKeyPath];
		[self setDataSeriesContainer:nil];
		[self setDataSeriesKeyPath:nil];
    }
	else if ([bindingName isEqualToString:@"peaks"])
	{
		[peaksContainer removeObserver:self forKeyPath:peaksKeyPath];
		[self setPeaksContainer:nil];
		[self setPeaksKeyPath:nil];
	}
	else if ([bindingName isEqualToString:@"baseline"])
	{
		[baselineContainer removeObserver:self forKeyPath:baselineKeyPath];
		[self setBaselineContainer:nil];
		[self setBaselineKeyPath:nil];
	}
	
	[super unbind:bindingName];
	[self setNeedsDisplay:YES];
}

#pragma mark dataSeries bindings
- (NSMutableArray *)dataSeries
{	
    return [dataSeriesContainer valueForKeyPath:dataSeriesKeyPath];	
}
- (NSObject *)dataSeriesContainer
{
    return dataSeriesContainer; 
}
- (void)setDataSeriesContainer:(NSObject *)aDataSeriesContainer
{
    if (dataSeriesContainer != aDataSeriesContainer) {
        [dataSeriesContainer release];
        dataSeriesContainer = [aDataSeriesContainer retain];
    }
}
- (NSString *)dataSeriesKeyPath
{
    return dataSeriesKeyPath; 
}
- (void)setDataSeriesKeyPath:(NSString *)aDataSeriesKeyPath
{
    if (dataSeriesKeyPath != aDataSeriesKeyPath) {
        [dataSeriesKeyPath release];
        dataSeriesKeyPath = [aDataSeriesKeyPath copy];
    }
}


#pragma mark peaks bindings
- (NSMutableArray *)peaks
{
	return [peaksContainer valueForKeyPath:peaksKeyPath];
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

#pragma mark baseline bindings
- (NSMutableArray *)baseline
{
	return [baselineContainer valueForKeyPath:baselineKeyPath];
}
- (NSObject *)baselineContainer
{
    return baselineContainer; 
}
- (void)setBaselineContainer:(NSObject *)aBaselineContainer
{
    if (baselineContainer != aBaselineContainer) {
        [baselineContainer release];
        baselineContainer = [aBaselineContainer retain];
    }
}
- (NSString *)baselineKeyPath
{
    return baselineKeyPath; 
}
- (void)setBaselineKeyPath:(NSString *)aBaselineKeyPath
{
    if (baselineKeyPath != aBaselineKeyPath) {
        [baselineKeyPath release];
        baselineKeyPath = [aBaselineKeyPath copy];
    }
}

#pragma mark ACCESSORS

- (id)delegate  
{
	return delegate;
}
- (void)setDelegate:(id)inValue  
{
    if (delegate != inValue) {
        delegate = inValue;        
    }
}

-(void)setFrame:(NSRect)newFrect {
    NSRect oldFrect, pRect, lRect;
    oldFrect = [self frame];
    pRect = [self plottingArea];
    pRect.size.width = pRect.size.width + newFrect.size.width - oldFrect.size.width;
    pRect.size.height = pRect.size.height + newFrect.size.height - oldFrect.size.height;
    [self setPlottingArea:pRect];
    lRect = [self legendArea];
    lRect.origin.x = lRect.origin.x + newFrect.size.width - oldFrect.size.width;
    lRect.origin.y = lRect.origin.y + newFrect.size.height - oldFrect.size.height;
    [self setLegendArea:lRect];
    
    [super setFrame:newFrect];            
}

- (NSAffineTransform *)transformGraphToScreen 
{
	return transformGraphToScreen;
}
- (void)setTransformGraphToScreen:(NSAffineTransform *)inValue  
{
    if (transformGraphToScreen != inValue) {
        [inValue retain];
        [transformGraphToScreen autorelease];
        transformGraphToScreen = inValue;        
    }
}

- (NSAffineTransform *)transformScreenToGraph  
{
	return transformScreenToGraph;
}
- (void)setTransformScreenToGraph:(NSAffineTransform *)inValue  
{
    if (transformScreenToGraph != inValue) {
        [inValue retain];
        [transformScreenToGraph autorelease];
        transformScreenToGraph = inValue;
    }
}

- (NSNumber *)pixelsPerXUnit  
{
	return pixelsPerXUnit;
}
- (void)setPixelsPerXUnit:(NSNumber *)inValue  
{
	if (pixelsPerXUnit != inValue) {
        [inValue retain];
        [pixelsPerXUnit autorelease];
        pixelsPerXUnit = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSNumber *)pixelsPerYUnit  
{
	return pixelsPerYUnit;
}
- (void)setPixelsPerYUnit:(NSNumber *)inValue  
{
	if (pixelsPerYUnit != inValue) {
        [inValue retain];
        [pixelsPerYUnit autorelease];
        pixelsPerYUnit = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSNumber *)minimumPixelsPerMajorGridLine  
{
	return minimumPixelsPerMajorGridLine;
}
- (void)setMinimumPixelsPerMajorGridLine:(NSNumber *)inValue  
{
    if (minimumPixelsPerMajorGridLine != inValue) {
        if ([inValue floatValue] > 0.0f) {
            [inValue retain];
            [minimumPixelsPerMajorGridLine autorelease];
            minimumPixelsPerMajorGridLine = inValue;
            [self setNeedsDisplay:YES];
        }
    }
}

- (NSPoint)origin  
{
	return origin;
}
- (void)setOrigin:(NSPoint)inValue  
{
    origin = inValue;
    [self setNeedsDisplay:YES];        
}

- (NSRect)plottingArea  
{
	return plottingArea;
}
- (void)setPlottingArea:(NSRect)inValue  
{
    plottingArea = inValue;
    [self setNeedsDisplay:YES];        
}

- (NSRect)legendArea  
{
	return legendArea;
}
- (void)setLegendArea:(NSRect)inValue  
{
    NSRect unionRect = NSUnionRect(legendArea,inValue);
    legendArea = inValue;
    if ([self shouldDrawLegend])
        [self setNeedsDisplayInRect:unionRect];        
    
}

- (NSRect)selectedRect  
{
	return selectedRect;
}
- (void)setSelectedRect:(NSRect)inValue  
{
    NSRect unionRect = NSUnionRect(selectedRect,inValue);
    selectedRect = inValue;
    [self setNeedsDisplayInRect:unionRect];        
}

- (NSColor *)backColor  
{
    return backColor;
}
- (void)setBackColor:(NSColor *)inValue  
{
    if (backColor != inValue) {
        [inValue retain];
        [backColor autorelease];
        backColor = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSColor *)plottingAreaColor  
{
    return plottingAreaColor;
}
- (void)setPlottingAreaColor:(NSColor *)inValue  
{
    if (plottingAreaColor != inValue) {
        [inValue retain];
        [plottingAreaColor autorelease];
        plottingAreaColor = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)axesColor  
{
    return axesColor;
}
- (void)setAxesColor:(NSColor *)inValue  
{
    if (axesColor != inValue) {
        [inValue retain];
        [axesColor autorelease];
        axesColor = inValue;
        if ([self shouldDrawAxes])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)gridColor  
{
    return gridColor;
}
- (void)setGridColor:(NSColor *)inValue  
{
    if (gridColor != inValue) {
        [inValue retain];
        [gridColor autorelease];
        gridColor = inValue;
        if ([self shouldDrawGrid])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)labelsColor  
{
    return labelsColor;
}
- (void)setLabelsColor:(NSColor *)inValue  
{
    if (labelsColor != inValue) {
        [inValue retain];
        [labelsColor autorelease];
        labelsColor = inValue;
        if ([self shouldDrawLabels])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)labelsOnFrameColor  
{
    return labelsOnFrameColor;
}
- (void)setLabelsOnFrameColor:(NSColor *)inValue  
{
    if (labelsOnFrameColor != inValue) {
        [inValue retain];
        [labelsOnFrameColor autorelease];
        labelsOnFrameColor = inValue;
        if ([self shouldDrawLabelsOnFrame])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)frameColor  
{
    return frameColor;
}
- (void)setFrameColor:(NSColor *)inValue  
{
    if (frameColor != inValue) {
        [inValue retain];
        [frameColor autorelease];
        frameColor = inValue;
        if ([self shouldDrawFrame])
            [self setNeedsDisplay:YES];        
    }
}

- (NSColor *)legendAreaColor  
{
    return legendAreaColor;
}
- (void)setLegendAreaColor:(NSColor *)inValue  
{
    if (legendAreaColor != inValue) {
        [inValue retain];
        [legendAreaColor autorelease];
        legendAreaColor = inValue;
        if ([self shouldDrawLegend])
            [self setNeedsDisplayInRect:[self legendArea]];        
    }
}

- (NSColor *)legendFrameColor  
{
    return legendFrameColor;
}
- (void)setLegendFrameColor:(NSColor *)inValue  
{
    if (legendFrameColor != inValue) {
        [inValue retain];
        [legendFrameColor autorelease];
        legendFrameColor = inValue;
        if ([self shouldDrawLegend])
            [self setNeedsDisplayInRect:[self legendArea]];        
    }
}

- (BOOL)shouldDrawLegend  
{
    return shouldDrawLegend;
}
- (void)setShouldDrawLegend:(BOOL)inValue  
{
    if (shouldDrawLegend != inValue) {
        shouldDrawLegend = inValue;
        [self setNeedsDisplayInRect:[self legendArea]];        
    }    
}

- (BOOL)shouldDrawAxes  
{
    return shouldDrawAxes;
}
- (void)setShouldDrawAxes:(BOOL)inValue  
{
    if (shouldDrawAxes != inValue) {
        shouldDrawAxes = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawFrame  
{
    return shouldDrawFrame;
}
- (void)setShouldDrawFrame:(BOOL)inValue  
{
    if (shouldDrawFrame != inValue) {
        shouldDrawFrame = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawMajorTickMarks
{
	return shouldDrawMajorTickMarks;
}
- (void)setShouldDrawMajorTickMarks:(BOOL)inValue
{
	if (shouldDrawMajorTickMarks != inValue) {        
        shouldDrawMajorTickMarks = inValue;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)shouldDrawMinorTickMarks
{
	return shouldDrawMinorTickMarks;
}
- (void)setShouldDrawMinorTickMarks:(BOOL)inValue
{
    if (shouldDrawMinorTickMarks != inValue) {
        shouldDrawMinorTickMarks = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawGrid  
{
    return shouldDrawGrid;
}
- (void)setShouldDrawGrid:(BOOL)inValue  
{
    if (shouldDrawGrid != inValue) {
        shouldDrawGrid = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawLabels  
{
    return shouldDrawLabels;
}
- (void)setShouldDrawLabels:(BOOL)inValue  
{
    if (shouldDrawLabels != inValue) {
        shouldDrawLabels = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];    
    }
}

- (BOOL)shouldDrawLabelsOnFrame  
{
    return shouldDrawLabelsOnFrame;
}
- (void)setShouldDrawLabelsOnFrame:(BOOL)inValue  
{
    if (shouldDrawLabelsOnFrame != inValue) {
        shouldDrawLabelsOnFrame = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSAttributedString *)titleString  
{
    return titleString;
}
- (void)setTitleString:(NSAttributedString *)inValue  
{
    if (titleString != inValue) {
        [inValue retain];
        [titleString autorelease];
        titleString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSAttributedString *)xAxisLabelString  
{
    return xAxisLabelString;
}
- (void)setXAxisLabelString:(NSAttributedString *)inValue  
{
    if (xAxisLabelString != inValue) {
        [inValue retain];
        [xAxisLabelString autorelease];
        xAxisLabelString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSAttributedString *)yAxisLabelString  
{
    return yAxisLabelString;
}
- (void)setYAxisLabelString:(NSAttributedString *)inValue  
{
    if (yAxisLabelString != inValue) {
        [inValue retain];
        [yAxisLabelString autorelease];
        yAxisLabelString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSString *)keyForXValue  
{
	return keyForXValue;
}
- (void)setKeyForXValue:(NSString *)inValue  
{
	if (keyForXValue != inValue) {
        [inValue retain];
        [keyForXValue autorelease];
        keyForXValue = inValue;
        
        int i, count;
        count = [[self dataSeries] count];
        for (i=0; i<count; i++){
            [[[self dataSeries] objectAtIndex:i] setKeyForXValue:inValue];
            [[[self dataSeries] objectAtIndex:i] constructPlotPath];
        }    
        
        [self setNeedsDisplay:YES];        
    }
}

- (NSString *)keyForYValue  
{
	return keyForYValue;
}
- (void)setKeyForYValue:(NSString *)inValue  
{
	if (keyForYValue != inValue) {
        [inValue retain];
        [keyForYValue autorelease];
        keyForYValue = inValue;
        
        int i, count;
        count = [[self dataSeries] count];
        
        for (i=0;i<count; i++){
            [[[self dataSeries] objectAtIndex:i] setKeyForYValue:inValue];
            [[[self dataSeries] objectAtIndex:i] constructPlotPath];
        }
        
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawBaseline  
{
	return shouldDrawBaseline;
}
- (void)setShouldDrawBaseline:(BOOL)inValue  
{
    if (shouldDrawBaseline != inValue) {
        shouldDrawBaseline = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawPeaks  
{
	return shouldDrawPeaks;
}
- (void)setShouldDrawPeaks:(BOOL)inValue  
{
    if (shouldDrawPeaks != inValue) {
        shouldDrawPeaks = inValue;
        
        int i,count = [[self dataSeries] count];
        for (i=0; i <  count; i++) {
            [[[self dataSeries] objectAtIndex:i] setShouldDrawPeaks:inValue];
        }
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (int)selectedScan  
{
	return selectedScan;
}
- (void)setSelectedScan:(int)inValue  
{
    if (selectedScan != inValue) {
        selectedScan = inValue;
        [self setNeedsDisplay:YES];        
    }
}


#pragma mark CALCULATED ACCESSORS

- (NSNumber *)xMinimum  
{
	NSPoint plotCorner;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithFloat:plotCorner.x];
}
- (void)setXMinimum:(NSNumber *)inValue  
{
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:([self plottingArea].size.width)/([[self xMaximum] floatValue] - [inValue floatValue])]];
	
	newOrigin.x = [self plottingArea].origin.x - [inValue floatValue] * [[self pixelsPerXUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)xMaximum  
{
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	plotSize = [[self transformScreenToGraph] transformSize:[self plottingArea].size];
	return [NSNumber numberWithFloat:(plotCorner.x + plotSize.width)];	
}
- (void)setXMaximum:(NSNumber *)inValue  
{
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:([self plottingArea].size.width)/([inValue floatValue] - [[self xMinimum] floatValue])]];
	
	newOrigin.x = [self plottingArea].origin.x + [self plottingArea].size.width - [inValue floatValue] * [[self pixelsPerXUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
	
}

- (NSNumber *)yMinimum  
{
	NSPoint plotCorner;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithFloat:plotCorner.y];	
}
- (void)setYMinimum:(NSNumber *)inValue  
{
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:([self plottingArea].size.height)/([[self yMaximum] floatValue] - [inValue floatValue])]];
	
	newOrigin.y = [self plottingArea].origin.y - [inValue floatValue] * [[self pixelsPerYUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)yMaximum  
{
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	plotSize = [[self transformScreenToGraph] transformSize:[self plottingArea].size];
	return [NSNumber numberWithFloat:(plotCorner.y + plotSize.height)];	
}
- (void)setYMaximum:(NSNumber *)inValue 
{
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:([self plottingArea].size.height)/([inValue floatValue] - [[self yMinimum] floatValue])]];
	
	newOrigin.y = [self plottingArea].origin.y + [self plottingArea].size.height  - [inValue floatValue] * [[self pixelsPerYUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)unitsPerMajorX  
{
	float a,b;
	a = [[self pixelsPerXUnit] floatValue];
	b = [[self minimumPixelsPerMajorGridLine] floatValue];
	return [NSNumber numberWithFloat:a/b];
}

- (void)setUnitsPerMajorX:(NSNumber *)inValue  
{
}

- (NSNumber *)unitsPerMajorY  
{
	return [NSNumber numberWithInt:-1];
}

- (void)setUnitsPerMajorY:(NSNumber *)inValue  
{
}



@end

