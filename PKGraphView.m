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


#import "PKGraphView.h"

#import "PKChromatogramDataSeries.h"
#import "PKChromatogram.h"
#import "PKGCMSDocument.h"
#import "PKPeakRecord.h"
#import "PKGraphDataSeries.h"
#import "PKSpectrumDataSeries.h"

static void *DataSeriesObservationContext = (void *)1092;
static void *PeaksObservationContext = (void *)1093;
//static void *PropertyObservationContext = (void *)1094;
//static void *FrameObservationContext = (void *)1095;
static void *DataObservationContext = (void *)1096;
static void *BaselineObservationContext = (void *)1097;

NSString *const MyGraphView_DidBecomeFirstResponderNotification = @"MyGraphView_DidBecomeFirstResponderNotification"; 
NSString *const MyGraphView_DidResignFirstResponderNotification = @"MyGraphView_DidResignFirstResponderNotification";


@implementation PKGraphView

static float kMinimumWidthPlottingArea  = 100.0;
static float kMinimumHeightPlottingArea = 100.0;
static float kMinimumPaddingAroundPlottingArea = 5.0;
static float kGridLineWidth             = 0.5;
static float kMajorTickMarksWidth       = 5.0;
static float kMinorTickMarksWidth       = 2.5;
static int   kMajorTickMarksPerUnit     = 1;
static int   kMinorTickMarksPerUnit     = 5;
static float kMajorTickMarksLineWidth   = 0.5;
static float kMinorTickMarksLineWidth   = 0.5;
static int   kPaddingLabels             = 4;

#pragma mark Initialization & deallocation
+ (void)initialize {
	// Bindings support
	[self exposeBinding:@"dataSeries"];
	[self exposeBinding:@"peaks"];
//	[self exposeBinding:@"baseline"];
	
	// Dependent keys
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerXUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"xMaximum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMinimum"];	
	[self setKeys:[NSArray arrayWithObjects:@"origin",@"plottingArea",@"pixelsPerYUnit",@"trans",nil] triggerChangeNotificationsForDependentKey:@"yMaximum"];	
	[self setKeys:[NSArray arrayWithObjects:@"dataSeries", @"keyForXValue", nil] triggerChangeNotificationsForDependentKey:@"acceptableKeysForXValue"];	
	[self setKeys:[NSArray arrayWithObjects:@"dataSeries", @"keyForYValue", nil] triggerChangeNotificationsForDependentKey:@"acceptableKeysForYValue"];	
}

- (NSArray *)exposedBindings {
	return [NSArray arrayWithObjects:@"dataSeries", @"peaks", nil];
}

- (id)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];
    if (self) {
		// Support transparency
		[NSColor setIgnoresAlpha:NO];

        // Defaults
        origin = NSMakePoint(50.5,50.5);
        pixelsPerXUnit = [[NSNumber alloc] initWithFloat:20.0f];
		pixelsPerYUnit = [[NSNumber alloc] initWithFloat:10.0f];
        minimumPixelsPerMajorGridLine = [[NSNumber alloc] initWithFloat:25.0f];
        minimumPixelsPerXUnit = [[NSNumber alloc] initWithFloat:1.0f];
		minimumPixelsPerYUnit = [[NSNumber alloc] initWithFloat:1.0f];
        plottingArea = NSMakeRect(80.5,35.5,[self bounds].size.width-90.5,[self bounds].size.height-40.5);
        legendArea =   NSMakeRect([self bounds].size.width-200-10-10,[self bounds].size.height-18-10-5,200,18);
        selectedRect = NSMakeRect(0,0,0,0);
        xAxisLabelString = [[NSAttributedString alloc] initWithString:@""];
        yAxisLabelString = [[NSAttributedString alloc] initWithString:@""];
        
        NSDictionary *defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
		shouldDrawAxes =            [[defaultValues valueForKey:@"shouldDrawAxes"] boolValue];
		shouldDrawAxesHorizontal =  [[defaultValues valueForKey:@"shouldDrawAxesHorizontal"] boolValue];
		shouldDrawAxesVertical =    [[defaultValues valueForKey:@"shouldDrawAxesVertical"] boolValue];
		shouldDrawFrame =           [[defaultValues valueForKey:@"shouldDrawFrame"] boolValue];
		shouldDrawFrameLeft =       [[defaultValues valueForKey:@"shouldDrawFrameLeft"] boolValue];
		shouldDrawFrameBottom =     [[defaultValues valueForKey:@"shouldDrawFrameBottom"] boolValue];
		shouldDrawMajorTickMarks =  [[defaultValues valueForKey:@"shouldDrawMajorTickMarks"] boolValue];
		shouldDrawMajorTickMarksHorizontal = YES;
		shouldDrawMinorTickMarksHorizontal = YES;
		shouldDrawMajorTickMarksVertical =   YES;
		shouldDrawMinorTickMarksVertical =   YES;
		shouldDrawGrid =            [[defaultValues valueForKey:@"shouldDrawGrid"] boolValue];
		shouldDrawLabels =          [[defaultValues valueForKey:@"shouldDrawLabels"] boolValue];
		shouldDrawLegend =          [[defaultValues valueForKey:@"shouldDrawLegend"] boolValue];
		shouldDrawLabelsOnFrame =   [[defaultValues valueForKey:@"shouldDrawLabelsOnFrame"] boolValue];
		shouldDrawLabelsOnFrameLeft =   YES;
		shouldDrawLabelsOnFrameBottom = YES;
		shouldDrawShadow =          [[defaultValues valueForKey:@"shouldDrawShadow"] boolValue];
		
		backColor =         [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"backColor"]] retain];
		plottingAreaColor = [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"plottingAreaColor"]] retain];
		axesColor =         [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"axesColor"]] retain];
		frameColor =        [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"frameColor"]] retain];
		gridColor =         [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"gridColor"]] retain];
		labelsColor =       [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"labelsColor"]] retain];
		labelsOnFrameColor =[(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"labelsOnFrameColor"]] retain];
		legendAreaColor =   [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"legendAreaColor"]] retain];
		legendFrameColor =  [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"legendFrameColor"]] retain];
		baselineColor =     [(NSColor *)[NSUnarchiver unarchiveObjectWithData:[defaultValues valueForKey:@"baselineColor"]] retain];
				
        labelFont = [[NSFont systemFontOfSize:10] retain];
        legendFont = [[NSFont systemFontOfSize:10] retain];
        axesLabelFont = [[NSFont systemFontOfSize:10] retain];
        
		// Additions for Peacock
		shouldDrawBaseline = [[defaultValues valueForKey:@"shouldDrawBaseline"] boolValue];
		shouldDrawPeaks = [[defaultValues valueForKey:@"shouldDrawPeaks"] boolValue];
        selectedScan = 0;
        
        drawingMode = JKStackedDrawingMode;
    }
	return self;
}

- (void)dealloc {
	[self unbind:@"peaks"];
	[self unbind:@"dataSeries"];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [pixelsPerXUnit release];
    [pixelsPerYUnit release];
    [minimumPixelsPerMajorGridLine release];
    [xAxisLabelString release];
    [yAxisLabelString release];
    
    [backColor release];
    [plottingAreaColor release];
    [axesColor release];
    [frameColor release];
    [gridColor release];
    [labelsColor release];
    [labelsOnFrameColor release];
    [legendAreaColor release];
    [legendFrameColor release];
    [baselineColor release];

    [labelFont release];
    [legendFont release];
    [axesLabelFont release];

    
    [dataSeriesContainer release];
    [dataSeriesKeyPath release];
    [peaksContainer release];
    [peaksKeyPath release];
    
	[super dealloc];
}
#pragma mark -

#pragma mark NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    PKGraphView *copy = [[[self class] allocWithZone:zone] initWithFrame:[self frame]];
    
    // Copy/point to parameters of self
    [copy setOrigin:[self origin]];
    //etc. etc.
    
    //[copy setDelegate:[self delegate]];
    
    return copy;
}
#pragma mark -

#pragma mark Settings
- (NSDictionary *)settings {
    NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
    [mutDict setValue:NSStringFromPoint([self origin]) forKey:@"origin"];
    [mutDict setValue:[self pixelsPerXUnit] forKey:@"pixelsPerXUnit"];
    [mutDict setValue:[self pixelsPerYUnit] forKey:@"pixelsPerYUnit"];
    [mutDict setValue:[self minimumPixelsPerMajorGridLine] forKey:@"minimumPixelsPerMajorGridLine"];
    [mutDict setValue:[self minimumPixelsPerXUnit] forKey:@"minimumPixelsPerXUnit"];
    [mutDict setValue:[self minimumPixelsPerYUnit] forKey:@"minimumPixelsPerYUnit"];
    [mutDict setValue:NSStringFromRect([self plottingArea]) forKey:@"plottingArea"];
    [mutDict setValue:NSStringFromRect([self legendArea]) forKey:@"legendArea"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self xAxisLabelString]] forKey:@"xAxisLabelString"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self yAxisLabelString]] forKey:@"yAxisLabelString"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawAxes] forKey:@"shouldDrawAxes"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawAxesHorizontal] forKey:@"shouldDrawAxesHorizontal"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawAxesVertical] forKey:@"shouldDrawAxesVertical"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawFrame] forKey:@"shouldDrawFrame"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawFrameLeft] forKey:@"shouldDrawFrameLeft"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawFrameBottom] forKey:@"shouldDrawFrameBottom"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawMajorTickMarks] forKey:@"shouldDrawMajorTickMarks"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawMajorTickMarksHorizontal] forKey:@"shouldDrawMajorTickMarksHorizontal"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawMinorTickMarksHorizontal] forKey:@"shouldDrawMinorTickMarksHorizontal"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawMajorTickMarksVertical] forKey:@"shouldDrawMajorTickMarksVertical"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawMinorTickMarksVertical] forKey:@"shouldDrawMinorTickMarksVertical"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawGrid] forKey:@"shouldDrawGrid"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawLabels] forKey:@"shouldDrawLabels"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawLegend] forKey:@"shouldDrawLegend"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawLabelsOnFrame] forKey:@"shouldDrawLabelsOnFrame"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawLabelsOnFrameLeft] forKey:@"shouldDrawLabelsOnFrameLeft"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawLabelsOnFrameBottom] forKey:@"shouldDrawLabelsOnFrameBottom"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawShadow] forKey:@"shouldDrawShadow"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self backColor]] forKey:@"backColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self plottingAreaColor]] forKey:@"plottingAreaColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self axesColor]] forKey:@"axesColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self frameColor]] forKey:@"frameColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self gridColor]] forKey:@"gridColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self labelsColor]] forKey:@"labelsColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self labelsOnFrameColor]] forKey:@"labelsOnFrameColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self legendAreaColor]] forKey:@"legendAreaColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self legendFrameColor]] forKey:@"legendFrameColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self baselineColor]] forKey:@"baselineColor"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self labelFont]] forKey:@"labelFont"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self legendFont]] forKey:@"legendFont"];
    [mutDict setValue:[NSArchiver archivedDataWithRootObject:[self axesLabelFont]] forKey:@"axesLabelFont"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawBaseline] forKey:@"shouldDrawBaseline"];
    [mutDict setValue:[NSNumber numberWithBool:shouldDrawPeaks] forKey:@"shouldDrawPeaks"];
    [mutDict setValue:[NSNumber numberWithInt:drawingMode] forKey:@"drawingMode"];
    [mutDict autorelease];
    PKLogDebug(@"%@", [mutDict description]);
    return mutDict;
}

- (void)setSettings:(NSDictionary *)settings {
    [self setOrigin:NSPointFromString([settings valueForKey:@"origin"])];
    [self setPixelsPerXUnit:[settings valueForKey:@"pixelsPerXUnit"]];
    [self setPixelsPerYUnit:[settings valueForKey:@"pixelsPerYUnit"]];
    [self setMinimumPixelsPerMajorGridLine:[settings valueForKey:@"minimumPixelsPerMajorGridLine"]];
    [self setMinimumPixelsPerXUnit:[settings valueForKey:@"minimumPixelsPerXUnit"]];
    [self setMinimumPixelsPerYUnit:[settings valueForKey:@"minimumPixelsPerYUnit"]];
    [self setPlottingArea:NSRectFromString([settings valueForKey:@"plottingArea"])];
    [self setLegendArea:NSRectFromString([settings valueForKey:@"legendArea"])];
    [self setXAxisLabelString:(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"xAxisLabelString"]]];
    [self setYAxisLabelString:(NSAttributedString *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"yAxisLabelString"]]];
    [self setShouldDrawAxes:[[settings valueForKey:@"shouldDrawAxes"] boolValue]];
    [self setShouldDrawAxesHorizontal:[[settings valueForKey:@"shouldDrawAxesHorizontal"] boolValue]];
    [self setShouldDrawAxesVertical:[[settings valueForKey:@"shouldDrawAxesVertical"] boolValue]];
    [self setShouldDrawFrame:[[settings valueForKey:@"shouldDrawFrame"] boolValue]];
    [self setShouldDrawFrameLeft:[[settings valueForKey:@"shouldDrawFrameLeft"] boolValue]];
    [self setShouldDrawFrameBottom:[[settings valueForKey:@"shouldDrawFrameBottom"] boolValue]];
    [self setShouldDrawMajorTickMarks:[[settings valueForKey:@"shouldDrawMajorTickMarks"] boolValue]];
    [self setShouldDrawMajorTickMarksHorizontal:[[settings valueForKey:@"shouldDrawMajorTickMarksHorizontal"] boolValue]];
    [self setShouldDrawMinorTickMarksHorizontal:[[settings valueForKey:@"shouldDrawMinorTickMarksHorizontal"] boolValue]];
    [self setShouldDrawMajorTickMarksVertical:[[settings valueForKey:@"shouldDrawMajorTickMarksVertical"] boolValue]];
    [self setShouldDrawMinorTickMarksVertical:[[settings valueForKey:@"shouldDrawMinorTickMarksVertical"] boolValue]];
    [self setShouldDrawGrid:[[settings valueForKey:@"shouldDrawGrid"] boolValue]];
    [self setShouldDrawLabels:[[settings valueForKey:@"shouldDrawLabels"] boolValue]];
    [self setShouldDrawLegend:[[settings valueForKey:@"shouldDrawLegend"] boolValue]];
    [self setShouldDrawLabelsOnFrame:[[settings valueForKey:@"shouldDrawLabelsOnFrame"] boolValue]];
    [self setShouldDrawLabelsOnFrameLeft:[[settings valueForKey:@"shouldDrawLabelsOnFrameLeft"] boolValue]];
    [self setShouldDrawLabelsOnFrameBottom:[[settings valueForKey:@"shouldDrawLabelsOnFrameBottom"] boolValue]];
    [self setShouldDrawShadow:[[settings valueForKey:@"shouldDrawShadow"] boolValue]];
    [self setBackColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"backColor"]]];
    [self setPlottingAreaColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"plottingAreaColor"]]];
    [self setAxesColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"axesColor"]]];
    [self setFrameColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"frameColor"]]];
    [self setGridColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"gridColor"]]];
    [self setLabelsColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"labelsColor"]]];
    [self setLabelsOnFrameColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"labelsOnFrameColor"]]];
    [self setLegendAreaColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"legendAreaColor"]]];
    [self setLegendFrameColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"legendFrameColor"]]];
    [self setBaselineColor:(NSColor *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"baselineColor"]]];
    [self setLabelFont:(NSFont *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"labelFont"]]];
    [self setLegendFont:(NSFont *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"legendFont"]]];
    [self setAxesLabelFont:(NSFont *)[NSUnarchiver unarchiveObjectWithData:[settings valueForKey:@"axesLabelFont"]]];
    [self setShouldDrawBaseline:[[settings valueForKey:@"shouldDrawBaseline"] boolValue]];
    [self setShouldDrawPeaks:[[settings valueForKey:@"shouldDrawPeaks"] boolValue]];
    [self setDrawingMode:[[settings valueForKey:@"drawingMode"] intValue]];
}

- (IBAction)saveSettings:(id)sender {
    NSSavePanel *sp = [NSSavePanel savePanel];
    [sp setMessage:NSLocalizedString(@"Choose a location for saving the current settings.", @"")];
    if ([sp runModal] == NSFileHandlingPanelOKButton) {
        if (![[self settings] writeToURL:[sp URL] atomically:YES]) {
            NSBeep();
        }
    }
}

- (IBAction)restoreSettings:(id)sender {
    NSOpenPanel *op = [NSOpenPanel openPanel];
    [op setMessage:NSLocalizedString(@"Choose a file containing settings.", @"")];
    if ([op runModal] == NSFileHandlingPanelOKButton) {
        [self setSettings:[NSDictionary dictionaryWithContentsOfURL:[op URL]]];
    }
}
#pragma mark -

#pragma mark Drawing Routines
- (void)drawRect:(NSRect)rect {
    // Draw common elements here
    
    // Calculate transforms
    [self calculateCoordinateConversions];

	// Fancy shadow effects...
	NSShadow *noShadow = [[NSShadow alloc] init];
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowBlurRadius:10];
	[shadow setShadowOffset:NSMakeSize(6,-6)];
		
	// Background colour
	[noShadow set];
	[[self backColor] set];
	[[NSBezierPath bezierPathWithRect:[self bounds]] fill];

	// Background colour plottingArea (with shadow)
	// Draw shadow with focusring color if firstResponder
	if (([[self window] isKeyWindow]) && ([[self window] firstResponder] == self) && ([[NSGraphicsContext currentContext] isDrawingToScreen])) {
		[shadow setShadowColor:[NSColor keyboardFocusIndicatorColor]];
        [shadow set]; 	    
    } else if ([self shouldDrawShadow]) {
    	[shadow set]; 	    
    } else {
        [noShadow set];
    }
    [[self plottingAreaColor] set];        
    
	if (NSIntersectsRect([self plottingArea],rect))
		[[NSBezierPath bezierPathWithRect:[self plottingArea]] fill];
	
	// Frame around plottingArea	
	[noShadow set];
	[[self frameColor] set];
	if (NSIntersectsRect([self plottingArea],rect))
		[[NSBezierPath bezierPathWithRect:[self plottingArea]] stroke];

    if ([[self dataSeries] count] == 0) {
        [noShadow release];
        [shadow release];
        return;
    }
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
        
        
        //NSAssert([[self dataSeries] count] >= 1, @"No dataSeries to draw.");
        int dataSeriesCount;
        int i;
        id object;
        
        dataSeriesCount = [[self dataSeries] count];
        for (i = 0; i < dataSeriesCount; i++) {
            object = [[self dataSeries] objectAtIndex:i];
            if ([object respondsToSelector:@selector(plotDataWithTransform:inView:)]) {
                [object plotDataWithTransform:[self transformForDataSeriesAtIndex:i] inView:self];
            }
        }
        
        // Draw line for selected scan
        NSPoint point;
        if (([self selectedScan] > 0) && ([[NSGraphicsContext currentContext] isDrawingToScreen])) {
            if ([[self window] firstResponder] == self) {
                [[NSColor alternateSelectedControlColor] set];
            } else {
                [[NSColor secondarySelectedControlColor] set];
            }
            
            if ([keyForXValue isEqualToString:@"Scan"]) {
                point = [[self transformGraphToScreen] transformPoint:NSMakePoint([self selectedScan]*1.0, 0)];                
            } else if ([keyForXValue isEqualToString:@"Time"]) {
                float thetime = [(PKGCMSDocument *)[[[[self dataSeries] objectAtIndex:0] chromatogram] document] timeForScan:selectedScan];
                point = [[self transformGraphToScreen] transformPoint:NSMakePoint(thetime, 0)];
            }
            
            NSBezierPath *selectedScanBezierPath = [NSBezierPath bezierPath];
            [selectedScanBezierPath moveToPoint:NSMakePoint(point.x, [self plottingArea].origin.y)];
            [selectedScanBezierPath lineToPoint:NSMakePoint(point.x, [self plottingArea].origin.y+[self plottingArea].size.height)];
            [selectedScanBezierPath stroke];        
        }
        
    }
    
	[NSGraphicsContext restoreGraphicsState];
    
    [NSGraphicsContext saveGraphicsState];	

	if ([self shouldDrawFrame]) {
        [self drawFrame];
        [[NSBezierPath bezierPathWithRect:[self plottingArea]] addClip];
        if ([self shouldDrawMajorTickMarks]) {
            [self drawMajorTickMarksOnFrame];
            if ([self shouldDrawMinorTickMarks])
                [self drawMinorTickMarksOnFrame];
        }
        [NSGraphicsContext restoreGraphicsState];
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

- (void)drawGrid {
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
	[gridPath setLineWidth:kGridLineWidth];
	[[self gridColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[gridPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [gridPath release];
}

- (void)drawMinorTickMarks {
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	//  horizontale tickmarks
    if (shouldDrawAxesHorizontal) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
        
        start = (-[self origin].x/stepInPixels)*kMinorTickMarksPerUnit-3;
        end = start + ([self frame].size.width/stepInPixels)*kMinorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/kMinorTickMarksPerUnit+[self origin].x,[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/kMinorTickMarksPerUnit+[self origin].x,[self origin].y+kMinorTickMarksWidth)];
        }
    }
    
	// En de Verticale tickmarks
	if (shouldDrawAxesVertical) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
        
        start = (-[self origin].y/stepInPixels)*kMinorTickMarksPerUnit-3;
        end = start + ([self frame].size.height/stepInPixels)*kMinorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint([self origin].x,i*stepInPixels/kMinorTickMarksPerUnit+[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint([self origin].x+kMinorTickMarksWidth, i*stepInPixels/kMinorTickMarksPerUnit+[self origin].y)];
        }	        
    }
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:kMinorTickMarksLineWidth];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMajorTickMarks {
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
    if (shouldDrawAxesHorizontal) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
        
        start = (-[self origin].x/stepInPixels)*kMajorTickMarksPerUnit-3;
        end = start + ([self frame].size.width/stepInPixels)*kMajorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/kMajorTickMarksPerUnit+[self origin].x,[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/kMajorTickMarksPerUnit+[self origin].x,[self origin].y+kMajorTickMarksWidth)];
        }
	}
    
	// En de horizontale tickmarks
    if (shouldDrawAxesVertical) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
        
        start = (-[self origin].y/stepInPixels)*kMajorTickMarksPerUnit-3;
        end = start + ([self frame].size.height/stepInPixels)*kMajorTickMarksPerUnit +3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint([self origin].x,i*stepInPixels/kMajorTickMarksPerUnit+[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint([self origin].x+kMajorTickMarksWidth, i*stepInPixels/kMajorTickMarksPerUnit+[self origin].y)];
        }	
    }	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:kMajorTickMarksLineWidth];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMinorTickMarksOnFrame{
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
    if (shouldDrawFrameBottom & shouldDrawMinorTickMarksHorizontal) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
        
        start = (([self plottingArea].origin.x-[self origin].x)/stepInPixels)*kMinorTickMarksPerUnit-3;
        end = start + ([self plottingArea].size.width/stepInPixels)*kMinorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/kMinorTickMarksPerUnit+[self origin].x,[self plottingArea].origin.y)];
            [tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/kMinorTickMarksPerUnit+[self origin].x,[self plottingArea].origin.y+kMinorTickMarksWidth)];
        }
	}
    
	// En de horizontale tickmarks
    if (shouldDrawFrameLeft & shouldDrawMinorTickMarksVertical) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
        
        start = (([self plottingArea].origin.y-[self origin].y)/stepInPixels)*kMinorTickMarksPerUnit-3;
        end = start + ([self plottingArea].size.height/stepInPixels)*kMinorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint([self plottingArea].origin.x,i*stepInPixels/kMinorTickMarksPerUnit+[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint([self plottingArea].origin.x+kMinorTickMarksWidth, i*stepInPixels/kMinorTickMarksPerUnit+[self origin].y)];
        }	
	}
    
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:kMinorTickMarksLineWidth];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawMajorTickMarksOnFrame{
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSBezierPath *tickMarksPath = [[NSBezierPath alloc] init];
	
	// Verticale tickmarks
    if (shouldDrawFrameBottom & shouldDrawMajorTickMarksHorizontal) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
        
        start = (([self plottingArea].origin.x-[self origin].x)/stepInPixels)*kMajorTickMarksPerUnit-3;
        end = start + ([self plottingArea].size.width/stepInPixels)*kMajorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint(i*stepInPixels/kMajorTickMarksPerUnit+[self origin].x,[self plottingArea].origin.y)];
            [tickMarksPath lineToPoint:NSMakePoint(i*stepInPixels/kMajorTickMarksPerUnit+[self origin].x,[self plottingArea].origin.y+kMajorTickMarksWidth)];
        }
    }
	
	// En de horizontale tickmarks
    if (shouldDrawFrameLeft & shouldDrawMajorTickMarksVertical) {
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
        
        start = (([self plottingArea].origin.y-[self origin].y)/stepInPixels)*kMajorTickMarksPerUnit-3;
        end = start + ([self plottingArea].size.height/stepInPixels)*kMajorTickMarksPerUnit+3;
        for (i=start; i <= end; i++) {
            [tickMarksPath moveToPoint:NSMakePoint([self plottingArea].origin.x,i*stepInPixels/kMajorTickMarksPerUnit+[self origin].y)];
            [tickMarksPath lineToPoint:NSMakePoint([self plottingArea].origin.x+kMajorTickMarksWidth, i*stepInPixels/kMajorTickMarksPerUnit+[self origin].y)];
        }	
    }
	
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[tickMarksPath setLineWidth:kMajorTickMarksLineWidth];
	[[self axesColor] set];
	
	// Met stroke wordt de bezierpath getekend.
	[tickMarksPath stroke];
	
	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [tickMarksPath release];
}

- (void)drawLegend {
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
	
    // Set legendarea to right size
    // resize legend area to fit all entries
    NSRect newLegendArea = [self legendArea];
    newLegendArea.size.height = [[self dataSeries] count] * 18;
    newLegendArea.origin.y = newLegendArea.origin.y - (newLegendArea.size.height - [self legendArea].size.height);
    [self setLegendArea:newLegendArea];
    
    
	// Achtergrondkleur legendArea (met schaduw)
    if ([self shouldDrawShadow]) {
       	[shadow set]; 	 
    }
	[[self legendAreaColor] setFill];
	[[NSBezierPath bezierPathWithRect:[self legendArea]] fill];

	[noShadow set];

    // Draw inside the legendArea
    [NSGraphicsContext saveGraphicsState];	
	[[NSBezierPath bezierPathWithRect:[self legendArea]] addClip];
	
	[attrs setValue:[self legendFont] forKey:NSFontAttributeName];
    NSBezierPath *line = [NSBezierPath bezierPath];
    NSString *seriesTitle = nil;
    
	if ([[self dataSeries] count] > 0) {
		for (i=0;i<[[self dataSeries] count]; i++) {
            [line removeAllPoints];
         //   PKLogDebug(@"legend seriesTitle: %@",[[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesTitle"]);
            if ([[[[self dataSeries] objectAtIndex:i] verticalScale] floatValue] != 1.0f) {
                seriesTitle = [NSString stringWithFormat:@"%@ (%.1f%C)",[[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesTitle"],[[[[self dataSeries] objectAtIndex:i] verticalScale] floatValue],0x00D7];                
            } else {
                seriesTitle = [[[self dataSeries] objectAtIndex:i] valueForKey:@"seriesTitle"];
            }
            if (!seriesTitle) {
                seriesTitle = @"Untitled Series";
            }
			string = [[NSMutableAttributedString alloc] initWithString:seriesTitle attributes:attrs];
            NSAssert(string,@"string is nil");
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

- (void)drawTitles {
	
	// Werkt, maar nu niet direct een schoonheidsprijs waard!! ;-)
	[[self titleString] drawAtPoint:NSMakePoint(([self bounds].size.width - [[self titleString] size].width)/2,([self bounds].size.height - NSMaxY([self plottingArea]))/2 - [[self titleString] size].height/2 + NSMaxY([self plottingArea]))];
	if ([self shouldDrawLabelsOnFrame]) {
		[[self xAxisLabelString] drawAtPoint:NSMakePoint(NSMaxX([self plottingArea])-[[self xAxisLabelString] size].width,_lowestYOriginLabelsXAxis-kPaddingLabels-[[self xAxisLabelString] size].height)];
	} else {
		[[self xAxisLabelString] drawAtPoint:NSMakePoint(NSMaxX([self plottingArea])-[[self xAxisLabelString] size].width,NSMinY([self plottingArea])-[[self xAxisLabelString] size].height-kPaddingLabels)];
	}
	
	// Y axis label
	[NSGraphicsContext saveGraphicsState];	

	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform rotateByDegrees:90.0];
    [transform concat];
	if ([self shouldDrawLabelsOnFrame]) {
		[[self yAxisLabelString] drawAtPoint:NSMakePoint(NSMaxY([self plottingArea])-[[self yAxisLabelString] size].width,-_lowestXOriginLabelsYAxis+kPaddingLabels)]; // i.p.v. 20 eigenlijk liever grootte van labels on frame + 4
	} else {
		[[self yAxisLabelString] drawAtPoint:NSMakePoint(NSMaxY([self plottingArea])-[[self yAxisLabelString] size].width,-NSMinX([self plottingArea])+kPaddingLabels)];
	}

	[NSGraphicsContext restoreGraphicsState];
	
}

- (void)drawLabels {
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%g";
	NSMutableString *label = @"";
	
	[attrs setValue:[self axesLabelFont] forKey:NSFontAttributeName];
	[attrs setValue:[self axesColor] forKey:NSForegroundColorAttributeName];
    [attrs2 setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
    [attrs2 setValue:[NSFont fontWithName:[[self axesLabelFont] fontName] size:[[self axesLabelFont] pointSize]*0.8] forKey:NSFontAttributeName];
	[attrs2 setValue:[self axesColor] forKey:NSForegroundColorAttributeName];
//	[attrs setValue:[NSFont systemFontOfSize:10] forKey:NSFontAttributeName];
//    [attrs2 setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
//    [attrs2 setValue:[NSFont systemFontOfSize:8] forKey:NSFontAttributeName];
    
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
        NSAssert(label,@"label is nil");
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
        NSAssert(string,@"string is nil");
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(i*stepInUnits,0.)];
		pointToDraw.x = pointToDraw.x - stringSize.width/2;
		pointToDraw.y = pointToDraw.y - stringSize.height - kPaddingLabels;
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
        NSAssert(label,@"label is nil");
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
        NSAssert(string,@"label is nil");
		stringSize = [string size];
		pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(0.,i*stepInUnits)];
		pointToDraw.x = pointToDraw.x - stringSize.width - kPaddingLabels;
		pointToDraw.y = pointToDraw.y - stringSize.height/2;
		[string drawAtPoint:pointToDraw];
		[string release];
        // Ugly fix for overlap
        if (stringSize.width > stepInPixels) {
            i++;
        }
        
	}
}

- (void)drawLabelsOnFrame {
	NSMutableAttributedString *string = [[[NSMutableAttributedString alloc] initWithString:@""] autorelease];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	NSMutableDictionary *attrs2 = [NSMutableDictionary dictionary];
	int i, start, end;
	float stepInUnits, stepInPixels;
	NSSize stringSize;
	NSPoint pointToDraw;
	NSString *formatString = @"%g";
	NSMutableString *label = @"";
	
	[attrs setValue:[self axesLabelFont] forKey:NSFontAttributeName];
  	[attrs setValue:[self axesColor] forKey:NSForegroundColorAttributeName];
    [attrs2 setValue:[NSNumber numberWithInt:1] forKey:NSSuperscriptAttributeName];
    [attrs2 setValue:[NSFont fontWithName:[[self axesLabelFont] fontName] size:[[self axesLabelFont] pointSize]*0.8] forKey:NSFontAttributeName];
	[attrs2 setValue:[self axesColor] forKey:NSForegroundColorAttributeName];

	// Labels op X-as
    _lowestYOriginLabelsXAxis = [self plottingArea].origin.y;
   if (shouldDrawLabelsOnFrameBottom) {        
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerXUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerXUnit] floatValue];
 
        start = ceil((-[self origin].x + [self plottingArea].origin.x)/stepInPixels);
        end = floor((-[self origin].x + [self plottingArea].origin.x + [self plottingArea].size.width)/stepInPixels);
        for (i=start; i <= end; i++) {  
            label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
            NSAssert(label,@"label is nil");
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
            NSAssert(string,@"string is nil");
            stringSize = [string size];
            pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(i*stepInUnits,0.)];
            pointToDraw.x = pointToDraw.x - stringSize.width/2;
            pointToDraw.y = [self plottingArea].origin.y - stringSize.height - kPaddingLabels;
            if (pointToDraw.y < _lowestYOriginLabelsXAxis) {
                _lowestYOriginLabelsXAxis = pointToDraw.y;
            }
            [string drawAtPoint:pointToDraw];
            [string release];
            // Ugly fix for overlap
            if (stringSize.width > stepInPixels) {
                i++;
            }
        }
    }
	
	// Labels op Y-as
    _lowestXOriginLabelsYAxis = [self plottingArea].origin.x;
    if (shouldDrawLabelsOnFrameLeft) {        
        stepInUnits = [self unitsPerMajorGridLine:[[self pixelsPerYUnit] floatValue]];
        stepInPixels = stepInUnits * [[self pixelsPerYUnit] floatValue];
        
        start = ceil((-[self origin].y + [self plottingArea].origin.y)/stepInPixels);
        end = floor((-[self origin].y + [self plottingArea].origin.y + [self plottingArea].size.height)/stepInPixels);
        for (i=start; i <= end; i++) {
            NSAssert(formatString,@"formatString is nil");
            label = [NSMutableString localizedStringWithFormat:formatString, i*stepInUnits];
            NSAssert(label,@"label is nil");
            if ([label rangeOfString:@"e"].location != NSNotFound) {
                [label replaceOccurrencesOfString:@"e+0" withString:@"e" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
                [label replaceOccurrencesOfString:@"e-0" withString:@"e-" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
                [label replaceOccurrencesOfString:@"e" withString:[NSString stringWithUTF8String:"\u22c510"] options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];                
                [label replaceOccurrencesOfString:@"+" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [label length])];
                NSAssert(label,@"label is nil");
                string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs]; 
                NSRange tenRange = [label rangeOfString:[NSString stringWithUTF8String:"\u22c510"]];
                NSRange superRange = NSMakeRange(tenRange.location+tenRange.length, [label length]-tenRange.location-tenRange.length);
                [string setAttributes:attrs2 range:superRange];
            } else {
                string = [[NSMutableAttributedString alloc] initWithString:label attributes:attrs];            
            }
            NSAssert(string,@"label is nil");
            stringSize = [string size];
            pointToDraw = [[self transformGraphToScreen] transformPoint:NSMakePoint(0.,i*stepInUnits)];
            pointToDraw.x = [self plottingArea].origin.x - stringSize.width - kPaddingLabels;
            if (pointToDraw.x < _lowestXOriginLabelsYAxis) {
                _lowestXOriginLabelsYAxis = pointToDraw.x;
            }
            pointToDraw.y = pointToDraw.y - stringSize.height/2;
            [string drawAtPoint:pointToDraw];
            [string release];
            // Ugly fix for overlap
            if (stringSize.height > stepInPixels) {
                i++;
            }
            
        }
    }
}

- (void)drawAxes {
	NSBezierPath *axesPath = [[NSBezierPath alloc] init];
	
	// De X as.
    if (shouldDrawAxesHorizontal) {
        [axesPath moveToPoint:NSMakePoint(0.,[self origin].y)];
        [axesPath lineToPoint:NSMakePoint([self frame].size.width,[self origin].y)];        
    }
	
	// En de Y as.
    if (shouldDrawAxesVertical) {
        [axesPath moveToPoint:NSMakePoint([self origin].x,0.)];
        [axesPath lineToPoint:NSMakePoint([self origin].x,[self frame].size.height)];        
    }

	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[axesPath setLineWidth:1.0];
	[[self axesColor] set];

	// Met stroke wordt de bezierpath getekend.
	[axesPath stroke];

	// We hebben axesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [axesPath release];
}

- (void)drawFrame{
    NSBezierPath *framesPath = [[NSBezierPath alloc] init];
	
	// De X as.
    if (shouldDrawFrameBottom) {
        [framesPath moveToPoint:[self plottingArea].origin];
        [framesPath lineToPoint:NSMakePoint([self plottingArea].origin.x+[self plottingArea].size.width,[self plottingArea].origin.y)];        
    }
	
	// En de Y as.
    if (shouldDrawFrameLeft) {
        [framesPath moveToPoint:[self plottingArea].origin];
        [framesPath lineToPoint:NSMakePoint([self plottingArea].origin.x,[self plottingArea].origin.y+[self plottingArea].size.height)];
    }
    
	// Hier stellen we in hoe de lijnen eruit moeten zien.
	[framesPath setLineWidth:1.0];
//#warning [BUG] Wrong color used?
    // No, because it is just a displaced axis after all, frameColor should be used for the rectangle around the graph
	[[self axesColor] set];
    
	// Met stroke wordt de bezierpath getekend.
	[framesPath stroke];
    
	// We hebben framesPath ge-alloc-ed, dus ruimen we die nog even op hier.
    [framesPath release];    
}

- (NSString *)view:(NSView *)view
  stringForToolTip:(NSToolTipTag)tag
             point:(NSPoint)point
          userData:(void *)userData{
	id peak = [[self peaks] objectAtIndex:(int)userData];
	return [NSString stringWithFormat:NSLocalizedString(@"Peak no. %d\n%@",@"Tiptool for peak number and label."), userData+1, [peak valueForKey:@"label"]];
}

- (void)refresh {
	PKLogDebug(@"Refresh - %@",[self description]);
    [self setNeedsDisplay:YES];
}
#pragma mark -

#pragma mark Printing
- (BOOL)knowsPageRange:(NSRangePointer)aRange {
    aRange -> location = 1;
    aRange -> length = 1;
    return YES;
}

- (NSRect)rectForPage:(NSInteger)pageNumber {
    if (pageNumber == 1) {
        NSSize paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
        return NSMakeRect(0.0f, 0.0f, paperSize.width, paperSize.height);
    } else {
        return NSZeroRect;
    }
}
#pragma mark -

#pragma mark Action Routines
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
	float x,y,avg;
	x = [[self pixelsPerXUnit] floatValue];
	y = [[self pixelsPerYUnit] floatValue];
	avg = (x+y)/2;
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:avg]];
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:avg]];
}


- (IBAction)showAll:(id)sender {
    [self setMinimumPixelsPerXUnit:[NSNumber numberWithFloat:0.0f]];
    [self setMinimumPixelsPerYUnit:[NSNumber numberWithFloat:0.0f]];
//    PKLogDebug(@"self: %@ sender: %@ count: %d",[self description],[sender description],[[self dataSeries] count]);
	int i, count;
	NSRect totRect, newRect;
	PKGraphDataSeries *mgds;
	
    totRect = NSZeroRect;
    
	// Voor iedere dataserie wordt de grootte in grafiek-coordinaten opgevraagd en de totaal omvattende rect bepaald
	count = [[self dataSeries] count];
    float maxTotal = 0.0f;
	for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
        if ([mgds isKindOfClass:[PKChromatogramDataSeries class]]) {
            if ([[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity] > maxTotal) {
                maxTotal = [[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity];
            }
        }
    }
    for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
		newRect = [mgds boundingRect];
        switch (drawingMode) {
        case JKStackedDrawingMode:
            // A little exta room to make room for labels
            if ([mgds isKindOfClass:[PKChromatogramDataSeries class]]) {
                float thisTotal = [[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity];
                [mgds setVerticalScale:[NSNumber numberWithFloat:maxTotal/thisTotal]];
                newRect.size.height = newRect.size.height*1.4*count;
            } else if ([mgds isKindOfClass:[PKSpectrumDataSeries class]]) {
                newRect.size.height = newRect.size.height*1.3*count;
                if (newRect.origin.y < 0.0) {
                    newRect.origin.y = newRect.origin.y * 1.3;
                }
                newRect.origin.x = newRect.origin.x - 2.0;
                newRect.size.width = newRect.size.width + 4.0;
            }
            break;
        case JKNormalDrawingMode:
        default:
            // A little exta room to make room for labels
            if ([mgds isKindOfClass:[PKChromatogramDataSeries class]]) {
                newRect.size.height = newRect.size.height*1.4;
            } else if ([mgds isKindOfClass:[PKSpectrumDataSeries class]]) {
                newRect.size.height = newRect.size.height*1.3;
                if (newRect.origin.y < 0.0) {
                    newRect.origin.y = newRect.origin.y * 1.3;
                }
                newRect.origin.x = newRect.origin.x - 2.0;
                newRect.size.width = newRect.size.width + 4.0;
            }
            break;
        }
		totRect = NSUnionRect(totRect, newRect);
	}
    if ((totRect.size.height <= 0.0f) || (totRect.size.width <= 0.0f)) {
        return;
    }
        
//    PKLogDebug(@"zooming to new rect");
	[self zoomToRect:totRect];
    [self setMinimumPixelsPerXUnit:[self pixelsPerXUnit]];
    [self setMinimumPixelsPerYUnit:[self pixelsPerYUnit]];
}

- (void)scaleVertically 
{
//    PKLogDebug(@"scaleVertically");
   	int i, count;
	PKGraphDataSeries *mgds;
	
	// Voor iedere dataserie wordt de grootte in grafiek-coordinaten opgevraagd en de totaal omvattende rect bepaald
	count = [[self dataSeries] count];
    float maxTotal = 0.0f;
	for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
        if ([mgds isKindOfClass:[PKChromatogramDataSeries class]]) {
            if ([[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity] > maxTotal) {
                maxTotal = [[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity];
            }
        }
    }
    for (i=0; i <  count; i++) {
		mgds=[[self dataSeries] objectAtIndex:i];
        switch (drawingMode) {
            case JKStackedDrawingMode:
                // A little exta room to make room for labels
                if ([mgds isKindOfClass:[PKChromatogramDataSeries class]]) {
                    float thisTotal = [[(PKChromatogramDataSeries *)mgds chromatogram] maxTotalIntensity];
                    [mgds setVerticalScale:[NSNumber numberWithFloat:maxTotal/thisTotal]];
                } 
                break;
            case JKNormalDrawingMode:
            default:
                 break;
        }
	}
     
    [self setNeedsDisplay:YES];
}
#pragma mark -

#pragma mark Helper Routines
- (void)calculateCoordinateConversions {
    @try {
        NSAffineTransform *translationMatrix, *scalingMatrix, *transformationMatrix, *invertMatrix;
        
        // We rekenen eerst in twee aparte matrices uit hoe de verplaatsing en schaling gedaan moet worden.
        
        // Als de oorsprong elders ligt, moeten we daarvoor corrigeren.
        translationMatrix = [NSAffineTransform transform];
        [translationMatrix translateXBy:[self origin].x yBy:[self origin].y];
        
        // De waarden omrekeningen naar pixels op het scherm.
         scalingMatrix = [NSAffineTransform transform];
         if ([[self pixelsPerXUnit] floatValue] <= 0.0f) {
             [self setPixelsPerXUnit:[NSNumber numberWithFloat:1.0f]];
         }
         if ([[self pixelsPerYUnit] floatValue] <= 0.0f) {
             [self setPixelsPerYUnit:[NSNumber numberWithFloat:1.0f]];
         }
         NSAssert([[self pixelsPerXUnit] floatValue] > 0, @"pixelsPerXUnit = 0");
         NSAssert([[self pixelsPerYUnit] floatValue] > 0, @"pixelsPerYUnit = 0");
         [scalingMatrix scaleXBy:[[self pixelsPerXUnit] floatValue] yBy:[[self pixelsPerYUnit] floatValue]];
        
        // In transformationMatrix combineren we de matrices. Eerst de verplaatsing, dan schalen.
        transformationMatrix = [NSAffineTransform transform];
        [transformationMatrix appendTransform:scalingMatrix];
        [transformationMatrix appendTransform:translationMatrix];
        [self setTransformGraphToScreen:transformationMatrix];
        
        // We zullen ook terug van data serie coordinaten naar scherm-coordinaten willen rekenen. Het zou niet effectief zijn om dat iedere keer dat we dit nodig hebben de inverse matrix uit te rekenen. Daarom hier 1 keer en vervolgens bewaren.
        invertMatrix = [transformationMatrix copy];
        [invertMatrix invert];
        [self setTransformScreenToGraph:invertMatrix];
        [invertMatrix release];
    }
    @catch ( NSException *e ) {
        PKLogError([e description]);
    }
    @finally {
        //
    }
}

- (NSAffineTransform *)transformForDataSeriesAtIndex:(int)index {
    int dataSeriesCount;
    NSAffineTransform *transform = nil;
    PKGraphDataSeries *aDataSeries = [[self dataSeries] objectAtIndex:index];

    switch (drawingMode) {
        case JKStackedDrawingMode:
            dataSeriesCount = [[self dataSeries] count];
            transform = [[NSAffineTransform alloc] init];
            [transform translateXBy:0.0 yBy:index*([self plottingArea].size.height/dataSeriesCount)];
            [transform prependTransform:[self transformGraphToScreen]];
            [transform scaleXBy:1.0 yBy:[[aDataSeries verticalScale] floatValue]];
            [transform translateXBy:0.0 yBy:[[aDataSeries verticalOffset] floatValue]];
            return [transform autorelease];

            break;
        case JKNormalDrawingMode:
        default:
            transform = [[NSAffineTransform alloc] init];
            [transform prependTransform:[self transformGraphToScreen]];
            [transform scaleXBy:1.0 yBy:[[aDataSeries verticalScale] floatValue]];
            [transform translateXBy:0.0 yBy:[[aDataSeries verticalOffset] floatValue]];
            return [transform autorelease]; // Returning a copy to prevent the receiver from mucking around with ours
            break;
    }
    
    // Not that we'd ever get here...
    return [[[self transformGraphToScreen] copy] autorelease];
}

- (float)unitsPerMajorGridLine:(float)pixelsPerUnit {
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
//    int seriesNumber;
//    
//    switch (drawingMode) {
//        case JKStackedDrawingMode:
//            // starts in series number 
//            seriesNumber = (((aRect.origin.y - [self plottingArea].origin.y)/[self plottingArea].size.height) * [[self dataSeries] count])/1;
//            PKLogDebug(@"seriesNumber %d",seriesNumber);
//            aRect.origin.y =  aRect.origin.y - seriesNumber * ([self plottingArea].size.height / [[self dataSeries] count]);
//            PKLogDebug(@"aRect.origin.y %g", aRect.origin.y);
//            break;
//        case JKNormalDrawingMode:
//        default:            
//            break;
//    }
    [self setPixelsPerXUnit:[NSNumber numberWithFloat:(([self plottingArea].size.width  )/aRect.size.width)]];
    [self setPixelsPerYUnit:[NSNumber numberWithFloat:(([self plottingArea].size.height )/aRect.size.height)]];
    
    newOrig.x = [self plottingArea].origin.x - aRect.origin.x * [[self pixelsPerXUnit] floatValue];
    newOrig.y = [self plottingArea].origin.y - aRect.origin.y * [[self pixelsPerYUnit] floatValue];
    [self setOrigin:newOrig];
    [self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (void)zoomToRectInView:(NSRect)aRect { // aRect in view coördinaten
	NSRect newRect;
		
	newRect.origin = [[self transformScreenToGraph] transformPoint:aRect.origin];
	newRect.size = [[self transformScreenToGraph] transformSize:aRect.size];
//	PKLogDebug(@"zoomToRectInView x %f, y %f, w %f, h %f",newRect.origin.x, newRect.origin.y, newRect.size.width, newRect.size.height);
	[self zoomToRect:newRect];

}

- (void)zoomIn{
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] - xWidth/8]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] + xWidth/8]];
	
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] - yWidth/8]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] + yWidth/8]];
}

- (void)zoomOut {
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - xWidth/4]];
	
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] - yWidth/4]];
}

- (void)moveLeft {
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] - xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - xWidth/4]];
}

- (void)moveRight {
	float xWidth = [[self xMaximum] floatValue] - [[self xMinimum] floatValue];
	[self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] + xWidth/4]];
	[self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] + xWidth/4]];
}

- (void)moveUp {
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] + yWidth/4]];
}

- (void)moveDown {
	float yWidth = [[self yMaximum] floatValue] - [[self yMinimum] floatValue];
	[self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] - yWidth/4]];
	[self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] - yWidth/4]];
}

- (void)selectNextPeak {
	if (([peaksContainer selectionIndex] != NSNotFound) & ([peaksContainer selectionIndex] != [[self peaks] count]-1)) {
		[peaksContainer setSelectionIndex:[peaksContainer selectionIndex]+1];		
	} else {
		[peaksContainer setSelectionIndex:0];			
	}
	[self setNeedsDisplayInRect:[self plottingArea]];
}

- (void)selectPreviousPeak {
	if (([peaksContainer selectionIndex] != NSNotFound) & ([peaksContainer selectionIndex] != 0)) {
		[peaksContainer setSelectionIndex:[peaksContainer selectionIndex]-1];
	} else {
		[peaksContainer setSelectionIndex:[[self peaks] count]-1];
	}
	[self setNeedsDisplayInRect:[self plottingArea]];
}

- (void)selectNextScan {
    [self setSelectedScan:[self selectedScan]+1];
    if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
        [delegate showSpectrumForScan:[self selectedScan]];
    }     
}

- (void)selectPreviousScan {
    [self setSelectedScan:[self selectedScan]-1];
    if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
        [delegate showSpectrumForScan:[self selectedScan]];
    }     
}
#pragma mark -

#pragma mark Mouse Interaction Management
- (void)resetCursorRects {
	[self addCursorRect:[self frame] cursor:[NSCursor arrowCursor]];
	[self addCursorRect:[self plottingArea] cursor:[NSCursor crosshairCursor]];
    [self addCursorRect:NSMakeRect([self plottingArea].origin.x-3.0,[self plottingArea].origin.y,6.0,[self plottingArea].size.height) cursor:[NSCursor resizeLeftRightCursor]];
    [self addCursorRect:NSMakeRect([self plottingArea].origin.x+[self plottingArea].size.width-3.0,[self plottingArea].origin.y,6.0,[self plottingArea].size.height) cursor:[NSCursor resizeLeftRightCursor]];
    [self addCursorRect:NSMakeRect([self plottingArea].origin.x,[self plottingArea].origin.y-3.0,[self plottingArea].size.width,6.0) cursor:[NSCursor resizeUpDownCursor]];
    [self addCursorRect:NSMakeRect([self plottingArea].origin.x,[self plottingArea].origin.y-3.0+[self plottingArea].size.height,[self plottingArea].size.width,6.0) cursor:[NSCursor resizeUpDownCursor]];
	if (shouldDrawLegend) [self addCursorRect:[self legendArea] cursor:[NSCursor openHandCursor]];
}

- (void)mouseDown:(NSEvent *)theEvent {
	_didDrag = NO;
	_mouseDownAtPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	_oldOrigin = [self origin];
	_oldLegendOrigin = [self legendArea].origin;
	_startedInsidePlottingArea = [self mouse:_mouseDownAtPoint inRect:[self plottingArea]];
	_startedInsideLegendArea = [self mouse:_mouseDownAtPoint inRect:[self legendArea]];
    
    if ([self mouse:_mouseDownAtPoint inRect:NSMakeRect([self plottingArea].origin.x-3.0,[self plottingArea].origin.y,6.0,[self plottingArea].size.height)]) {
        _startedOperation = JKLeftResizePlottingAreaOperation;
    } else if ([self mouse:_mouseDownAtPoint inRect:NSMakeRect([self plottingArea].origin.x+[self plottingArea].size.width-3.0,[self plottingArea].origin.y,6.0,[self plottingArea].size.height)]) {
        _startedOperation = JKRightResizePlottingAreaOperation;
    } else if ([self mouse:_mouseDownAtPoint inRect:NSMakeRect([self plottingArea].origin.x,[self plottingArea].origin.y-3.0,[self plottingArea].size.width,6.0)]) {
        _startedOperation = JKBottomResizePlottingAreaOperation;
    } else if ([self mouse:_mouseDownAtPoint inRect:NSMakeRect([self plottingArea].origin.x,[self plottingArea].origin.y-3.0+[self plottingArea].size.height,[self plottingArea].size.width,6.0)]) {
        _startedOperation = JKTopResizePlottingAreaOperation;
    } else if (_startedInsideLegendArea & shouldDrawLegend) {
        _startedOperation = JKDragLegendOperation;
	} else if (_startedInsidePlottingArea) {
		if (([theEvent modifierFlags] & NSCommandKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
			// adding peak
            _startedOperation = JKAddPeakOperation;
		} else if (([theEvent modifierFlags] & NSAlternateKeyMask) && ([theEvent modifierFlags] & NSShiftKeyMask)) {
            // zoom out
            _startedOperation = JKZoomOutOperation;
		} else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
            // zoom
            _startedOperation = JKZoomOperation;
		} else if (([theEvent modifierFlags] & NSControlKeyMask) && ([theEvent modifierFlags] & NSCommandKeyMask)) {
            // adding baselinepoint
            _startedOperation = JKAddBaselinePointOperation;
        } else if (([theEvent modifierFlags] & NSControlKeyMask) && ([theEvent modifierFlags] & NSAlternateKeyMask)) {
            // select baselinepoint
            _startedOperation = JKSelectBaselinePointOperation;
		} else {
            // clicks
            _startedOperation = JKSelectPeakOperation;
		}		
	} else {
		if ([theEvent modifierFlags] & NSAlternateKeyMask) {
            if (_mouseDownAtPoint.x > plottingArea.origin.x && _mouseDownAtPoint.x < plottingArea.origin.x + plottingArea.size.width) {
                _startedOperation = JKZoomHorizontalOnlyOperation;
            } else {
                _startedOperation = JKZoomVerticalOnlyOperation;                 
            }
		} else {
            if (_mouseDownAtPoint.x > plottingArea.origin.x && _mouseDownAtPoint.x < plottingArea.origin.x + plottingArea.size.width) {
                _startedOperation = JKDragHorizontalOnlyOperation;
            } else {
                _startedOperation = JKDragVerticalOnlyOperation;                 
            }
		}		
	}
    
    [self setCursorForOperation:_startedOperation];
}

- (void)mouseDragged:(NSEvent *)theEvent {
	_didDrag = YES;
	NSRect draggedRect;
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint newOrigin;
  	NSRect legendRect;
    NSRect newRect;
    
	switch (_startedOperation) {
    case JKDragLegendOperation:
		newOrigin.x = _oldLegendOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
		newOrigin.y = _oldLegendOrigin.y + (mouseLocation.y - _mouseDownAtPoint.y);
		legendRect = [self legendArea];
		legendRect.origin = newOrigin;
        if (NSIntersectsRect([self bounds], legendRect))
            [self setLegendArea:legendRect];	        
        break;
    case JKLeftResizePlottingAreaOperation:
        newRect = [self plottingArea];
        newRect.size.width = newRect.size.width - (mouseLocation.x - newRect.origin.x);
        newRect.origin.x = mouseLocation.x;
        if (NSIntersectsRect([self bounds], newRect))
            [self setPlottingArea:newRect];
        break;
    case JKRightResizePlottingAreaOperation:
        newRect = [self plottingArea];
        newRect.size.width = mouseLocation.x - newRect.origin.x;
        if (NSIntersectsRect([self bounds], newRect))
            [self setPlottingArea:newRect];
        break;
    case JKBottomResizePlottingAreaOperation:
        newRect = [self plottingArea];
        newRect.size.height = newRect.size.height - (mouseLocation.y - newRect.origin.y);
        newRect.origin.y = mouseLocation.y;
        if (NSIntersectsRect([self bounds], newRect))
            [self setPlottingArea:newRect];
        break;
    case JKTopResizePlottingAreaOperation:
        newRect = [self plottingArea];
        newRect.size.height = mouseLocation.y - newRect.origin.y;
        if (NSIntersectsRect([self bounds], newRect))
            [self setPlottingArea:newRect];
        break;
    case JKZoomOperation:
        draggedRect.origin.x = (_mouseDownAtPoint.x < mouseLocation.x ? _mouseDownAtPoint.x : mouseLocation.x);
        draggedRect.origin.y = (_mouseDownAtPoint.y < mouseLocation.y ? _mouseDownAtPoint.y : mouseLocation.y);
        draggedRect.size.width = fabs(mouseLocation.x-_mouseDownAtPoint.x);
        draggedRect.size.height = fabs(mouseLocation.y-_mouseDownAtPoint.y);
        [self setSelectedRect:draggedRect];
        break;
    case JKZoomHorizontalOnlyOperation:
        draggedRect.origin.x = (_mouseDownAtPoint.x < mouseLocation.x ? _mouseDownAtPoint.x : mouseLocation.x);
        draggedRect.origin.y = plottingArea.origin.y;
        draggedRect.size.width = fabs(mouseLocation.x-_mouseDownAtPoint.x);
        draggedRect.size.height = plottingArea.size.height;
        [self setSelectedRect:draggedRect];
        break;
    case JKZoomVerticalOnlyOperation:
        draggedRect.origin.x = plottingArea.origin.x;
        draggedRect.origin.y = (_mouseDownAtPoint.y < mouseLocation.y ? _mouseDownAtPoint.y : mouseLocation.y);
        draggedRect.size.width = plottingArea.size.width;
        draggedRect.size.height = fabs(mouseLocation.y-_mouseDownAtPoint.y);
        [self setSelectedRect:draggedRect];
        break;
    case JKSelectPeakOperation:
    case JKDragOperation:
        newOrigin;
        newOrigin.x = _oldOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
        newOrigin.y = _oldOrigin.y + (mouseLocation.y - _mouseDownAtPoint.y);
        [self setOrigin:newOrigin];
        _startedOperation = JKDragOperation;
		break;
    case JKDragVerticalOnlyOperation:
        newOrigin;
            newOrigin.x = _oldOrigin.x;// + (mouseLocation.x - _mouseDownAtPoint.x);
        newOrigin.y = _oldOrigin.y + (mouseLocation.y - _mouseDownAtPoint.y);
        [self setOrigin:newOrigin];
        _startedOperation = JKDragVerticalOnlyOperation;
        break;
    case JKDragHorizontalOnlyOperation:
        newOrigin;
        newOrigin.x = _oldOrigin.x + (mouseLocation.x - _mouseDownAtPoint.x);
        newOrigin.y = _oldOrigin.y;// + (mouseLocation.y - _mouseDownAtPoint.y);
        [self setOrigin:newOrigin];
        _startedOperation = JKDragHorizontalOnlyOperation;
        break;
    default:
        break;
    }
    
    [self setCursorForOperation:_startedOperation];        	
}

- (void)mouseUp:(NSEvent *)theEvent {
	NSPoint mouseLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    PKPeakRecord *selectedPeak = nil;
    PKChromatogram *selectedChromatogram;
    NSDictionary *selectedBaselinePoint = nil;
//    int selectedScan = NSNotFound;
    int selectedPeakIndex = NSNotFound;
    int selectedBaselinePointIndex = NSNotFound;
    
    switch (_startedOperation) {
        case JKSelectPeakOperation:
            if ([theEvent clickCount] == 2) { // Double click
                //  select scan and show spectrum 
                selectedScan = [self scanAtPoint:mouseLocation];
                if (selectedScan != NSNotFound) {
                    if ([delegate respondsToSelector:@selector(showSpectrumForScan:)]) {
                        [self setSelectedScan:selectedScan];
                        [delegate showSpectrumForScan:[self selectedScan]];
                    }                     
                } else {
                    // or show chromatogram for mass
                    int selectedMass = [self massAtPoint:mouseLocation];
                    if ([delegate respondsToSelector:@selector(showChromatogramForModel:)]) {
                        [delegate showChromatogramForModel:[NSString stringWithFormat:@"%d",selectedMass]];
                    }                                         
                }                
                [self setNeedsDisplay:YES];
            } else if ([theEvent modifierFlags] & NSCommandKeyMask ) {
                //  select additional peak(/select baseline point/select scan)
                selectedPeak = [self peakAtPoint:mouseLocation];
                if (selectedPeak) {
                    _lastSelectedPeakIndex = [[self peaks] indexOfObject:selectedPeak];
                    [peaksContainer addSelectedObjects:[NSArray arrayWithObject:selectedPeak]];
                } else {
                    _lastSelectedPeakIndex = NSNotFound;
                }
            } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
                //  select series of peaks(/select baseline point/select scan)
                selectedPeak = [self peakAtPoint:mouseLocation];
                if (selectedPeak) {
                    selectedPeakIndex = [[self peaks] indexOfObject:selectedPeak];
                    // do we know where the range for the selection started?
                    if (_lastSelectedPeakIndex != NSNotFound) {
                        if (_lastSelectedPeakIndex < selectedPeakIndex) {
                            [peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_lastSelectedPeakIndex+1,selectedPeakIndex-_lastSelectedPeakIndex)]];
                        } else {
                            [peaksContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selectedPeakIndex,_lastSelectedPeakIndex-selectedPeakIndex)]];
                        }
                    } else {
                        [peaksContainer addSelectedObjects:[NSArray arrayWithObject:selectedPeak]];
                    }
                    _lastSelectedPeakIndex = [[self peaks] indexOfObject:selectedPeak];
                } else {
                    _lastSelectedPeakIndex = NSNotFound;
                }
            } else {
                //  select peak(/select baseline point/select scan)
                selectedPeak = [self peakAtPoint:mouseLocation];
                if (selectedPeak) {
                    _lastSelectedPeakIndex = [[self peaks] indexOfObject:selectedPeak];
                    [peaksContainer setSelectedObjects:[NSArray arrayWithObject:selectedPeak]];
                } else {
                    _lastSelectedPeakIndex = NSNotFound;
                }
             }
            [self setNeedsDisplayInRect:[self plottingArea]];
            break;
        case JKAddPeakOperation:
            PKLogDebug(@"peak drag from scan %d to scan %d",[self scanAtPoint:_mouseDownAtPoint],[self scanAtPoint:mouseLocation]);
            PKChromatogram *theChromatogram = [self chromatogramAtPoint:_mouseDownAtPoint]; 
            PKPeakRecord *newPeak = [theChromatogram peakFromScan:[self scanAtPoint:_mouseDownAtPoint] toScan:[self scanAtPoint:mouseLocation]];
            [theChromatogram insertObject:newPeak inPeaksAtIndex:[theChromatogram countOfPeaks]];
            selectedPeak = newPeak;
            if (selectedPeak) {
                _lastSelectedPeakIndex = [[self peaks] indexOfObject:selectedPeak];
                [peaksContainer setSelectedObjects:[NSArray arrayWithObject:selectedPeak]];
            } else {
                _lastSelectedPeakIndex = NSNotFound;
            }
            [self setNeedsDisplayInRect:[self plottingArea]];            
            break;
        case JKAddBaselinePointOperation:
            selectedChromatogram = [self chromatogramAtPoint:mouseLocation]; 
            [selectedChromatogram insertObject:[self pointAtPoint:mouseLocation] inBaselinePointsAtIndex:[selectedChromatogram baselinePointsIndexAtScan:[self scanAtPoint:mouseLocation]]];
            [self setShouldDrawBaseline:YES];
            [self setNeedsDisplayInRect:[self plottingArea]];  
            break;
        case JKZoomOutOperation:
            if ([theEvent clickCount] == 2) { // Double click
				[self showAll:self];
            } else {
                [self zoomOut];
            }
            break;
        case JKZoomOperation:
        case JKZoomVerticalOnlyOperation:
        case JKZoomHorizontalOnlyOperation:
            if ([theEvent clickCount] == 2) { // Double click
				[self showAll:self];
            } else if ([self selectedRect].size.width > 2.0f && [self selectedRect].size.height > 2.0f) {
                [self zoomToRectInView:[self selectedRect]];
            } else {
                [self zoomIn];
            }
            break;
//        case JKSelectBaselinePointOperation:
//            // deselect any peaks
//            // [peaksContainer setSelectedObjects:nil];
//            selectedChromatogram = [self chromatogramAtPoint:_mouseDownAtPoint];
//            
//           	//  select baselinepoints
//            if ([theEvent modifierFlags] & NSCommandKeyMask ) {
//                //  select additional peak(/select baseline point/select scan)
//                selectedBaselinePoint = [self baselinePointAtPoint:mouseLocation];
//                if (selectedBaselinePoint) {
//                    _lastSelectedBaselinePointIndex = [[selectedChromatogram baselinePoints] indexOfObject:selectedBaselinePoint];
//                    [baselineContainer addSelectedObjects:[NSArray arrayWithObject:selectedBaselinePoint]];
//                } else {
//                    _lastSelectedBaselinePointIndex = NSNotFound;
//                }
//            } else if ([theEvent modifierFlags] & NSShiftKeyMask) {
//                //  select series of baseline points
//                selectedBaselinePoint = [self baselinePointAtPoint:mouseLocation];
//                if (selectedBaselinePoint) {
//                    selectedBaselinePointIndex = [[selectedChromatogram baselinePoints] indexOfObject:selectedBaselinePoint];
//                    // do we know where the range for the selection started?
//                    if (_lastSelectedBaselinePointIndex != NSNotFound) {
//                        if (_lastSelectedBaselinePointIndex < selectedBaselinePointIndex) {
//                            [baselineContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(_lastSelectedBaselinePointIndex+1,selectedBaselinePointIndex-_lastSelectedBaselinePointIndex)]];
//                        } else {
//                            [baselineContainer addSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selectedBaselinePointIndex,_lastSelectedBaselinePointIndex-selectedBaselinePointIndex)]];
//                        }
//                    } else {
//                        [baselineContainer addSelectedObjects:[NSArray arrayWithObject:selectedBaselinePoint]];
//                    }
//                    _lastSelectedBaselinePointIndex = [[selectedChromatogram baselinePoints] indexOfObject:selectedBaselinePoint];
//                } else {
//                    _lastSelectedBaselinePointIndex = NSNotFound;
//                }
//            } else {
//                //  select baseline point
//                selectedBaselinePoint = [self baselinePointAtPoint:mouseLocation];
//                if (selectedBaselinePoint) {
//                    _lastSelectedBaselinePointIndex = [[theChromatogram baselinePoints] indexOfObject:selectedBaselinePoint];
//                    [baselineContainer setSelectedObjects:[NSArray arrayWithObject:selectedBaselinePoint]];
//                } else {
//                    _lastSelectedBaselinePointIndex = NSNotFound;
//                }
//            }
//            [self setNeedsDisplayInRect:[self plottingArea]];
//            
//            break;
        case JKDragOperation:
        case JKDragVerticalOnlyOperation:
        case JKDragHorizontalOnlyOperation:
        case JKDragLegendOperation:
        default:
            [self setNeedsDisplay:YES]; // Avoid blurry display
            break;
    }
            
	// Reset
    _startedOperation = JKNoOperation;
	_didDrag = NO;
    [self setSelectedRect:NSMakeRect(0,0,0,0)];
	[self setCursorForOperation:JKNoOperation];        	
}

- (void)setCursorForOperation:(JKOperations)operation {
    NSCursor *zoomCursor = nil;
    NSPoint mouseLocation;
    
    switch (operation) {
        case JKDragLegendOperation:
        case JKDragOperation:
        case JKDragVerticalOnlyOperation:
        case JKDragHorizontalOnlyOperation:
            [[NSCursor closedHandCursor] set];
            break;
        case JKZoomOperation:
        case JKZoomVerticalOnlyOperation:
        case JKZoomHorizontalOnlyOperation:
            zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom_in"] hotSpot:NSMakePoint(10,12)];
            [zoomCursor set];
            [zoomCursor release];        
            break;
        case JKZoomOutOperation:
            zoomCursor = [[NSCursor alloc] initWithImage:[NSImage imageNamed:@"zoom_out"] hotSpot:NSMakePoint(10,12)];
            [zoomCursor set];
            [zoomCursor release];        
            break;
        default:
            mouseLocation = [self convertPoint: [[self window] mouseLocationOutsideOfEventStream] fromView:nil];
            if ([self mouse:mouseLocation inRect:[self plottingArea]]) {
               	[[NSCursor crosshairCursor] set];
            } else {
                [[NSCursor arrowCursor] set];
            }
            break;
    }
}

- (void)scrollWheel:(NSEvent *)theEvent {
    float deltaX = [theEvent deltaX];
    float deltaY = [theEvent deltaY];
    float pixelsPerXUnitF = [[self pixelsPerXUnit] floatValue];
    float pixelsPerYUnitF = [[self pixelsPerYUnit] floatValue];
     if ([theEvent modifierFlags] & NSAlternateKeyMask) {
         [self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] + 4.0f*deltaX/pixelsPerXUnitF]];
         [self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - 4.0f*deltaX/pixelsPerXUnitF]];
         [self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + 4.0f*deltaY/pixelsPerYUnitF]];
//         [self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] - 4.0f*deltaY/pixelsPerYUnit]];         
//         if (deltaY > 0) {
//             [self zoomIn];        
//         } else {
//             [self zoomOut];
//         }         
     } else {
         [self setXMaximum:[NSNumber numberWithFloat:[[self xMaximum] floatValue] - 4.0f*deltaX/pixelsPerXUnitF]];
         [self setXMinimum:[NSNumber numberWithFloat:[[self xMinimum] floatValue] - 4.0f*deltaX/pixelsPerXUnitF]];
         [self setYMaximum:[NSNumber numberWithFloat:[[self yMaximum] floatValue] + 4.0f*deltaY/pixelsPerYUnitF]];
         [self setYMinimum:[NSNumber numberWithFloat:[[self yMinimum] floatValue] + 4.0f*deltaY/pixelsPerYUnitF]];         
     }
}
#pragma mark -

#pragma mark Selection helper methods
- (int)scanAtPoint:(NSPoint)aPoint {
    int scan = NSNotFound;
    NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:aPoint];
    if ([keyForXValue isEqualToString:@"Scan"]) {
        scan = lroundf(graphLocation.x);
    } else if ([keyForXValue isEqualToString:@"Time"]) {
        PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
        if (chromatogram) {
            scan = [chromatogram scanForTime:graphLocation.x];            
        }
    } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
        PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
        if (chromatogram) {
            float retentionSlope = [[[chromatogram document] retentionIndexSlope] floatValue];
            float retentionRemainder = [[[chromatogram document] retentionIndexRemainder] floatValue];
            scan = lroundf( (graphLocation.x - retentionRemainder)/retentionSlope );
         }
    } else {
//        PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
    }
    
    return scan;
}

- (PKPeakRecord *)peakAtPoint:(NSPoint)aPoint {
    NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:aPoint];
    PKPeakRecord *peak = nil;
    PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
    int i;
    float retentionSlope = [[[chromatogram document] retentionIndexSlope] floatValue];
    float retentionRemainder = [[[chromatogram document] retentionIndexRemainder] floatValue];
   
    if (chromatogram) {
        int peaksCount = [[chromatogram peaks] count];
        for (i=0; i < peaksCount; i++) {
            peak = [[chromatogram peaks] objectAtIndex:i];
            if ([keyForXValue isEqualToString:@"Scan"]) {
                if (([peak start] < graphLocation.x) & ([peak end] > graphLocation.x)) {
                    return peak;
                } 
            } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
                if (([peak start] *retentionSlope +retentionRemainder < graphLocation.x) & ([peak end] *retentionSlope +retentionRemainder > graphLocation.x)) {
                    return peak;
                } 
            } else if ([keyForXValue isEqualToString:@"Time"]) {
                if (([[peak valueForKey:@"startTime"] floatValue] < graphLocation.x) & ([[peak valueForKey:@"endTime"] floatValue] > graphLocation.x)) {
                    return peak;
                }                         
            } else {
//                PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
            }
        }
        
        // Second best guess
        // assumes peaks are ordered properly
        for (i=0; i < peaksCount; i++) {
            peak = [[chromatogram peaks] objectAtIndex:i];
            if ([keyForXValue isEqualToString:@"Scan"]) {
                if ([peak start] >= graphLocation.x) {
                    return peak;
                } 
            } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
                if ([peak start] *retentionSlope +retentionRemainder >= graphLocation.x) {
                    return peak;
                } 
            } else if ([keyForXValue isEqualToString:@"Time"]) {
                if ([[peak valueForKey:@"startTime"] floatValue] >= graphLocation.x) {
                    return peak;
                }                         
            } else {
                //                PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
            }
        }
        
        
    } else {
//        PKLogError(@"No chromatogram available");
    }
    return peak;
}

- (NSMutableDictionary *)pointAtPoint:(NSPoint)aPoint {
    int scan = NSNotFound;
    //NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:aPoint];
    
    NSAffineTransform *transform = [self transformForDataSeriesAtIndex:[self dataSeriesIndexAtPoint:aPoint]];
    [transform invert];
    NSPoint graphLocation = [transform transformPoint:aPoint];
    

    NSMutableDictionary *thePoint = [NSMutableDictionary dictionaryWithCapacity:3];
    
    if ([keyForXValue isEqualToString:@"Scan"]) {
        scan = lroundf(graphLocation.x);
        [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"Scan"];
        [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"scan"];
        PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
        if (chromatogram) {
            [thePoint setValue:[NSNumber numberWithFloat:[[self chromatogramAtPoint:aPoint] timeForScan:scan]] forKey:@"Time"];
            
        } else {
            [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"Total Intensity"];
            [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"intensity"];
        }

    } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
        PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
        if (chromatogram) {
            float retentionSlope = [[[chromatogram document] retentionIndexSlope] floatValue];
            float retentionRemainder = [[[chromatogram document] retentionIndexRemainder] floatValue];
            scan = lroundf( (graphLocation.x - retentionRemainder)/retentionSlope );
            [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"Scan"];
            [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"scan"];
           [thePoint setValue:[NSNumber numberWithFloat:[[self chromatogramAtPoint:aPoint] timeForScan:scan]] forKey:@"Time"];
        }
        [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"Total Intensity"];        
        [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"intensity"];        
   } else if ([keyForXValue isEqualToString:@"Time"]) {
        PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
        if (chromatogram) {
            scan = [chromatogram scanForTime:graphLocation.x];            
            [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"Scan"];
            [thePoint setValue:[NSNumber numberWithInt:scan] forKey:@"scan"];
        }
        [thePoint setValue:[NSNumber numberWithFloat:graphLocation.x] forKey:@"Time"];
        [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"Total Intensity"];
        [thePoint setValue:[NSNumber numberWithFloat:graphLocation.y] forKey:@"intensity"];
        
    } else {
//        PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
    }
    
    return thePoint;
}

- (int)massAtPoint:(NSPoint)aPoint {
    int mass = NSNotFound;
    NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:aPoint];
    
    if ([keyForXValue isEqualToString:@"Mass"]) {
        mass = lroundf(graphLocation.x);
    } else {
        PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
    }
    
    return mass;
}

- (PKChromatogram *)chromatogramAtPoint:(NSPoint)aPoint {  
    int dataSerieIndex = [self dataSeriesIndexAtPoint:aPoint];
    if ([[[self dataSeries] objectAtIndex:dataSerieIndex] isMemberOfClass:[PKChromatogramDataSeries class]]) {
        return [[[self dataSeries] objectAtIndex:dataSerieIndex] chromatogram];
    }
    return nil;
}

- (int)dataSeriesIndexAtPoint:(NSPoint)aPoint {
    PKChromatogram *chromatogram = nil;
    int i, count, dataSerieIndex;
    float dataSerieHeight;
    
    count = [[self dataSeries] count];
    if (count > 0) {
        // Does a bezierpath contain the point?
        for (i = 0; i < count; i++) {
            NSBezierPath *bezierPath = [[[[[self dataSeries] objectAtIndex:i] plotPath] copy] autorelease];
            [bezierPath transformUsingAffineTransform:[self transformForDataSeriesAtIndex:i]];

            if ([bezierPath containsPoint:aPoint]) {
                return i;
            }
        } 
        // or else, is it in a bounding rect
        for (i = 0; i < count; i++) {
            NSRect rect = [[[self dataSeries] objectAtIndex:i] boundingRect];
            if (NSPointInRect(aPoint, rect)) {
                return i;
            }
        } 
        // When outside any rect, use fall back
        dataSerieHeight = [self plottingArea].size.height/count;
        dataSerieIndex = floor((aPoint.y-[self plottingArea].origin.y)/dataSerieHeight);
        if ((dataSerieIndex < 0) || (dataSerieIndex >= count)) {
            dataSerieIndex = 0;
        }
        return dataSerieIndex;              
    } 
    return NSNotFound;
}

//- (NSDictionary *)baselinePointAtPoint:(NSPoint)aPoint {
//#warning [TODO] Incomplete method
//    NSPoint graphLocation = [[self transformScreenToGraph] transformPoint:aPoint];
//    NSDictionary *baselinePoint = nil;
//    PKChromatogram *chromatogram = [self chromatogramAtPoint:aPoint];
//    int i;
//    float retentionSlope = [[[chromatogram document] retentionIndexSlope] floatValue];
//    float retentionRemainder = [[[chromatogram document] retentionIndexRemainder] floatValue];
//    
////    if (chromatogram) {
////        int peaksCount = [[chromatogram baselinePoints] count];
////        for (i=0; i < peaksCount; i++) {
////            baselinePoint = [[chromatogram baselinePoints] objectAtIndex:i];
////            if ([keyForXValue isEqualToString:@"Scan"]) {
////                if (([peak start] < graphLocation.x) & ([peak end] > graphLocation.x)) {
////                    return baselinePoint;
////                } 
////            } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
////                if (([peak start] *retentionSlope +retentionRemainder < graphLocation.x) & ([peak end] *retentionSlope +retentionRemainder > graphLocation.x)) {
////                    return baselinePoint;
////                } 
////            } else if ([keyForXValue isEqualToString:@"Time"]) {
////                if (([[peak valueForKey:@"startTime"] floatValue] < graphLocation.x) & ([[peak valueForKey:@"endTime"] floatValue] > graphLocation.x)) {
////                    return baselinePoint;
////                }                         
////            } else {
//////                PKLogError(@"Unexpected keyForXValue '%@'", keyForXValue);
////            }
////        }
////    } else {
//////        PKLogError(@"No chromatogram available");
////    }
//    return baselinePoint;
//}
#pragma mark -

#pragma mark Keyboard Interaction Management
- (void)flagsChanged:(NSEvent *)theEvent {
    if (_startedOperation != JKNoOperation) {
        [self setCursorForOperation:_startedOperation];
    } else if (([theEvent modifierFlags] & NSAlternateKeyMask ) && ([theEvent modifierFlags] & NSShiftKeyMask )) {
        [self setCursorForOperation:JKZoomOutOperation];
    } else if (([theEvent modifierFlags] & NSAlternateKeyMask ) && ([theEvent modifierFlags] & NSCommandKeyMask )) {
        [self setCursorForOperation:JKAddPeakOperation];
    } else if ([theEvent modifierFlags] & NSAlternateKeyMask) {
        [self setCursorForOperation:JKZoomOperation];
    } else {
        [self setCursorForOperation:JKNoOperation];
    }
}

- (void)keyDown:(NSEvent *)theEvent {
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
	} else if ([[theEvent characters] isEqualToString:@"r"]) {
		[self setNeedsDisplay:YES];
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
				} else {
					[self selectPreviousPeak];
				}
				break;
			case NSDownArrowFunctionKey:
				if ([theEvent modifierFlags] & NSAlternateKeyMask) {
					[self moveDown];
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
				[self setNeedsDisplayInRect:[self plottingArea]];
				break;
			default:
				[super keyDown:theEvent];
		}
	}
}

- (BOOL)canBecomeKeyView {
	return YES;
}
- (BOOL) acceptsFirstResponder {
    return YES;
}
- (BOOL) resignFirstResponder {
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidResignFirstResponderNotification object:self];
	[self setNeedsDisplay:YES];
    return YES;
}
- (BOOL) becomeFirstResponder {
	[[NSNotificationCenter defaultCenter] postNotificationName:MyGraphView_DidBecomeFirstResponderNotification object:self];
	[self setNeedsDisplay:YES];
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

- (void)delete:(id)sender {
//    [baselineContainer removeObjects:[baselineContainer selectedObjects]];
    [peaksContainer removeObjects:[peaksContainer selectedObjects]];
//    [dataSeriesContainer removeObjects:[dataSeriesContainer selectedObjects]];
}
#pragma mark -

#pragma mark Key Value Observing Management
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
    if (context == PeaksObservationContext)
	{
		[self setNeedsDisplayInRect:[self plottingArea]];
	}
	else if (context == DataObservationContext) 
	{
//		int i, count;
		// Als de inhoud van onze dataArray wijzigt, bijv. als er een dataserie wordt toegevoegd, dan willen we ons registreren voor wijzingen die de dataserie post. Eerst verwijderen we onszelf voor alle notificaties, en daarna registreren we voor de op dit moment beschikbare dataseries. Dit is eenvoudiger (en waarschijnlijk sneller) dan uitzoeken wat er precies veranderd is.
//		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"MyGraphDataSerieDidChangeNotification" object:nil];
//		count = [[self dataSeries] count];
//		for (i=0;i<count; i++){
//			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:@"MyGraphDataSerieDidChangeNotification" object:[[self dataSeries] objectAtIndex:i]];
//		}
		[self setNeedsDisplayInRect:[self plottingArea]];
    } 
    else if (context == DataSeriesObservationContext) 
	{
        // resize legend area to fit all entries
        NSRect newLegendArea = [self legendArea];
        newLegendArea.size.height = [[self dataSeries] count] * 18;
        newLegendArea.origin.y = newLegendArea.origin.y - (newLegendArea.size.height - [self legendArea].size.height);
        [self setLegendArea:newLegendArea];
        
        if (![self keyForXValue] && [[self dataSeries] count] > 0) {
            [self setKeyForXValue:[[[self dataSeries] objectAtIndex:0] keyForXValue]];
        }
        if (![self keyForYValue] && [[self dataSeries] count] > 0) {
            [self setKeyForYValue:[[[self dataSeries] objectAtIndex:0] keyForYValue]];
        }
        
		[self setNeedsDisplayInRect:[self plottingArea]];
    } 
    else if (context == BaselineObservationContext) 
	{
		[self setNeedsDisplayInRect:[self plottingArea]];
    } 

}
#pragma mark -

#pragma mark Bindings
- (void)bind:(NSString *)bindingName
    toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
     options:(NSDictionary *)options{
	
    if ([bindingName isEqualToString:@"dataSeries"])
	{		
		[self setDataSeriesContainer:observableObject];
		[self setDataSeriesKeyPath:observableKeyPath];
		[dataSeriesContainer addObserver:self
							  forKeyPath:dataSeriesKeyPath
								 options:(NSKeyValueObservingOptionNew |
										  NSKeyValueObservingOptionOld)
								 context:DataSeriesObservationContext];
//        PKLogDebug(@"count: %d",[[self dataSeries] count]);
		//[self startObservingGraphics:[graphicsContainer valueForKeyPath:graphicsKeyPath]];
		
    }
	else if ([bindingName isEqualToString:@"peaks"])
	{
		[self setPeaksContainer:observableObject];
		[self setPeaksKeyPath:observableKeyPath];
		[peaksContainer addObserver:self
						 forKeyPath:peaksKeyPath
							options:0
							context:PeaksObservationContext];
	}
//	else if ([bindingName isEqualToString:@"baseline"])
//	{
//		[self setBaselineContainer:observableObject];
//		[self setBaselineKeyPath:observableKeyPath];
//		[baselineContainer addObserver:self
//							forKeyPath:baselineKeyPath
//							   options:nil
//							   context:BaselineObservationContext];
//	}
	
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
	else if ([bindingName isEqualToString:@"peaks"])
	{
		[peaksContainer removeObserver:self forKeyPath:peaksKeyPath];
		[self setPeaksContainer:nil];
		[self setPeaksKeyPath:nil];
	}
//	else if ([bindingName isEqualToString:@"baseline"])
//	{
//		[baselineContainer removeObserver:self forKeyPath:baselineKeyPath];
//		[self setBaselineContainer:nil];
//		[self setBaselineKeyPath:nil];
//	}
	
	[super unbind:bindingName];
	[self setNeedsDisplay:YES];
}

#pragma mark dataSeries bindings
- (NSMutableArray *)dataSeries
{	
    return [dataSeriesContainer valueForKeyPath:dataSeriesKeyPath];	
}
- (NSArrayController *)dataSeriesContainer{
    return dataSeriesContainer; 
}
- (void)setDataSeriesContainer:(NSArrayController *)aDataSeriesContainer{
    if (dataSeriesContainer != aDataSeriesContainer) {
        [dataSeriesContainer release];
        dataSeriesContainer = [aDataSeriesContainer retain];
    }
}
- (NSString *)dataSeriesKeyPath{
    return dataSeriesKeyPath; 
}
- (void)setDataSeriesKeyPath:(NSString *)aDataSeriesKeyPath{
    if (dataSeriesKeyPath != aDataSeriesKeyPath) {
        [dataSeriesKeyPath release];
        dataSeriesKeyPath = [aDataSeriesKeyPath copy];
    }
}


#pragma mark peaks bindings
- (NSMutableArray *)peaks{
	return [peaksContainer valueForKeyPath:peaksKeyPath];
}
- (NSArrayController *)peaksContainer{
    return peaksContainer; 
}
- (void)setPeaksContainer:(NSArrayController *)aPeaksContainer{
    if (peaksContainer != aPeaksContainer) {
        [peaksContainer release];
        peaksContainer = [aPeaksContainer retain];
    }
}
- (NSString *)peaksKeyPath{
    return peaksKeyPath; 
}
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath{
    if (peaksKeyPath != aPeaksKeyPath) {
        [peaksKeyPath release];
        peaksKeyPath = [aPeaksKeyPath copy];
    }
}
//
//#pragma mark baseline bindings
//- (NSMutableArray *)baseline
//{
//	return [baselineContainer valueForKeyPath:baselineKeyPath];
//}
//- (NSObject *)baselineContainer
//{
//    return baselineContainer; 
//}
//- (void)setBaselineContainer:(NSObject *)aBaselineContainer
//{
//    if (baselineContainer != aBaselineContainer) {
//        [baselineContainer release];
//        baselineContainer = [aBaselineContainer retain];
//    }
//}
//- (NSString *)baselineKeyPath
//{
//    return baselineKeyPath; 
//}
//- (void)setBaselineKeyPath:(NSString *)aBaselineKeyPath
//{
//    if (baselineKeyPath != aBaselineKeyPath) {
//        [baselineKeyPath release];
//        baselineKeyPath = [aBaselineKeyPath copy];
//    }
//}
#pragma mark -

#pragma mark Accessors
- (id)delegate {
	return delegate;
}
- (void)setDelegate:(id)inValue {
    if (delegate != inValue) {
        delegate = inValue;        
    }
}

- (void)setFrame:(NSRect)newFrect {
    NSRect oldFrect, pRect, lRect;
    NSNumber *xMinimum = [self xMinimum];
    NSNumber *xMaximum = [self xMaximum];
    NSNumber *yMinimum = [self yMinimum];
    NSNumber *yMaximum = [self yMaximum];
    oldFrect = [self frame];
    pRect = [self plottingArea];
    pRect.size.width = pRect.size.width + newFrect.size.width - oldFrect.size.width;
    pRect.size.height = pRect.size.height + newFrect.size.height - oldFrect.size.height;
    lRect = [self legendArea];
    lRect.origin.x = lRect.origin.x + newFrect.size.width - oldFrect.size.width;
    lRect.origin.y = lRect.origin.y + newFrect.size.height - oldFrect.size.height;
    [self setLegendArea:lRect];
    [super setFrame:newFrect];      
    [[self window] invalidateCursorRectsForView:self];
    [self setPlottingArea:pRect];
    [self setXMinimum:xMinimum];
    [self setXMaximum:xMaximum];
    [self setYMinimum:yMinimum];
    [self setYMaximum:yMaximum];
    
}

- (NSAffineTransform *)transformGraphToScreen {
	return transformGraphToScreen;
}
- (void)setTransformGraphToScreen:(NSAffineTransform *)inValue {
    if (transformGraphToScreen != inValue) {
        [inValue retain];
        [transformGraphToScreen autorelease];
        transformGraphToScreen = inValue;        
    }
}

- (NSAffineTransform *)transformScreenToGraph {
	return transformScreenToGraph;
}
- (void)setTransformScreenToGraph:(NSAffineTransform *)inValue {
    if (transformScreenToGraph != inValue) {
        [inValue retain];
        [transformScreenToGraph autorelease];
        transformScreenToGraph = inValue;
    }
}

- (NSNumber *)pixelsPerXUnit {
	return pixelsPerXUnit;
}
- (void)setPixelsPerXUnit:(NSNumber *)inValue {
	if (pixelsPerXUnit != inValue) {
        if ([inValue isLessThan:[self minimumPixelsPerXUnit]]) {
            inValue = [self minimumPixelsPerXUnit];
        }
        [inValue retain];
        [pixelsPerXUnit autorelease];
        pixelsPerXUnit = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSNumber *)pixelsPerYUnit {
	return pixelsPerYUnit;
}
- (void)setPixelsPerYUnit:(NSNumber *)inValue {
	if (pixelsPerYUnit != inValue) {
        if ([inValue isLessThan:[self minimumPixelsPerYUnit]]) {
            inValue = [self minimumPixelsPerYUnit];
        }
        [inValue retain];
        [pixelsPerYUnit autorelease];
        pixelsPerYUnit = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSNumber *)minimumPixelsPerXUnit {
	return minimumPixelsPerXUnit;
}
- (void)setMinimumPixelsPerXUnit:(NSNumber *)inValue {
	if (minimumPixelsPerXUnit != inValue) {
        [inValue retain];
        [minimumPixelsPerXUnit autorelease];
        minimumPixelsPerXUnit = inValue;
    }
}

- (NSNumber *)minimumPixelsPerYUnit {
	return minimumPixelsPerYUnit;
}
- (void)setMinimumPixelsPerYUnit:(NSNumber *)inValue {
	if (minimumPixelsPerYUnit != inValue) {
        [inValue retain];
        [minimumPixelsPerYUnit autorelease];
        minimumPixelsPerYUnit = inValue;
    }
}

- (NSNumber *)minimumPixelsPerMajorGridLine {
	return minimumPixelsPerMajorGridLine;
}
- (void)setMinimumPixelsPerMajorGridLine:(NSNumber *)inValue {
    if (minimumPixelsPerMajorGridLine != inValue) {
        if ([inValue floatValue] > 0.0f) {
            [inValue retain];
            [minimumPixelsPerMajorGridLine autorelease];
            minimumPixelsPerMajorGridLine = inValue;
            [self setNeedsDisplay:YES];
        }
    }
}

- (NSPoint)origin {
	return origin;
}
- (void)setOrigin:(NSPoint)inValue {
    origin = inValue;
    [self setNeedsDisplay:YES];        
}

- (NSRect)plottingArea {
	return plottingArea;
}
- (void)setPlottingArea:(NSRect)inValue {
    if (inValue.origin.x < kMinimumPaddingAroundPlottingArea) {
        inValue.size.width = plottingArea.size.width;
        inValue.origin.x = kMinimumPaddingAroundPlottingArea;
    } else if (inValue.origin.x > [self frame].size.width - kMinimumWidthPlottingArea - kMinimumPaddingAroundPlottingArea) {
        inValue.origin.x = [self frame].size.width - kMinimumWidthPlottingArea - kMinimumPaddingAroundPlottingArea;
    }
    if (inValue.origin.y < kMinimumPaddingAroundPlottingArea) {
        inValue.size.height = plottingArea.size.height;
        inValue.origin.y = kMinimumPaddingAroundPlottingArea;
    } else if (inValue.origin.y > [self frame].size.height - kMinimumHeightPlottingArea - kMinimumPaddingAroundPlottingArea) {
        inValue.origin.y = [self frame].size.height - kMinimumHeightPlottingArea - kMinimumPaddingAroundPlottingArea;
    }
    if (inValue.size.width < kMinimumWidthPlottingArea) {
        inValue.size.width = kMinimumWidthPlottingArea;
    } else if (inValue.size.width > [self frame].size.width - inValue.origin.x - 2*kMinimumPaddingAroundPlottingArea) {
        inValue.size.width = [self frame].size.width - inValue.origin.x -2*kMinimumPaddingAroundPlottingArea;
    }
    if (inValue.size.height < kMinimumHeightPlottingArea) {
        inValue.size.height = kMinimumHeightPlottingArea;
    } else if (inValue.size.height > [self frame].size.height - inValue.origin.y - 2*kMinimumPaddingAroundPlottingArea) {
        inValue.size.height = [self frame].size.height - inValue.origin.y - 2*kMinimumPaddingAroundPlottingArea;
    }
    plottingArea = inValue;
    [self setNeedsDisplay:YES];        
    [[self window] invalidateCursorRectsForView:self];
}

- (NSRect)legendArea {
	return legendArea;
}
- (void)setLegendArea:(NSRect)inValue {
    NSRect unionRect = NSUnionRect(legendArea,inValue);
    legendArea = inValue;
    if ([self shouldDrawLegend]) {
        [[self window] invalidateCursorRectsForView:self];
        [self setNeedsDisplayInRect:NSInsetRect(unionRect,-20.0,-20.0)];        
    }
    
}

- (NSRect)selectedRect {
	return selectedRect;
}
- (void)setSelectedRect:(NSRect)inValue {
    NSRect unionRect = NSUnionRect(selectedRect,inValue);
    selectedRect = inValue;
    [self setNeedsDisplayInRect:NSInsetRect(unionRect, -10.0, -10.0)];        
}

- (NSColor *)backColor {
    return backColor;
}
- (void)setBackColor:(NSColor *)inValue {
    if (backColor != inValue) {
        [inValue retain];
        [backColor autorelease];
        backColor = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSColor *)baselineColor {
    return baselineColor;
}
- (void)setBaselineColor:(NSColor *)inValue {
    if (baselineColor != inValue) {
        [inValue retain];
        [baselineColor autorelease];
        baselineColor = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSColor *)plottingAreaColor {
    return plottingAreaColor;
}
- (void)setPlottingAreaColor:(NSColor *)inValue {
    if (plottingAreaColor != inValue) {
        [inValue retain];
        [plottingAreaColor autorelease];
        plottingAreaColor = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)axesColor {
    return axesColor;
}
- (void)setAxesColor:(NSColor *)inValue {
    if (axesColor != inValue) {
        [inValue retain];
        [axesColor autorelease];
        axesColor = inValue;
        if ([self shouldDrawAxes])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)gridColor {
    return gridColor;
}
- (void)setGridColor:(NSColor *)inValue {
    if (gridColor != inValue) {
        [inValue retain];
        [gridColor autorelease];
        gridColor = inValue;
        if ([self shouldDrawGrid])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)labelsColor {
    return labelsColor;
}
- (void)setLabelsColor:(NSColor *)inValue {
    if (labelsColor != inValue) {
        [inValue retain];
        [labelsColor autorelease];
        labelsColor = inValue;
        if ([self shouldDrawLabels])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)labelsOnFrameColor {
    return labelsOnFrameColor;
}
- (void)setLabelsOnFrameColor:(NSColor *)inValue {
    if (labelsOnFrameColor != inValue) {
        [inValue retain];
        [labelsOnFrameColor autorelease];
        labelsOnFrameColor = inValue;
        if ([self shouldDrawLabelsOnFrame])
            [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (NSColor *)frameColor {
    return frameColor;
}
- (void)setFrameColor:(NSColor *)inValue {
    if (frameColor != inValue) {
        [inValue retain];
        [frameColor autorelease];
        frameColor = inValue;
        if ([self shouldDrawFrame])
            [self setNeedsDisplay:YES];        
    }
}

- (NSColor *)legendAreaColor {
    return legendAreaColor;
}
- (void)setLegendAreaColor:(NSColor *)inValue {
    if (legendAreaColor != inValue) {
        [inValue retain];
        [legendAreaColor autorelease];
        legendAreaColor = inValue;
        if ([self shouldDrawLegend])
            [self setNeedsDisplayInRect:[self legendArea]];        
    }
}

- (NSColor *)legendFrameColor {
    return legendFrameColor;
}
- (void)setLegendFrameColor:(NSColor *)inValue {
    if (legendFrameColor != inValue) {
        [inValue retain];
        [legendFrameColor autorelease];
        legendFrameColor = inValue;
        if ([self shouldDrawLegend])
            [self setNeedsDisplayInRect:[self legendArea]];        
    }
}

- (JKDrawingModes)drawingMode {
	return drawingMode;
}
- (void)setDrawingMode:(JKDrawingModes)aDrawingMode {
	drawingMode = aDrawingMode;
    [self setNeedsDisplayInRect:[self plottingArea]];
}


- (BOOL)shouldDrawLegend {
    return shouldDrawLegend;
}
- (void)setShouldDrawLegend:(BOOL)inValue {
    if (shouldDrawLegend != inValue) {
        shouldDrawLegend = inValue;
        [[self window] invalidateCursorRectsForView:self];
        [self setNeedsDisplayInRect:NSInsetRect([self legendArea], -20.0, -20.0)];        
    }    
}

- (BOOL)shouldDrawAxes {
    return shouldDrawAxes;
}
- (void)setShouldDrawAxes:(BOOL)inValue {
    if (shouldDrawAxes != inValue) {
        shouldDrawAxes = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawAxesHorizontal{
    return shouldDrawAxesHorizontal;
}
- (void)setShouldDrawAxesHorizontal:(BOOL)inValue {
    if (shouldDrawAxesHorizontal != inValue) {
        shouldDrawAxesHorizontal = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawAxesVertical{
    return shouldDrawAxesVertical;
}
- (void)setShouldDrawAxesVertical:(BOOL)inValue {
    if (shouldDrawAxesVertical != inValue) {
        shouldDrawAxesVertical = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawFrame {
    return shouldDrawFrame;
}
- (void)setShouldDrawFrame:(BOOL)inValue {
    if (shouldDrawFrame != inValue) {
        shouldDrawFrame = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawFrameLeft{
    return shouldDrawFrameLeft;
}
- (void)setShouldDrawFrameLeft:(BOOL)inValue {
    if (shouldDrawFrameLeft != inValue) {
        shouldDrawFrameLeft = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawFrameBottom{
    return shouldDrawFrameBottom;
}
- (void)setShouldDrawFrameBottom:(BOOL)inValue {
    if (shouldDrawFrameBottom != inValue) {
        shouldDrawFrameBottom = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawMajorTickMarks{
	return shouldDrawMajorTickMarks;
}
- (void)setShouldDrawMajorTickMarks:(BOOL)inValue{
	if (shouldDrawMajorTickMarks != inValue) {        
        shouldDrawMajorTickMarks = inValue;
        [self setNeedsDisplay:YES];
    }
}
- (BOOL)shouldDrawMajorTickMarksHorizontal{
	return shouldDrawMajorTickMarksHorizontal;
}
- (void)setShouldDrawMajorTickMarksHorizontal:(BOOL)inValue{
	if (shouldDrawMajorTickMarksHorizontal != inValue) {        
        shouldDrawMajorTickMarksHorizontal = inValue;
        [self setNeedsDisplay:YES];
    }
}
- (BOOL)shouldDrawMajorTickMarksVertical{
	return shouldDrawMajorTickMarksVertical;
}
- (void)setShouldDrawMajorTickMarksVertical:(BOOL)inValue{
	if (shouldDrawMajorTickMarksVertical != inValue) {        
        shouldDrawMajorTickMarksVertical = inValue;
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)shouldDrawMinorTickMarks{
	return shouldDrawMinorTickMarks;
}
- (void)setShouldDrawMinorTickMarks:(BOOL)inValue{
    if (shouldDrawMinorTickMarks != inValue) {
        shouldDrawMinorTickMarks = inValue;
        [self setNeedsDisplay:YES];        
    }
}
- (BOOL)shouldDrawMinorTickMarksHorizontal{
	return shouldDrawMinorTickMarksHorizontal;
}
- (void)setShouldDrawMinorTickMarksHorizontal:(BOOL)inValue{
    if (shouldDrawMinorTickMarksHorizontal != inValue) {
        shouldDrawMinorTickMarksHorizontal = inValue;
        [self setNeedsDisplay:YES];        
    }
}
- (BOOL)shouldDrawMinorTickMarksVertical{
	return shouldDrawMinorTickMarksVertical;
}
- (void)setShouldDrawMinorTickMarksVertical:(BOOL)inValue{
    if (shouldDrawMinorTickMarksVertical != inValue) {
        shouldDrawMinorTickMarksVertical = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawGrid {
    return shouldDrawGrid;
}
- (void)setShouldDrawGrid:(BOOL)inValue {
    if (shouldDrawGrid != inValue) {
        shouldDrawGrid = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];        
    }
}

- (BOOL)shouldDrawLabels {
    return shouldDrawLabels;
}
- (void)setShouldDrawLabels:(BOOL)inValue {
    if (shouldDrawLabels != inValue) {
        shouldDrawLabels = inValue;
        [self setNeedsDisplayInRect:[self plottingArea]];    
    }
}

- (BOOL)shouldDrawLabelsOnFrame {
    return shouldDrawLabelsOnFrame;
}
- (void)setShouldDrawLabelsOnFrame:(BOOL)inValue {
    if (shouldDrawLabelsOnFrame != inValue) {
        shouldDrawLabelsOnFrame = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawLabelsOnFrameLeft {
    return shouldDrawLabelsOnFrameLeft;
}
- (void)setShouldDrawLabelsOnFrameLeft:(BOOL)inValue {
    if (shouldDrawLabelsOnFrameLeft != inValue) {
        shouldDrawLabelsOnFrameLeft = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawLabelsOnFrameBottom {
    return shouldDrawLabelsOnFrameBottom;
}
- (void)setShouldDrawLabelsOnFrameBottom:(BOOL)inValue {
    if (shouldDrawLabelsOnFrameBottom != inValue) {
        shouldDrawLabelsOnFrameBottom = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (BOOL)shouldDrawShadow {
    return shouldDrawShadow;
}
- (void)setShouldDrawShadow:(BOOL)inValue {
    if (shouldDrawShadow != inValue) {
        shouldDrawShadow = inValue;
        [self setNeedsDisplay:YES];        
    }
}


- (NSAttributedString *)titleString {
    return titleString;
}
- (void)setTitleString:(NSAttributedString *)inValue {
    if (titleString != inValue) {
        [inValue retain];
        [titleString autorelease];
        titleString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSAttributedString *)xAxisLabelString {
    return xAxisLabelString;
}
- (void)setXAxisLabelString:(NSAttributedString *)inValue {
    if (xAxisLabelString != inValue) {
        [inValue retain];
        [xAxisLabelString autorelease];
        xAxisLabelString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSAttributedString *)yAxisLabelString {
    return yAxisLabelString;
}
- (void)setYAxisLabelString:(NSAttributedString *)inValue {
    if (yAxisLabelString != inValue) {
        [inValue retain];
        [yAxisLabelString autorelease];
        yAxisLabelString = inValue;
        [self setNeedsDisplay:YES];        
    }
}

- (NSString *)keyForXValue {
	return keyForXValue;
}
- (void)setKeyForXValue:(NSString *)inValue {
	if (keyForXValue != inValue) {
        [inValue retain];
        [keyForXValue autorelease];
        keyForXValue = inValue;

        if ([keyForXValue isEqualToString:@"Time"]) {
            [self setXAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"Time (minutes) \u2192"] attributes:[xAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else if ([keyForXValue isEqualToString:@"Scan"]) {
            [self setXAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"Scan \u2192"]  attributes:[xAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else if ([keyForXValue isEqualToString:@"Mass"]) {
            [self setXAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"m/z Values \u2192"]  attributes:[xAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else if ([keyForXValue isEqualToString:@"Retention Index"]) {
            [self setXAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"Retention Index \u2192"]  attributes:[xAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else if ([keyForXValue hasPrefix:@"Factor"]) {
            [self setXAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", keyForXValue, [NSString stringWithUTF8String:"\u2192"]] attributes:[xAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        }
        
        int i, count;
        count = [[self dataSeries] count];
        for (i=0; i<count; i++){
            [[[self dataSeries] objectAtIndex:i] setKeyForXValue:inValue];
        }    
        [self showAll:self];
        [self setNeedsDisplay:YES];        
    }
}

//- (NSArray *)availableKeys {
//    if (![self dataSeries] || [[self dataSeries] count] == 0) {
//        return nil;
//    }
//    // Assumes that the first datapoint in the first dataseries is representative for all
//    // This *should* be the case though.
//    return [[[self dataSeries] objectAtIndex:0] dataArrayKeys];
//}

- (NSArray *)acceptableKeysForXValue {
    if (![self dataSeries] || [[self dataSeries] count] == 0) {
        return nil;
    }
    // Assumes that the first datapoint in the first dataseries is representative for all
    // This *should* be the case though.
    return [[[self dataSeries] objectAtIndex:0] acceptableKeysForXValue];    
}

- (NSArray *)acceptableKeysForYValue {
    if (![self dataSeries] || [[self dataSeries] count] == 0) {
        return nil;
    }
    // Assumes that the first datapoint in the first dataseries is representative for all
    // This *should* be the case though.
    return [[[self dataSeries] objectAtIndex:0] acceptableKeysForYValue];    
}

- (NSString *)keyForYValue {
	return keyForYValue;
}
- (void)setKeyForYValue:(NSString *)inValue {
	if (keyForYValue != inValue) {
        [inValue retain];
        [keyForYValue autorelease];
        keyForYValue = inValue;
        
        if ([keyForYValue isEqualToString:@"Total Intensity"]) {
            [self setYAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"Total Intensity \u2192"] attributes:[yAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else  if ([keyForYValue isEqualToString:@"Intensity"]) {
            [self setYAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithUTF8String:"Intensity \u2192"] attributes:[yAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        } else if ([keyForYValue hasPrefix:@"Factor"]) {
            [self setYAxisLabelString:[[[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ %@", keyForYValue, [NSString stringWithUTF8String:"\u2192"]] attributes:[yAxisLabelString attributesAtIndex:0 effectiveRange:nil]] autorelease]];
        }
        
        
        int i, count;
        count = [[self dataSeries] count];
        
        for (i=0;i<count; i++){
            [[[self dataSeries] objectAtIndex:i] setKeyForYValue:inValue];
        }
        [self showAll:self];
        [self setNeedsDisplay:YES];        
    }
}

- (NSFont *)labelFont {
    return labelFont;
}
- (void)setLabelFont:(id)inValue {
    if (labelFont != inValue) {
        [inValue retain];
        [labelFont autorelease];
        labelFont = inValue;
        [self setNeedsDisplay:YES]; 
    }
}

- (NSFont *)legendFont {
    return legendFont;
}
- (void)setLegendFont:(id)inValue {
    if (legendFont != inValue) {
        [inValue retain];
        [legendFont autorelease];
        legendFont = inValue;
        [self setNeedsDisplay:YES]; 
    }
}


- (NSFont *)axesLabelFont {
    return axesLabelFont;
}
- (void)setAxesLabelFont:(id)inValue {
    if (axesLabelFont != inValue) {
        [inValue retain];
        [axesLabelFont autorelease];
        axesLabelFont = inValue;
        [self setNeedsDisplay:YES]; 
    }
}


- (BOOL)shouldDrawBaseline {
	return shouldDrawBaseline;
}
- (void)setShouldDrawBaseline:(BOOL)inValue {
//    if (shouldDrawBaseline != inValue) {
        shouldDrawBaseline = inValue;

        int i,count = [[self dataSeries] count];
        for (i=0; i <  count; i++) {
            [[[self dataSeries] objectAtIndex:i] setShouldDrawBaseline:inValue];
        }
        [self setNeedsDisplayInRect:[self plottingArea]];        
//    }
}

- (BOOL)shouldDrawPeaks {
	return shouldDrawPeaks;
}
- (void)setShouldDrawPeaks:(BOOL)inValue {
//    if (shouldDrawPeaks != inValue) {
        shouldDrawPeaks = inValue;
        
        int i,count = [[self dataSeries] count];
        for (i=0; i <  count; i++) {
            [[[self dataSeries] objectAtIndex:i] setShouldDrawPeaks:inValue];
        }
        [self setNeedsDisplayInRect:[self plottingArea]];        
//    }
}

- (int)selectedScan {
	return selectedScan;
}
- (void)setSelectedScan:(int)inValue {
    if (selectedScan != inValue) {
//        NSPoint startPoint;
//        startPoint = [[self transformGraphToScreen] transformPoint:NSMakePoint(selectedScan,0.0)];
//        NSPoint endPoint;
//        endPoint = [[self transformGraphToScreen] transformPoint:NSMakePoint(inValue,0.0)];
        NSRect dirtyRect = [self plottingArea];
//        if (startPoint.x < endPoint.x) {
//            dirtyRect.origin.x = startPoint.x-2.0;
//            dirtyRect.size.width = endPoint.x-startPoint.x+4.0;            
//        } else {
//            dirtyRect.origin.x = endPoint.x-2.0;
//            dirtyRect.size.width = startPoint.x-endPoint.x+4.0;
//        }
        selectedScan = inValue;
        [self setNeedsDisplayInRect:dirtyRect];        
    }
}

#pragma mark (calculated)
- (BOOL)hasPeaks {
    if ([[self peaks] count] > 0) {
        return YES;
    } else {
        return NO;
    }
}

- (NSNumber *)xMinimum {
	NSPoint plotCorner;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithFloat:plotCorner.x];
}
- (void)setXMinimum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:([self plottingArea].size.width)/([[self xMaximum] floatValue] - [inValue floatValue])]];
	
	newOrigin.x = [self plottingArea].origin.x - [inValue floatValue] * [[self pixelsPerXUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)xMaximum {
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	plotSize = [[self transformScreenToGraph] transformSize:[self plottingArea].size];
	return [NSNumber numberWithFloat:(plotCorner.x + plotSize.width)];	
}
- (void)setXMaximum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerXUnit:[NSNumber numberWithFloat:([self plottingArea].size.width)/([inValue floatValue] - [[self xMinimum] floatValue])]];
	
	newOrigin.x = [self plottingArea].origin.x + [self plottingArea].size.width - [inValue floatValue] * [[self pixelsPerXUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
	
}

- (NSNumber *)yMinimum {
	NSPoint plotCorner;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	return [NSNumber numberWithFloat:plotCorner.y];	
}
- (void)setYMinimum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:([self plottingArea].size.height)/([[self yMaximum] floatValue] - [inValue floatValue])]];
	
	newOrigin.y = [self plottingArea].origin.y - [inValue floatValue] * [[self pixelsPerYUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)yMaximum {
	NSPoint plotCorner;
	NSSize plotSize;
	plotCorner = [[self transformScreenToGraph] transformPoint:[self plottingArea].origin];
	plotSize = [[self transformScreenToGraph] transformSize:[self plottingArea].size];
	return [NSNumber numberWithFloat:(plotCorner.y + plotSize.height)];	
}
- (void)setYMaximum:(NSNumber *)inValue {
	NSPoint newOrigin;
	newOrigin = [self origin];
	
	[self setPixelsPerYUnit:[NSNumber numberWithFloat:([self plottingArea].size.height)/([inValue floatValue] - [[self yMinimum] floatValue])]];
	
	newOrigin.y = [self plottingArea].origin.y + [self plottingArea].size.height  - [inValue floatValue] * [[self pixelsPerYUnit] floatValue];
	[self setOrigin:newOrigin];
	[self calculateCoordinateConversions];
    [self setNeedsDisplay:YES];
}

- (NSNumber *)unitsPerMajorX {
	float a,b;
	a = [[self pixelsPerXUnit] floatValue];
	b = [[self minimumPixelsPerMajorGridLine] floatValue];
	return [NSNumber numberWithFloat:a/b];
}

- (void)setUnitsPerMajorX:(NSNumber *)inValue {
}

- (NSNumber *)unitsPerMajorY {
	return [NSNumber numberWithInt:-1];
}

- (void)setUnitsPerMajorY:(NSNumber *)inValue {
}



@synthesize baselineContainer;
@synthesize _startedResizePlottingAreaTop;
@synthesize _didDrag;
@synthesize _startedInsideLegendArea;
@synthesize _lowestXOriginLabelsYAxis;
@synthesize _lastSelectedPeakIndex;
@synthesize _startedResizePlottingAreaBottom;
@synthesize _startedResizePlottingAreaRight;
@synthesize _startedInsidePlottingArea;
@synthesize _startedResizePlottingAreaLeft;
@synthesize baselineKeyPath;
@synthesize _lowestYOriginLabelsXAxis;
@end

