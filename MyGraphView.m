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

static void *DataSeriesObservationContext = (void *)1092;
static void *PeaksObservationContext = (void *)1093;
static void *PropertyObservationContext = (void *)1094;
static void *FrameObservationContext = (void *)1095;
static void *DataObservationContext = (void *)1096;
static void *BaselineObservationContext = (void *)1097;
static void *DataSeriesSelectionIndexesObservationContext = (void *)1098;
static void *PeaksSelectionIndexesObservationContext = (void *)1099;
static void *BaselineSelectionIndexesObservationContext = (void *)1100;

NSString *const MyGraphView_DidBecomeFirstResponderNotification = @"MyGraphView_DidBecomeFirstResponderNotification"; 
NSString *const MyGraphView_DidResignFirstResponderNotification = @"MyGraphView_DidResignFirstResponderNotification";

@implementation MyGraphView

#pragma mark INITIALIZATION
+ (void)initialize 
{
	// Bindings support
	[self exposeBinding:@"dataSeries"];
	[self exposeBinding:@"dataSeriesSelectionIndexes"];
	
	[self exposeBinding:@"peaks"];
	[self exposeBinding:@"peaksSelectionIndexes"];
	
	[self exposeBinding:@"baseline"];
	[self exposeBinding:@"baselineSelectionIndexes"];
	
	// Dependent keys
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMaximum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMaximum"];	
}

- (NSArray *)exposedBindings 
{
	return [NSArray arrayWithObjects:@"dataSeries",@"dataSeriesSelectionIndexes", @"peaks", @"peaksSelectionIndexes", @"baseline", @"baselineSelectionIndexes", nil];
}


- (id)initWithFrame:(NSRect)frame 
{
	self = [super initWithFrame:frame];
    if (self) {
		// Support transparency
		[NSColor setIgnoresAlpha:NO];

        // Defaults
		[self setOrigin:NSMakePoint(50.,50.)];
		[self setPixelsPerXUnit:[NSNumber numberWithDouble:20.0]];
		[self setPixelsPerYUnit:[NSNumber numberWithDouble:10]];
		[self setMinimumPixelsPerMajorGridLine:[NSNumber numberWithDouble:25]];
		[self setPlottingArea:NSMakeRect(50,20,[self bounds].size.width-60,[self bounds].size.height-25)];
		[self setLegendArea:NSMakeRect([self bounds].size.width-90-60,[self bounds].size.height-90-120,60,120)];
		[self setSelectedRect:NSMakeRect(0,0,0,0)];
		
		[self setShouldDrawAxes:YES];
		[self setShouldDrawMajorTickMarks:YES];
		[self setShouldDrawMinorTickMarks:YES];
		[self setShouldDrawGrid:YES];
		[self setShouldDrawLabels:NO];
		[self setShouldDrawLegend:NO];
		[self setShouldDrawLabelsOnFrame:YES];
		
		[self setBackColor:[NSColor clearColor]];
		[self setPlottingAreaColor:[NSColor whiteColor]];
		[self setAxesColor:[NSColor blackColor]];
		[self setGridColor:[NSColor gridColor]];
		[self setLabelsColor:[NSColor blackColor]];
		[self setLabelsOnFrameColor:[NSColor blackColor]];
		[self setLegendAreaColor:[NSColor whiteColor]];
		[self setLegendFrameColor:[NSColor blackColor]];
		
		// Nu refreshen we ook als data van een andere instance van deze view veranderd!!!
	//	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"MyGraphDataSerieDidChangeNotification" object:nil];
		
		// Observe changes for what values to draw
		[self addObserver:self forKeyPath:@"keyForXValue" options:nil context:DataObservationContext];
		[self addObserver:self forKeyPath:@"keyForYValue" options:nil context:DataObservationContext];
		
		// Observe changes for plotting area
		[self addObserver:self forKeyPath:@"origin" options:nil context:PropertyObservationContext];
		[self addObserver:self forKeyPath:@"frame" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:FrameObservationContext];	

		// Observe changes for what to draw
		[self addObserver:self forKeyPath:@"shouldDrawAxes" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawMajorTickMarks" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawMinorTickMarks" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawLegend" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawGrid" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawLabels" options:nil context:PropertyObservationContext];
		[self addObserver:self forKeyPath:@"shouldDrawLabelsOnFrame" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawLegend" options:nil context:PropertyObservationContext];	
		
		// Observe changes for color
		[self addObserver:self forKeyPath:@"backColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"plottingAreaColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"axesColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"gridColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"labelsColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"labelsOnFrameColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"legendAreaColor" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"legendFrameColor" options:nil context:PropertyObservationContext];	
		
		// Observe changes for zooming
		[self addObserver:self forKeyPath:@"minimumPixelsPerMajorGridLine" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"pixelsPerXUnit" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"pixelsPerYUnit" options:nil context:PropertyObservationContext];
		
		// Observe changes for text
		[self addObserver:self forKeyPath:@"titleString" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"xAxisLabelString" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"yAxisLabelString" options:nil context:PropertyObservationContext];	

		// Additions for Peacock
		[self setShouldDrawBaseline:NO];
		[self setShouldDrawPeaks:YES];

		[self addObserver:self forKeyPath:@"baseline" options:nil context:PropertyObservationContext];			
		[self addObserver:self forKeyPath:@"shouldDrawBaseline" options:nil context:PropertyObservationContext];	
		[self addObserver:self forKeyPath:@"shouldDrawPeaks" options:nil context:PropertyObservationContext];	
	}
	return self;
}

- (void)dealloc
{
	[self unbind:@"baselineSelectionIndexes"];
	[self unbind:@"baseline"];
	[self unbind:@"peaksSelectionIndexes"];
	[self unbind:@"peaks"];
	[self unbind:@"dataSeriesSelectionIndexes"];
	[self unbind:@"dataSeries"];

	// Observe changes for what values to draw
	[self removeObserver:self forKeyPath:@"keyForXValue"];
	[self removeObserver:self forKeyPath:@"keyForYValue"];
	
	// Observe changes for plotting area
	[self removeObserver:self forKeyPath:@"origin"];
	[self removeObserver:self forKeyPath:@"frame"];	
	
	// Observe changes for what to draw
	[self removeObserver:self forKeyPath:@"shouldDrawAxes"];	
	[self removeObserver:self forKeyPath:@"shouldDrawMajorTickMarks"];	
	[self removeObserver:self forKeyPath:@"shouldDrawMinorTickMarks"];	
	[self removeObserver:self forKeyPath:@"shouldDrawLegend"];	
	[self removeObserver:self forKeyPath:@"shouldDrawGrid"];	
	[self removeObserver:self forKeyPath:@"shouldDrawLabels"];
	[self removeObserver:self forKeyPath:@"shouldDrawLabelsOnFrame"];	
	[self removeObserver:self forKeyPath:@"shouldDrawLegend"];	
	
	// Observe changes for color
	[self removeObserver:self forKeyPath:@"backColor"];	
	[self removeObserver:self forKeyPath:@"plottingAreaColor"];	
	[self removeObserver:self forKeyPath:@"axesColor"];	
	[self removeObserver:self forKeyPath:@"gridColor"];	
	[self removeObserver:self forKeyPath:@"labelsColor"];	
	[self removeObserver:self forKeyPath:@"labelsOnFrameColor"];	
	[self removeObserver:self forKeyPath:@"legendAreaColor"];	
	[self removeObserver:self forKeyPath:@"legendFrameColor"];	
	
	// Observe changes for zooming
	[self removeObserver:self forKeyPath:@"minimumPixelsPerMajorGridLine"];	
	[self removeObserver:self forKeyPath:@"pixelsPerXUnit"];	
	[self removeObserver:self forKeyPath:@"pixelsPerYUnit"];
	
	// Observe changes for text
	[self removeObserver:self forKeyPath:@"titleString"];	
	[self removeObserver:self forKeyPath:@"xAxisLabelString"];	
	[self removeObserver:self forKeyPath:@"yAxisLabelString"];	
	
	// Additions for Peacock
	[self removeObserver:self forKeyPath:@"baseline"];			
	[self removeObserver:self forKeyPath:@"shouldDrawBaseline"];	
	[self removeObserver:self forKeyPath:@"shouldDrawPeaks"];	

	[super dealloc];
}



#pragma mark DRAWING ROUTINES
- (void)drawRect:(NSRect)rect {
	[self calculateCoordinateConversions];

	// Fancy schaduw effecten...
	NSShadow *noShadow = [[NSShadow alloc] init];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:10];
	[shadow setShadowOffset:NSMakeSize(6,-6)];
		
	// Achtergrondkleur
	[noShadow set];
	[[self backColor] set];
	[[NSBezierPath bezierPathWithRect:rect] fill];

	// Achtergrondkleur plottingArea (met schaduw)
	[shadow set]; 	
	[[self plottingAreaColor] set];
	[[NSBezierPath bezierPathWithRect:[self plottingArea]] fill];
	
	// Frame om plottingArea	
	[noShadow set];
	[[self frameColor] set];
	[[NSBezierPath bezierPathWithRect:[self plottingArea]] stroke];

    // Draw plotting inside the plotting area
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
	
	if ([self shouldDrawGrid])
		[self drawGrid];
	if ([self shouldDrawAxes])
		[self drawAxes];
	if ([self shouldDrawMinorTickMarks])
		[self drawMinorTickMarks];
	if ([self shouldDrawMajorTickMarks])
		[self drawMajorTickMarks];
	if ([self shouldDrawLabels])
		[self drawLabels];
	
	// Additions for Peacock
	if ([self shouldDrawBaseline])
		[self drawBaseline];
	
	// In plaats van een loop kunnen we ook deze convenient method gebruiken om iedere dataserie zich te laten tekenen.
	//NSAssert([[self dataSeries] count] >= 1, @"No dataSeries to draw.");
	[[self dataSeries] makeObjectsPerformSelector:@selector(plotDataWithTransform:) withObject:[self trans]];
	
	[NSGraphicsContext restoreGraphicsState];
	
	if ([self shouldDrawLabelsOnFrame])
		[self drawLabelsOnFrame];
	if ([self shouldDrawLegend])
		[self drawLegend];
	[self drawTitles];
	
	[[[NSColor selectedControlColor] colorWithAlphaComponent:0.4] set];
	[[NSBezierPath bezierPathWithRect:[self selectedRect]] fill];
	[[NSColor selectedControlColor] set];
	[[NSBezierPath bezierPathWithRect:[self selectedRect]] stroke];
	
	[shadow release];
	[noShadow release];
}

- (void)drawGrid {
	int i, start, end;
	double stepInUnits, stepInPixels;
	NSBezierPath *gridPath = [[NSBezierPath alloc] init];
		
	// Verticale gridlijnen
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] doubleValue];
	
	start = -[self origin].x/stepInPixels;
	end = start + [self frame].size.width/stepInPixels+1;
	for (i=start; i <= end; i++) {
		[gridPath moveToPoint:NSMakePoint(i*stepInPixels+[self origin].x,0.)];
		[gridPath lineToPoint:NSMakePoint(i*stepInPixels+[self origin].x,[self frame].size.height)];
	}
	
	// En de horizontale gridlijnen
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] doubleValue];
	
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

- (void)drawMajorTickMarks {
	int i, start, end;
	double stepInUnits, stepInPixels;
	double tickMarksWidth = 2.5;
	int tickMarksPerUnit = 5;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] doubleValue];
	
	start = (-[self origin].x/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.width/stepInPixels)*tickMarksPerUnit+1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] doubleValue];
	
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

- (void)drawMinorTickMarks {
	int i, start, end;
	double stepInUnits, stepInPixels;
	double tickMarksWidth = 5.0;
	int tickMarksPerUnit = 1;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] doubleValue];
	
	start = (-[self origin].x/stepInPixels)*tickMarksPerUnit;
	end = start + ([self frame].size.width/stepInPixels)*tickMarksPerUnit+1;
	for (i=start; i <= end; i++) {
		[tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y)];
		[tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/tickMarksPerUnit+[self origin].x,[self origin].y+tickMarksWidth)];
	}
	
	// En de horizontale tickmarks
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] doubleValue];
	
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

- (void)drawLegend {
	int i;
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

	// Frame om legendArea
	[noShadow set];
	[[self legendFrameColor] setStroke];
	[[NSBezierPath bezierPathWithRect:[self legendArea]] stroke];
	
    // Draw inside the legendArea
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self legendArea]] addClip];
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
		
	if ([[self dataSeries] count] > 0) {
		for (i=0;i<[[self dataSeries] count]; i++) {
			string = [[NSMutableAttributedString alloc] initWithString:[[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesTitle"] attributes:attrs];
			stringSize = [string size];
			pointToDraw = [self legendArea].origin;
			pointToDraw.x = pointToDraw.x + 4;
			pointToDraw.y = pointToDraw.y - stringSize.height*(i+1) + [self legendArea].size.height - (4*i) - 4;
			[string drawAtPoint:pointToDraw];
			[string release];
		}
	}
	
	[NSGraphicsContext restoreGraphicsState];
	
	// Cleaning up
	[noShadow release];
	[shadow release];
}

- (void)drawTitles {
	
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

- (void)drawLabels {
	NSMutableAttributedString *string;// = [[NSMutableAttributedString alloc] init];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	int i, start, end;
	double stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%.f";
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];

	// Labels op X-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] doubleValue];
	
	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	if (floor(log10(stepInUnits)) < 0) {
		formatString = [NSString stringWithFormat:@"%%.%.ff", fabs(floor(log10(stepInUnits)))];
	} 
	
	// Nog in te voegen: waarden groter dan 1E6 met notatie 1,0 x 10^6  en hetzelfde voor waarden kleiner dan 1E-6.
	// Nul moet altijd gewoon "0" zijn.
	// Als we ver van de oorspong gaan, dan moeten de waarden ook anders genoteerd worden, 1,10,100,1000,1e4 1,0001e4,1,0002e4 of 10.001, 10.002, of toch niet?!
	// Duizendtal markers
	
	start = -[self origin].x/stepInPixels;
	end = start + [self frame].size.width/stepInPixels+1;
	for (i=start; i <= end; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, i*stepInUnits] attributes:attrs];
//		[string initWithString:[NSString stringWithFormat:@"%.1fx10%d", i*stepInUnits, 3] attributes:attrs];
		
//		[attrs setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
//		[attrs setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];
//		[string setAttributes:attrs range:NSMakeRange(6,1)];
		stringSize = [string size];
		pointToDraw = [[self trans] transformPoint:NSMakePoint(i*stepInUnits,0.)];
		pointToDraw.x = pointToDraw.x - stringSize.width/2;
		pointToDraw.y = pointToDraw.y - stringSize.height - 4;
		[string drawAtPoint:pointToDraw];
		[string release];
	}

	// Labels op Y-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] doubleValue];

	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	if (floor(log10(stepInUnits)) < 0) {
		formatString = [NSString stringWithFormat:@"%%.%.ff", fabs(floor(log10(stepInUnits)))];
	} else {
		formatString = @"%.f";
	}
	
	start = -[self origin].y/stepInPixels;
	end = start + [self frame].size.height/stepInPixels+1;
	for (i=start; i <= end; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, i*stepInUnits] attributes:attrs];
		stringSize = [string size];
		pointToDraw = [[self trans] transformPoint:NSMakePoint(0.,i*stepInUnits)];
		pointToDraw.x = pointToDraw.x - stringSize.width - 4;
		pointToDraw.y = pointToDraw.y - stringSize.height/2;
		[string drawAtPoint:pointToDraw];
		[string release];
	}
}

- (void)drawLabelsOnFrame {
	NSMutableAttributedString *string;// = [[NSMutableAttributedString alloc] init];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	int i, start, end;
	double stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%.f";
	
	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
	
	// Labels op X-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerXUnit] doubleValue];
	
	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	if (floor(log10(stepInUnits)) < 0) {
		formatString = [NSString stringWithFormat:@"%%.%.ff", fabs(floor(log10(stepInUnits)))];
	} 
	
	// Nog in te voegen: waarden groter dan 1E6 met notatie 1,0 x 10^6  en hetzelfde voor waarden kleiner dan 1E-6.
	// Nul moet altijd gewoon "0" zijn. Of de "O" in italics van Oorsprong/Origin.
	// Als we ver van de oorspong gaan, dan moeten de waarden ook anders genoteerd worden, 1,10,100,1000,1e4 1,0001e4,1,0002e4 of 10.001, 10.002, of toch niet?!
	// Duizendtal markers
	
	start = ceil((-[self origin].x + [self plottingArea].origin.x)/stepInPixels);
	end = floor((-[self origin].x + [self plottingArea].origin.x + [self plottingArea].size.width)/stepInPixels);
	for (i=start; i <= end; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, i*stepInUnits] attributes:attrs];
//		[string initWithString:[NSString stringWithFormat:@"%.1fx10%d", i*stepInUnits, 3] attributes:attrs];
		
//		[attrs setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
//		[attrs setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];
//		[string setAttributes:attrs range:NSMakeRange(6,1)];
		stringSize = [string size];
		pointToDraw = [[self trans] transformPoint:NSMakePoint(i*stepInUnits,0.)];
		pointToDraw.x = pointToDraw.x - stringSize.width/2;
		pointToDraw.y = [self plottingArea].origin.y - stringSize.height - 4;
		[string drawAtPoint:pointToDraw];
		[string release];
	}
	
	// Labels op Y-as
	stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] doubleValue]];
	stepInPixels = stepInUnits * [[self pixelsPerYUnit] doubleValue];
	
	// Toegegeven, dit is niet erg doorzichtig. Het is een dubbelgenestte printf string die ervoor zorgt dat er altijd net genoeg cijfers achter de komma worden gezet om te weten hoe groot de stap tussen de gridlijnen is.
	if (floor(log10(stepInUnits)) < 0) {
		formatString = [NSString stringWithFormat:@"%%.%.ff", fabs(floor(log10(stepInUnits)))];
	} else {
		formatString = @"%.f";
	}
	
	start = ceil((-[self origin].y + [self plottingArea].origin.y)/stepInPixels);
	end = floor((-[self origin].y + [self plottingArea].origin.y + [self plottingArea].size.height)/stepInPixels);
	for (i=start; i <= end; i++) {
		string = [[NSMutableAttributedString alloc] initWithString:[NSString localizedStringWithFormat:formatString, i*stepInUnits] attributes:attrs];
		stringSize = [string size];
		pointToDraw = [[self trans] transformPoint:NSMakePoint(0.,i*stepInUnits)];
		pointToDraw.x = [self plottingArea].origin.x - stringSize.width - 4;
		pointToDraw.y = pointToDraw.y - stringSize.height/2;
		[string drawAtPoint:pointToDraw];
		[string release];
	}
}

- (void)drawAxes {
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

// Additions for Peacock
- (void)drawBaseline {
	int i, count, count2;
	NSBezierPath *baselinePath = [[NSBezierPath alloc] init];
	NSPoint pointToDraw;
	NSMutableArray *baselinePoints;
	NSArray *baselinePointsSelected;
	
	baselinePoints = [self baseline];
	count = [baselinePoints count];
	baselinePointsSelected = [[self baseline] objectsAtIndexes:[self baselineSelectionIndexes]];
	count2 = [baselinePointsSelected count];
	
    // Draw inside the legendArea
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
	
	// De baseline.

	if (count > 0) {
		pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:0] valueForKey:@"Scan"] floatValue],[[[baselinePoints objectAtIndex:0] valueForKey:@"Total Intensity"] floatValue]);
		[baselinePath moveToPoint:[[self trans] transformPoint:pointToDraw]];  	
		for (i=1;i<count; i++) {
			pointToDraw = NSMakePoint([[[baselinePoints objectAtIndex:i] valueForKey:@"Scan"] floatValue],[[[baselinePoints objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
			[baselinePath lineToPoint:[[self trans] transformPoint:pointToDraw]];			
		}
	}

	if (count2 > 0) {
		for (i=0;i<count2; i++) {
			pointToDraw = NSMakePoint([[[baselinePointsSelected objectAtIndex:i] valueForKey:@"Scan"] floatValue],[[[baselinePointsSelected objectAtIndex:i] valueForKey:@"Total Intensity"] floatValue]);
			pointToDraw = [[self trans] transformPoint:pointToDraw];
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


- (NSString *)view:(NSView *)view stringForToolTip:(NSToolTipTag)tag point:(NSPoint)point userData:(void *)userData {
	id peak = [[self peaks] objectAtIndex:(int)userData];
	return [NSString stringWithFormat:NSLocalizedString(@"Peak no. %d\n%@",@"Tiptool for peak number and label."), userData+1, [peak valueForKey:@"label"]];
}

- (void)refresh {
//	JKLogDebug(@"Refresh - %@",[self description]);
    [self setNeedsDisplay:YES];
}

#pragma mark ACTION ROUTINES
- (void)centerOrigin:(id)sender {
	NSPoint newOrigin;
	NSRect theFrame;
	theFrame = [self plottingArea];
	newOrigin.x = theFrame.origin.x + theFrame.size.width/2;
	newOrigin.y = theFrame.origin.y + theFrame.size.height/2;	
    [self setOrigin:newOrigin];
}
- (void)lowerLeftOrigin:(id)sender {
    [self setOrigin:[self plottingArea].origin];
}
- (void)squareAxes:(id)sender {
	double x,y,avg;
	x = [[self pixelsPerXUnit] doubleValue];
	y = [[self pixelsPerYUnit] doubleValue];
	avg = (x+y)/2;
	[self setPixelsPerXUnit:[NSNumber numberWithDouble:avg]];
	[self setPixelsPerYUnit:[NSNumber numberWithDouble:avg]];
}
- (void)showAll:(id)sender {
	int i, count;
	NSRect totRect, newRect;
	MyGraphDataSerie *mgds;
	
	// Voor iedere dataserie wordt de grootte in grafiek-coördinaten opgevraagd en de totaal omvattende rect bepaald
	count = [[self dataSeries] count];
	for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
		newRect = [mgds boundingRect];
		totRect = NSUnionRect(totRect, newRect);
	}
	[self zoomToRect:totRect];
}
- (void)showMagnifyingGlass:(NSEvent *)theEvent {
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
	[[self dataSeries] makeObjectsPerformSelector:@selector(plotDataWithTransform:) withObject:[self trans]];
	[aView unlockFocus];
//	[magnifiedImage addRepresentation:[NSPDFImageRep imageRepWithData:[self dataWithPDFInsideRect:[magnifyingGlassWindow frame]]]];
//	[magnifiedView setImage:magnifiedImage];
	[[self window] addChildWindow:magnifyingGlassWindow ordered:NSWindowAbove];
	[magnifyingGlassWindow orderFront:self];
}

#pragma mark HELPER ROUTINES
- (void)calculateCoordinateConversions {
	NSAffineTransform *translationMatrix, *scalingMatrix, *transformationMatrix, *invertMatrix;
	
	// We rekenen eerst in twee aparte matrices uit hoe de verplaatsing en schaling gedaan moet worden.
	
	// Als de oorsprong elders ligt, moeten we daarvoor corrigeren.
    translationMatrix = [NSAffineTransform transform];
    [translationMatrix translateXBy:[self origin].x yBy:[self origin].y];
	
	// De waarden omrekeningen naar pixels op het scherm.
     scalingMatrix = [NSAffineTransform transform];
    [scalingMatrix scaleXBy:[[self pixelsPerXUnit] floatValue] yBy:[[self pixelsPerYUnit] floatValue]];
	
	// In transformationMatrix combineren we de matrices. Eerst de verplaatsing, dan schalen.
    transformationMatrix = [NSAffineTransform transform];
    [transformationMatrix appendTransform:scalingMatrix];
    [transformationMatrix appendTransform:translationMatrix];
    [self setTrans:transformationMatrix];
    
	// We zullen ook terug van data serie coördinaten naar scherm-coördinaten willen rekenen. Het zou niet effectief zijn om dat iedere keer dat we dit nodig hebben de inverse matrix uit te rekenen. Daarom hier één keer en vervolgens bewaren.
    invertMatrix = [[transformationMatrix copy] autorelease];
    [invertMatrix invert];
    [self setInverseTrans:invertMatrix];
	
}

- (double)unitsPerMajorGridLine:(double)pixelsPerUnit {
	double amountAtMinimum, orderOfMagnitude, fraction;
	
	amountAtMinimum = [[self minimumPixelsPerMajorGridLine] doubleValue]/pixelsPerUnit;	
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

	[self setPixelsPerXUnit:[NSNumber numberWithDouble:(([self plottingArea].size.width  )/aRect.size.width)]];
	[self setPixelsPerYUnit:[NSNumber numberWithDouble:(([self plottingArea].size.height )/aRect.size.height)]];

	newOrig.x = [self plottingArea].origin.x - aRect.origin.x * [[self pixelsPerXUnit] doubleValue];
	newOrig.y = [self plottingArea].origin.y - aRect.origin.y * [[self pixelsPerYUnit] doubleValue];
	[self setOrigin:newOrig];
	[self calculateCoordinateConversions];
}

- (void)zoomToRectInView:(NSRect)aRect { // aRect in view coördinaten
	NSRect newRect;
		
	newRect.origin = [[self inverseTrans] transformPoint:aRect.origin];
	newRect.size = [[self inverseTrans] transformSize:aRect.size];
	JKLogDebug(@"zoomToRectInView x %f, y %f, w %f, h %f",newRect.origin.x, newRect.origin.y, newRect.size.width, newRect.size.height);
	[self zoomToRect:newRect];

}

- (void)zoomOut {
	double xWidth = [[self xMaximum] doubleValue] - [[self xMinimum] doubleValue];
	[self setXMaximum:[NSNumber numberWithDouble:[[self xMaximum] doubleValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithDouble:[[self xMinimum] doubleValue] - xWidth/4]];
	
	double yWidth = [[self yMaximum] doubleValue] - [[self yMinimum] doubleValue];
	[self setYMaximum:[NSNumber numberWithDouble:[[self yMaximum] doubleValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithDouble:[[self yMinimum] doubleValue] - yWidth/4]];
}

- (void)moveLeft {
	double xWidth = [[self xMaximum] doubleValue] - [[self xMinimum] doubleValue];
	[self setXMaximum:[NSNumber numberWithDouble:[[self xMaximum] doubleValue] - xWidth/4]];
	[self setXMinimum:[NSNumber numberWithDouble:[[self xMinimum] doubleValue] - xWidth/4]];
}

- (void)moveRight {
	double xWidth = [[self xMaximum] doubleValue] - [[self xMinimum] doubleValue];
	[self setXMaximum:[NSNumber numberWithDouble:[[self xMaximum] doubleValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithDouble:[[self xMinimum] doubleValue] + xWidth/4]];
}

- (void)moveUp {
	double yWidth = [[self yMaximum] doubleValue] - [[self yMinimum] doubleValue];
	[self setYMaximum:[NSNumber numberWithDouble:[[self yMaximum] doubleValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithDouble:[[self yMinimum] doubleValue] + yWidth/4]];
}

- (void)moveDown {
	double yWidth = [[self yMaximum] doubleValue] - [[self yMinimum] doubleValue];
	[self setYMaximum:[NSNumber numberWithDouble:[[self yMaximum] doubleValue] - yWidth/4]];
	[self setYMinimum:[NSNumber numberWithDouble:[[self yMinimum] doubleValue] - yWidth/4]];
}

#pragma mark MOUSE INTERACTION MANAGEMENT
- (void)resetCursorRects {
	[self addCursorRect:[self frame] cursor:[NSCursor arrowCursor]];
	[self addCursorRect:[self plottingArea] cursor:[NSCursor crosshairCursor]];
	if (shouldDrawLegend) [self addCursorRect:[self legendArea] cursor:[NSCursor openHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent {
	didDrag = NO;
	mouseDownAtPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	oldOrigin = [self origin];
//	oldLegendOrigin = [self legendArea].origin;
}

- (void)mouseDragged:(NSEvent *)theEvent {
    BOOL isInsidePlottingArea, isInsideLegendArea;
	didDrag = YES;
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	// Waar is de muis?
	isInsidePlottingArea = [self mouse:mouseLocation inRect:[self plottingArea]];
	isInsideLegendArea = [self mouse:mouseLocation inRect:[self legendArea]];

	NSRect draggedRect;
	draggedRect.origin.x = (mouseDownAtPoint.x < mouseLocation.x ? mouseDownAtPoint.x : mouseLocation.x);
	draggedRect.origin.y = (mouseDownAtPoint.y < mouseLocation.y ? mouseDownAtPoint.y : mouseLocation.y);
	draggedRect.size.width = fabs(mouseLocation.x-mouseDownAtPoint.x);
	draggedRect.size.height = fabs(mouseLocation.y-mouseDownAtPoint.y);
	
	if (isInsidePlottingArea) {
		if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
			//   combine spectrum
			JKLogDebug(@"combine spectrum");
		} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			//   add custom peak
			JKLogDebug(@"add custom peak");
		} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
			//   not specified
			JKLogDebug(@"not specified");
		} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
			//   move chromatogram
			JKLogDebug(@"move chromatogram");
			[[NSCursor closedHandCursor] set];
			NSPoint newOrigin;
			newOrigin.x = oldOrigin.x + (mouseLocation.x - mouseDownAtPoint.x);
			newOrigin.y = oldOrigin.y + (mouseLocation.y - mouseDownAtPoint.y);
			[self setOrigin:newOrigin];
				
		} else {
			NSCursor *zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom2"] hotSpot:NSMakePoint(6,6)];
			[zoomCursor set];
			[zoomCursor release];
			//   zoom in/move baseline point
			JKLogDebug(@"zoom in/move baseline point");
			//		[[NSColor selectedTextBackgroundColor] set];
		}		
	} else if (isInsideLegendArea) {
		[[NSCursor closedHandCursor] set];
		NSPoint newOrigin;
		newOrigin.x = oldOrigin.x + (mouseLocation.x - mouseDownAtPoint.x);
		newOrigin.y = oldOrigin.y + (mouseLocation.y - mouseDownAtPoint.y);
		NSRect legendRect;
		legendRect = [self legendArea];
		legendRect.origin = newOrigin;
		[self setLegendArea:legendRect];		
	}
				[self setSelectedRect:draggedRect];

	[self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	if (!didDrag) {
		if ([theEvent clickCount] == 1) { // Single click
			if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
				//   select scan
				JKLogDebug(@"select scan");
//				if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
					[delegate showSpectrumForScan:0];
//				} else {
//					JKLogError(@"MyGraphView delegate doesn't respond to showSpectrumForScan:");
//				}
			} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
				//  select scan 
				JKLogDebug(@"select scan");								
			} else if ([theEvent modifierFlags] & NSCommandKeyMask ) {
				//  select scan 
				JKLogDebug(@"select scan");		
				[self showMagnifyingGlass:theEvent];
			} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
				//  zoom out 
				[self zoomOut];
			} else {
				//  select peak/select baseline point/select scan 
				JKLogDebug(@"select peak/select baseline point/select scan");
			}
		} else if ([theEvent clickCount] == 2) { // Double click
			if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
				//   combine spectrum for peak
				JKLogDebug(@"combine spectrum for peak");
			} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
				//  add peak
				JKLogDebug(@"add peak");
			} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
				//  add baseline point
				int i;
				NSPoint pointInReal = [[self inverseTrans] transformPoint:mouseLocation];
				
				NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
				[mutDict setValue:[NSNumber numberWithFloat:pointInReal.x] forKey:@"Scan"];
				[mutDict setValue:[NSNumber numberWithFloat:pointInReal.y] forKey:@"Total Intensity"];
				
				// Following works, but can fail in circumstances, need error checking!
				// if count 0 addObject
				i=0;
				while (pointInReal.x > [[[[self baseline] objectAtIndex:i] valueForKey:@"Scan"] intValue]) {
					i++;
				}
				// if i == count addObject
				
				[(NSArrayController*) baselineContainer insertObject:mutDict atArrangedObjectIndex:i];
				[mutDict release];
			} else if ([theEvent modifierFlags] & NSShiftKeyMask)  {
				//  show all 
				[self showAll:self];
			} else {
				//  show spectrum 
				JKLogDebug(@"show spectrum");
			}
		} else {
			NSBeep();
		}
	} else if (didDrag) {
		NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect draggedRect;
		draggedRect.origin.x = (mouseDownAtPoint.x < mouseLocation.x ? mouseDownAtPoint.x : mouseLocation.x);
		draggedRect.origin.y = (mouseDownAtPoint.y < mouseLocation.y ? mouseDownAtPoint.y : mouseLocation.y);
		draggedRect.size.width = fabs(mouseLocation.x-mouseDownAtPoint.x);
		draggedRect.size.height = fabs(mouseLocation.y-mouseDownAtPoint.y);
		
		if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
			//   combine spectrum
			JKLogDebug(@"combine spectrum");
		} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
			//   add custom peak
			JKLogDebug(@"add custom peak");
		} else if ([theEvent modifierFlags] & NSCommandKeyMask) {
			//   not specified
			
		} else if ([theEvent modifierFlags] & NSShiftKeyMask) {
			//   move chromatogram
			NSPoint newOrigin;
			newOrigin.x = oldOrigin.x + (mouseLocation.x - mouseDownAtPoint.x);
			newOrigin.y = oldOrigin.y + (mouseLocation.y - mouseDownAtPoint.y);
			[self setOrigin:newOrigin];
		} else {
			//   zoom in/move baseline point
			if ([self mouse:mouseDownAtPoint inRect:[self plottingArea]]) { //isInsidePlottingArea
				// nothing
			} else { // !isInsidePlottingArea
				if (mouseDownAtPoint.y < plottingArea.origin.y | mouseDownAtPoint.y > (plottingArea.origin.y + plottingArea.size.height)) {
					draggedRect.origin.y = plottingArea.origin.y;
					draggedRect.size.height = plottingArea.size.height;
				} else if (mouseDownAtPoint.x < plottingArea.origin.x | mouseDownAtPoint.x > (plottingArea.origin.x + plottingArea.size.width)) {
					draggedRect.origin.x = plottingArea.origin.x;
					draggedRect.size.width = plottingArea.size.width;
				}
			}
			[self zoomToRectInView:draggedRect];
			[self setSelectedRect:NSMakeRect(0,0,0,0)];
			[[NSCursor crosshairCursor] set]; 
		}
	}
	
	didDrag = NO;
	[self resetCursorRects];
	[self setNeedsDisplay:YES];
}

#pragma mark KEYBOARD INTERACTION MANAGEMENT
- (void)flagsChanged:(NSEvent *)theEvent {
	BOOL isInsidePlottingArea;
	NSPoint mouseLocation = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView:nil];
	
	// Waar is de muis?
	isInsidePlottingArea = [self mouse:mouseLocation inRect:[self plottingArea]];
	
	if (!didDrag){
		if (isInsidePlottingArea) {		
			if ([theEvent modifierFlags] & NSShiftKeyMask ) {
				NSCursor *zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom2"] hotSpot:NSMakePoint(6,6)];
				[zoomCursor set];
				[zoomCursor release];
			} else {
				[[NSCursor crosshairCursor] set];
			}
		}		
	}
}

- (void)keyDown:(NSEvent *)theEvent {
	if ([[theEvent characters] isEqualToString:@"a"]) {
		[self showAll:self];
	} else if ([[theEvent characters] isEqualToString:@"l"]) {
		shouldDrawLegend ? [self setShouldDrawLegend:NO] : [self setShouldDrawLegend:YES];
	} else if ([[theEvent characters] isEqualToString:@"g"]) {
		shouldDrawGrid ? [self setShouldDrawGrid:NO] : [self setShouldDrawGrid:YES];
	} else if ([[theEvent characters] isEqualToString:@"x"]) {
		shouldDrawAxes ? [self setShouldDrawAxes:NO] : [self setShouldDrawAxes:YES];
	} else if ([[theEvent characters] isEqualToString:@"b"]) {
		shouldDrawBaseline ? [self setShouldDrawBaseline:NO] : [self setShouldDrawBaseline:YES];
	} else if ([[theEvent characters] isEqualToString:@"p"]) {
		shouldDrawPeaks ? [self setShouldDrawPeaks:NO] : [self setShouldDrawPeaks:YES];
	} else if ([[theEvent characters] isEqualToString:@"z"]) {
		[self zoomOut];
	} else if ([[theEvent characters] isEqualToString:@" "]) {
//		[self showMagnifyingGlass:self];
	} else {
		NSString *keyString = [theEvent charactersIgnoringModifiers];
		unichar   keyChar = [keyString characterAtIndex:0];
		switch (keyChar) {
			case NSLeftArrowFunctionKey:
				[self moveLeft];
				break;
			case NSRightArrowFunctionKey:
				[self moveRight];
				break;
			case NSUpArrowFunctionKey:
				[self moveUp];
				break;
			case NSDownArrowFunctionKey:
				[self moveDown];
				break;
			case 0177: // Delete Key
			case NSDeleteFunctionKey:
			case NSDeleteCharFunctionKey:
				[[self baseline] removeObjectsAtIndexes:[self baselineSelectionIndexes]];
				[self setNeedsDisplay:YES];
				break;
			default:
				[super keyDown:theEvent];
		}
	}
}

- (BOOL)canBecomeKeyView {
	return YES;
}
- (BOOL) acceptsFirstResponder{
    return YES;
}
- (BOOL) resignFirstResponder{
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidResignFirstResponderNotification object:self];
    return YES;
}
- (BOOL) becomeFirstResponder{
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidBecomeFirstResponderNotification object:self];
    return YES;
}

- (void)copy:(id)sender {
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

#pragma mark KEY VALUE OBSERVING MANAGEMENT
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if ([keyPath isEqualToString:@"peaks"]) 
	{
//		[(ChromatogramGraphDataSerie *)[[self dataSeries] objectAtIndex:0] setPeaks:[self peaks]];
	} 
	else if (context == DataSeriesObservationContext)
	{
		/*
		 Should be able to use
		 NSArray *oldGraphics = [change objectForKey:NSKeyValueChangeOldKey];
		 etc. but the dictionary doesn't contain old and new arrays...??
		 */
//		NSArray *newGraphics = [object valueForKeyPath:graphicsKeyPath];
//		
//		NSMutableArray *onlyNew = [newGraphics mutableCopy];
//		[onlyNew removeObjectsInArray:oldGraphics];
//		[self startObservingGraphics:onlyNew];
//		[onlyNew release];
//		
//		NSMutableArray *removed = [oldGraphics mutableCopy];
//		[removed removeObjectsInArray:newGraphics];
//		[self stopObservingGraphics:removed];
//		[removed release];
//		
//		[self setOldGraphics:newGraphics];
		
		// could check drawingBounds of old and new, but...
		[self setNeedsDisplay:YES];
		return;
    }
	else if (context == PropertyObservationContext)
	{
//		NSRect updateRect;
		
		// Note: for Circle, drawingBounds is a dependent key of all the other
		// property keys except color, so we'll get this anyway...
//		if ([keyPath isEqualToString:@"drawingBounds"])
//		{
//			NSRect newBounds = [[change objectForKey:NSKeyValueChangeNewKey] rectValue];
//			NSRect oldBounds = [[change objectForKey:NSKeyValueChangeOldKey] rectValue];
//			updateRect = NSUnionRect(newBounds,oldBounds);
//		}
//		else
//		{
//			updateRect = [(NSObject <Graphic> *)object drawingBounds];
//		}
//		updateRect = NSMakeRect(updateRect.origin.x-1.0,
//								updateRect.origin.y-1.0,
//								updateRect.size.width+2.0,
//								updateRect.size.height+2.0);
		[self setNeedsDisplay:YES];//InRect:updateRect];
		return;
	}
	else if (context == PeaksObservationContext)
	{
		[self setNeedsDisplay:YES];
		return;
	}
	else if (context == BaselineObservationContext)
	{
		if (shouldDrawPeaks) [self setNeedsDisplay:YES]; // Don't redraw if we don't show the peaks anyway!!
		return;
	}
	else if (context == PropertyObservationContext) 
	{
		[self setNeedsDisplay:YES];
		return;
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
		[self refresh];
		return;
    } 
	else if (context == FrameObservationContext) 
	{
		NSRect oldFrect, newFrect, pRect, lRect;
		oldFrect = [[change objectForKey:NSKeyValueChangeOldKey] rectValue];
		newFrect = [[change objectForKey:NSKeyValueChangeNewKey] rectValue];
		pRect = [self plottingArea];
		pRect.size.width = pRect.size.width + newFrect.size.width - oldFrect.size.width;
		pRect.size.height = pRect.size.height + newFrect.size.height - oldFrect.size.height;
		[self setPlottingArea:pRect];
		lRect = [self legendArea];
		lRect.origin.x = lRect.origin.x + newFrect.size.width - oldFrect.size.width;
		lRect.origin.y = lRect.origin.y + newFrect.size.height - oldFrect.size.height;
		[self setLegendArea:lRect];
	} 
	else if ([keyPath isEqualToString:@"keyForXValue"]) 
	{
		int i, count;
		// KORT DOOR DE BOCHT HIER
		count = [[self dataSeries] count];
		for (i=0;i<count; i++){
			[[[self dataSeries] objectAtIndex:i] setKeyForXValue:[self keyForXValue]];
			[[[self dataSeries] objectAtIndex:i] setKeyForYValue:[self keyForYValue]];
			[[[self dataSeries] objectAtIndex:i] constructPlotPath];
		}
	} 
	else if([keyPath isEqualToString:@"keyForYValue"]) 
	{
			int i, count;
			// KORT DOOR DE BOCHT HIER
			count = [[self dataSeries] count];

			for (i=0;i<count; i++){
				[[[self dataSeries] objectAtIndex:i] setKeyForXValue:[self keyForXValue]];
				[[[self dataSeries] objectAtIndex:i] setKeyForYValue:[self keyForYValue]];
				[[[self dataSeries] objectAtIndex:i] constructPlotPath];
			}
	} 
	else 
	{
		// fallback
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
    else if ([bindingName isEqualToString:@"dataSeriesSelectionIndexes"])
	{		
		[self setDataSeriesSelectionIndexesContainer:observableObject];
		[self setDataSeriesSelectionIndexesKeyPath:observableKeyPath];
		[dataSeriesSelectionIndexesContainer addObserver:self
											  forKeyPath:dataSeriesSelectionIndexesKeyPath
												 options:(NSKeyValueObservingOptionNew |
														  NSKeyValueObservingOptionOld)
												 context:DataSeriesSelectionIndexesObservationContext];
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
	else if ([bindingName isEqualToString:@"peaksSelectionIndexes"])
	{
		[self setPeaksSelectionIndexesContainer:observableObject];
		[self setPeaksSelectionIndexesKeyPath:observableKeyPath];
		[peaksSelectionIndexesContainer addObserver:self
										 forKeyPath:peaksSelectionIndexesKeyPath
											options:nil
											context:PeaksSelectionIndexesObservationContext];
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
	else if ([bindingName isEqualToString:@"baselineSelectionIndexes"])
	{
		[self setBaselineSelectionIndexesContainer:observableObject];
		[self setBaselineSelectionIndexesKeyPath:observableKeyPath];
		[baselineSelectionIndexesContainer addObserver:self
											forKeyPath:baselineSelectionIndexesKeyPath
											   options:nil
											   context:BaselineSelectionIndexesObservationContext];
	}
	
	[super bind:bindingName
	   toObject:observableObject
	withKeyPath:observableKeyPath
		options:options];
	
    [self setNeedsDisplay:YES];
}


- (void)unbind:(NSString *)bindingName {
	
    if ([bindingName isEqualToString:@"dataSeries"])
	{
		[dataSeriesContainer removeObserver:self forKeyPath:dataSeriesKeyPath];
		[self setDataSeriesContainer:nil];
		[self setDataSeriesKeyPath:nil];
    }
    else if ([bindingName isEqualToString:@"dataSeriesSelectionIndexes"])
	{
		[dataSeriesSelectionIndexesContainer removeObserver:self forKeyPath:dataSeriesSelectionIndexesKeyPath];
		[self setDataSeriesSelectionIndexesContainer:nil];
		[self setDataSeriesSelectionIndexesKeyPath:nil];
    }
	else if ([bindingName isEqualToString:@"peaks"])
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
	else if ([bindingName isEqualToString:@"baseline"])
	{
		[baselineContainer removeObserver:self forKeyPath:baselineKeyPath];
		[self setBaselineContainer:nil];
		[self setBaselineKeyPath:nil];
	}
	else if ([bindingName isEqualToString:@"baselineSelectionIndexes"])
	{
		[baselineSelectionIndexesContainer removeObserver:self forKeyPath:baselineSelectionIndexesKeyPath];
		[self setBaselineSelectionIndexesContainer:nil];
		[self setBaselineSelectionIndexesKeyPath:nil];
	}
	
	[super unbind:bindingName];
	[self setNeedsDisplay:YES];
}

#pragma mark dataSeries bindings
- (NSMutableArray *)dataSeries
{	
    return [dataSeriesContainer valueForKeyPath:dataSeriesKeyPath];	
}
- (NSIndexSet *)dataSeriesSelectionIndexes
{	
    return [dataSeriesSelectionIndexesContainer valueForKeyPath:dataSeriesSelectionIndexesKeyPath];	
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
- (NSObject *)dataSeriesSelectionIndexesContainer
{
    return dataSeriesSelectionIndexesContainer; 
}
- (void)setDataSeriesSelectionIndexesContainer:(NSObject *)aDataSeriesSelectionIndexesContainer
{
    if (dataSeriesSelectionIndexesContainer != aDataSeriesSelectionIndexesContainer) {
        [dataSeriesSelectionIndexesContainer release];
        dataSeriesSelectionIndexesContainer = [aDataSeriesSelectionIndexesContainer retain];
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
- (NSString *)dataSeriesSelectionIndexesKeyPath
{
    return dataSeriesSelectionIndexesKeyPath; 
}
- (void)setDataSeriesSelectionIndexesKeyPath:(NSString *)aDataSeriesSelectionIndexesKeyPath
{
    if (dataSeriesSelectionIndexesKeyPath != aDataSeriesSelectionIndexesKeyPath) {
        [dataSeriesSelectionIndexesKeyPath release];
        dataSeriesSelectionIndexesKeyPath = [aDataSeriesSelectionIndexesKeyPath copy];
    }
}


#pragma mark peaks bindings
- (NSMutableArray *)peaks
{
	return [peaksContainer valueForKeyPath:peaksKeyPath];
}
- (NSIndexSet *)peaksSelectionIndexes
{
	return [peaksSelectionIndexesContainer valueForKeyPath:peaksSelectionIndexesKeyPath];
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

#pragma mark baseline bindings
- (NSMutableArray *)baseline
{
	return [baselineContainer valueForKeyPath:baselineKeyPath];
}
- (NSIndexSet *)baselineSelectionIndexes
{
	return [baselineSelectionIndexesContainer valueForKeyPath:baselineSelectionIndexesKeyPath];
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
- (NSObject *)baselineSelectionIndexesContainer
{
    return baselineSelectionIndexesContainer; 
}
- (void)setBaselineSelectionIndexesContainer:(NSObject *)aBaselineSelectionIndexesContainer
{
    if (baselineSelectionIndexesContainer != aBaselineSelectionIndexesContainer) {
        [baselineSelectionIndexesContainer release];
        baselineSelectionIndexesContainer = [aBaselineSelectionIndexesContainer retain];
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
- (NSString *)baselineSelectionIndexesKeyPath
{
    return baselineSelectionIndexesKeyPath; 
}
- (void)setBaselineSelectionIndexesKeyPath:(NSString *)aBaselineSelectionIndexesKeyPath
{
    if (baselineSelectionIndexesKeyPath != aBaselineSelectionIndexesKeyPath) {
        [baselineSelectionIndexesKeyPath release];
        baselineSelectionIndexesKeyPath = [aBaselineSelectionIndexesKeyPath copy];
    }
}

#pragma mark ACCESSORS
- (id)delegate {
	return delegate;
}
- (void)setDelegate:(id)inValue {
	delegate = inValue;
}

- (NSAffineTransform *)trans{
	return trans;
}
- (void)setTrans:(NSAffineTransform *)inValue {
	[inValue retain];
    [trans autorelease];
    trans = inValue;
}

- (NSAffineTransform *)inverseTrans {
	return inverseTrans;
}
- (void)setInverseTrans:(NSAffineTransform *)inValue {
	[inValue retain];
    [inverseTrans autorelease];
    inverseTrans = inValue;
}

- (NSNumber *)pixelsPerXUnit {
	return pixelsPerXUnit;
}
- (void)setPixelsPerXUnit:(NSNumber *)inValue {
	[inValue retain];
    [pixelsPerXUnit autorelease];
	pixelsPerXUnit = inValue;
}

- (NSNumber *)pixelsPerYUnit {
	return pixelsPerYUnit;
}
- (void)setPixelsPerYUnit:(NSNumber *)inValue {
	[inValue retain];
    [pixelsPerYUnit autorelease];
	pixelsPerYUnit = inValue;
}

- (NSNumber *)minimumPixelsPerMajorGridLine {
	return minimumPixelsPerMajorGridLine;
}
- (void)setMinimumPixelsPerMajorGridLine:(NSNumber *)inValue {
	// Check voor > 0! (nog niet geïmplementeerd)
	[inValue retain];
    [minimumPixelsPerMajorGridLine autorelease];
	minimumPixelsPerMajorGridLine = inValue;
}

- (NSPoint)origin {
	return origin;
}
- (void)setOrigin:(NSPoint)inValue {
	origin = inValue;
}

- (NSRect)plottingArea {
	return plottingArea;
}
- (void)setPlottingArea:(NSRect)inValue {
	plottingArea = inValue;
}

- (NSRect)legendArea {
	return legendArea;
}
- (void)setLegendArea:(NSRect)inValue {
	legendArea = inValue;
}

- (NSRect)selectedRect {
	return selectedRect;
}
- (void)setSelectedRect:(NSRect)inValue {
	selectedRect = inValue;
}
- (NSColor *)backColor {
    return backColor;
}
- (void)setBackColor:(NSColor *)inValue {
    [inValue retain];
    [backColor autorelease];
    backColor = inValue;
}
- (NSColor *)plottingAreaColor {
    return plottingAreaColor;
}
- (void)setPlottingAreaColor:(NSColor *)inValue {
    [inValue retain];
    [plottingAreaColor autorelease];
    plottingAreaColor = inValue;
}
- (NSColor *)axesColor {
    return axesColor;
}
- (void)setAxesColor:(NSColor *)inValue {
    [inValue retain];
    [axesColor autorelease];
    axesColor = inValue;
}
- (NSColor *)gridColor {
    return gridColor;
}
- (void)setGridColor:(NSColor *)inValue {
    [inValue retain];
    [gridColor autorelease];
    gridColor = inValue;
}
- (NSColor *)labelsColor {
    return labelsColor;
}
- (void)setLabelsColor:(NSColor *)inValue {
    [inValue retain];
    [labelsColor autorelease];
    labelsColor = inValue;
}
- (NSColor *)labelsOnFrameColor {
    return labelsOnFrameColor;
}
- (void)setLabelsOnFrameColor:(NSColor *)inValue {
    [inValue retain];
    [labelsOnFrameColor autorelease];
    labelsOnFrameColor = inValue;
}
- (NSColor *)frameColor {
    return frameColor;
}
- (void)setFrameColor:(NSColor *)inValue {
    [inValue retain];
    [frameColor autorelease];
    frameColor = inValue;
}
- (NSColor *)legendAreaColor {
    return legendAreaColor;
}
- (void)setLegendAreaColor:(NSColor *)inValue {
    [inValue retain];
    [legendAreaColor autorelease];
    legendAreaColor = inValue;
}
- (NSColor *)legendFrameColor {
    return legendFrameColor;
}
- (void)setLegendFrameColor:(NSColor *)inValue {
    [inValue retain];
    [legendFrameColor autorelease];
    legendFrameColor = inValue;
}
- (BOOL)shouldDrawLegend {
    return shouldDrawLegend;
}
- (void)setShouldDrawLegend:(BOOL)inValue {
     shouldDrawLegend = inValue;
}
- (BOOL)shouldDrawAxes {
    return shouldDrawAxes;
}
- (void)setShouldDrawAxes:(BOOL)inValue {
     shouldDrawAxes = inValue;
}
- (BOOL)shouldDrawMajorTickMarks
{
	return shouldDrawMajorTickMarks;
}
- (void)setShouldDrawMajorTickMarks:(BOOL)inValue;
{
	shouldDrawMajorTickMarks = inValue;
}
- (BOOL)shouldDrawMinorTickMarks
{
	return shouldDrawMinorTickMarks;
}
- (void)setShouldDrawMinorTickMarks:(BOOL)inValue
{
	shouldDrawMinorTickMarks = inValue;
}

- (BOOL)shouldDrawGrid {
    return shouldDrawGrid;
}
- (void)setShouldDrawGrid:(BOOL)inValue {
     shouldDrawGrid = inValue;
}
- (BOOL)shouldDrawLabels {
    return shouldDrawLabels;
}
- (void)setShouldDrawLabels:(BOOL)inValue {
	shouldDrawLabels = inValue;
}
- (BOOL)shouldDrawLabelsOnFrame {
    return shouldDrawLabelsOnFrame;
}
- (void)setShouldDrawLabelsOnFrame:(BOOL)inValue {
	shouldDrawLabelsOnFrame = inValue;
}
- (NSAttributedString *)titleString {
    return titleString;
}
- (void)setTitleString:(NSAttributedString *)inValue {
    [inValue retain];
    [titleString autorelease];
    titleString = inValue;
}
- (NSAttributedString *)xAxisLabelString {
    return xAxisLabelString;
}
- (void)setXAxisLabelString:(NSAttributedString *)inValue {
    [inValue retain];
    [xAxisLabelString autorelease];
    xAxisLabelString = inValue;
}
- (NSAttributedString *)yAxisLabelString {
    return yAxisLabelString;
}
- (void)setYAxisLabelString:(NSAttributedString *)inValue {
    [inValue retain];
    [yAxisLabelString autorelease];
    yAxisLabelString = inValue;
}
- (NSString *)keyForXValue {
	return keyForXValue;
}
- (void)setKeyForXValue:(NSString *)inValue {
	[inValue retain];
    [keyForXValue autorelease];
    keyForXValue = inValue;
}
- (NSString *)keyForYValue {
	return keyForYValue;
}
- (void)setKeyForYValue:(NSString *)inValue {
	[inValue retain];
    [keyForYValue autorelease];
    keyForYValue = inValue;
}

// Additions for Peacock
- (BOOL)shouldDrawBaseline {
	return shouldDrawBaseline;
}
- (void)setShouldDrawBaseline:(BOOL)inValue {
	shouldDrawBaseline = inValue;
}
- (BOOL)shouldDrawPeaks {
	return shouldDrawPeaks;
}
- (void)setShouldDrawPeaks:(BOOL)inValue {
	shouldDrawPeaks = inValue;
}


#pragma mark CALCULATED ACCESSORS
- (NSNumber *)xMinimum {
	NSPoint plotCorner;
	plotCorner = [[self inverseTrans] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithDouble:plotCorner.x];
}
- (void)setXMinimum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithDouble:([self plottingArea].size.width)/([[self xMaximum] doubleValue] - [inValue doubleValue])]];
	
	newOrigin.x = [self plottingArea].origin.x - [inValue doubleValue] * [[self pixelsPerXUnit] doubleValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
}
- (NSNumber *)xMaximum {
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self inverseTrans] transformPoint:[self plottingArea].origin];
	plotSize = [[self inverseTrans] transformSize:[self plottingArea].size];
	return [NSNumber numberWithDouble:(plotCorner.x + plotSize.width)];	
}
- (void)setXMaximum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithDouble:([self plottingArea].size.width)/([inValue doubleValue] - [[self xMinimum] doubleValue])]];
	
	newOrigin.x = [self plottingArea].origin.x + [self plottingArea].size.width - [inValue doubleValue] * [[self pixelsPerXUnit] doubleValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
	
}
- (NSNumber *)yMinimum {
	NSPoint plotCorner;
	plotCorner = [[self inverseTrans] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithDouble:plotCorner.y];	
}
- (void)setYMinimum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithDouble:([self plottingArea].size.height)/([[self yMaximum] doubleValue] - [inValue doubleValue])]];
	
	newOrigin.y = [self plottingArea].origin.y - [inValue doubleValue] * [[self pixelsPerYUnit] doubleValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
}
- (NSNumber *)yMaximum {
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self inverseTrans] transformPoint:[self plottingArea].origin];
	plotSize = [[self inverseTrans] transformSize:[self plottingArea].size];
	return [NSNumber numberWithDouble:(plotCorner.y + plotSize.height)];	
}
- (void)setYMaximum:(NSNumber *)inValue{
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithDouble:([self plottingArea].size.height)/([inValue doubleValue] - [[self yMinimum] doubleValue])]];
	
	newOrigin.y = [self plottingArea].origin.y + [self plottingArea].size.height  - [inValue doubleValue] * [[self pixelsPerYUnit] doubleValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
}
- (NSNumber *)unitsPerMajorX {
	double a,b;
	a = [[self pixelsPerXUnit] doubleValue];
	b = [[self minimumPixelsPerMajorGridLine] doubleValue];
	return [NSNumber numberWithDouble:a/b];
}
- (void)setUnitsPerMajorX:(NSNumber *)inValue {
}
- (NSNumber *)unitsPerMajorY {
	return [NSNumber numberWithInt:-1];
}
- (void)setUnitsPerMajorY:(NSNumber *)inValue {
}
@end
