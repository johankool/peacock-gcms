//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

extern NSString *const MyGraphView_DidBecomeFirstResponderNotification;
extern NSString *const MyGraphView_DidResignFirstResponderNotification;

@protocol MyGraphViewDelegateProtocol
- (void)showSpectrumForScan:(int)scan;

@end

@interface MyGraphView : NSView {
	id delegate; // Conformance to MyGraphViewDelegateProtocol is optional
	
	// Bindings support
	NSArrayController *dataSeriesContainer;
    NSString *dataSeriesKeyPath;
	
	NSArrayController *peaksContainer;
    NSString *peaksKeyPath;

	NSArrayController *baselineContainer;
    NSString *baselineKeyPath;
	
    NSAffineTransform *transformGraphToScreen;     
	NSAffineTransform *transformScreenToGraph;
	NSNumber *pixelsPerXUnit, *pixelsPerYUnit;
	NSNumber *minimumPixelsPerMajorGridLine;
	NSString *keyForXValue;
	NSString *keyForYValue;
	NSPoint origin;
	NSRect plottingArea;
	NSRect legendArea;
	NSRect selectedRect;
	NSColor *backColor;
	NSColor *plottingAreaColor;
	NSColor *axesColor;	// Also used for tickmarks
	NSColor *gridColor;
	NSColor *labelsColor;
	NSColor *labelsOnFrameColor;
	NSColor *frameColor;
	NSColor *legendAreaColor;
	NSColor *legendFrameColor;
	BOOL shouldDrawLegend;
	BOOL shouldDrawAxes;
	BOOL shouldDrawMajorTickMarks;
	BOOL shouldDrawMinorTickMarks;
	BOOL shouldDrawGrid;
	BOOL shouldDrawLabels;
	BOOL shouldDrawLabelsOnFrame;
	
	// Additions for Peacock
	BOOL shouldDrawBaseline;
	BOOL shouldDrawPeaks;
	
	NSAttributedString *titleString;
	NSAttributedString *xAxisLabelString;
	NSAttributedString *yAxisLabelString;
	
	// Temporary storage items
	BOOL _didDrag;
	BOOL _startedInsidePlottingArea;
	BOOL _startedInsideLegendArea;
	
	NSPoint _mouseDownAtPoint;
	NSPoint _oldOrigin;
	NSPoint _oldLegendOrigin;
	int _lastSelectedPeakIndex;
}

#pragma mark DRAWING ROUTINES
- (void)drawGrid;
- (void)drawMajorTickMarks;
- (void)drawMinorTickMarks;
- (void)drawLegend;
- (void)drawAxes;
- (void)drawTitles;
- (void)drawLabels;
- (void)drawLabelsOnFrame;
- (void)refresh;

// Additions for Peacock
- (void)drawBaseline;
//- (void)drawPeaks;

#pragma mark ACTION ROUTINES
- (void)centerOrigin:(id)sender;
- (void)lowerLeftOrigin:(id)sender;
- (void)squareAxes:(id)sender;
- (void)showAll:(id)sender;

#pragma mark HELPER ROUTINES
- (void)calculateCoordinateConversions;
- (void)zoomToRect:(NSRect)rect;
- (void)zoomToRectInView:(NSRect)aRect;
- (void)zoomIn;
- (void)zoomOut;
- (void)moveLeft;
- (void)moveRight;
- (void)moveUp;
- (void)moveDown;
- (void)selectNextPeak; 
- (void)selectPreviousPeak;
- (float)unitsPerMajorGridLine:(float)pixelsPerUnit;

#pragma mark BINDINGS
- (NSMutableArray *)dataSeries;
- (NSObject *)dataSeriesContainer;
- (void)setDataSeriesContainer:(NSObject *)aDataSeriesContainer;
- (NSString *)dataSeriesKeyPath;
- (void)setDataSeriesKeyPath:(NSString *)aDataSeriesKeyPath;

- (NSMutableArray *)peaks;
- (NSObject *)peaksContainer;
- (void)setPeaksContainer:(NSObject *)aPeaksContainer;
- (NSString *)peaksKeyPath;
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath;

- (NSMutableArray *)baseline;
- (NSObject *)baselineContainer;
- (void)setBaselineContainer:(NSObject *)aBaselineContainer;
- (NSString *)baselineKeyPath;
- (void)setBaselineKeyPath:(NSString *)aBaselineKeyPath;

#pragma mark ACCESSORS
- (id)delegate;
- (void)setDelegate:(id)inValue;
- (NSAffineTransform *)transformGraphToScreen;
- (void)setTransformGraphToScreen:(NSAffineTransform *)inValue;
- (NSAffineTransform *)transformScreenToGraph;
- (void)setTransformScreenToGraph:(NSAffineTransform *)inValue;
- (NSNumber *)pixelsPerXUnit;
- (void)setPixelsPerXUnit:(NSNumber *)inValue;
- (NSNumber *)pixelsPerYUnit;
- (void)setPixelsPerYUnit:(NSNumber *)inValue;
- (NSNumber *)minimumPixelsPerMajorGridLine;
- (void)setMinimumPixelsPerMajorGridLine:(NSNumber *)inValue;
- (NSPoint)origin;
- (void)setOrigin:(NSPoint)inValue;
- (NSRect)plottingArea;
- (void)setPlottingArea:(NSRect)inValue;
- (NSRect)legendArea;
- (void)setLegendArea:(NSRect)inValue;
- (NSRect)selectedRect;
- (void)setSelectedRect:(NSRect)inValue;

// Colors
- (NSColor *)backColor;
- (void)setBackColor:(NSColor *)inValue;
- (NSColor *)plottingAreaColor;
- (void)setPlottingAreaColor:(NSColor *)inValue;
- (NSColor *)axesColor;
- (void)setAxesColor:(NSColor *)inValue;
- (NSColor *)gridColor;
- (void)setGridColor:(NSColor *)inValue;
- (NSColor *)labelsColor;
- (void)setLabelsColor:(NSColor *)inValue;
- (NSColor *)labelsOnFrameColor;
- (void)setLabelsOnFrameColor:(NSColor *)inValue;
- (NSColor *)frameColor;
- (void)setFrameColor:(NSColor *)inValue;
- (NSColor *)legendAreaColor;
- (void)setLegendAreaColor:(NSColor *)inValue;
- (NSColor *)legendFrameColor;
- (void)setLegendFrameColor:(NSColor *)inValue;

// Drawing options
- (BOOL)shouldDrawLegend;
- (void)setShouldDrawLegend:(BOOL)inValue;
- (BOOL)shouldDrawAxes;
- (void)setShouldDrawAxes:(BOOL)inValue;
- (BOOL)shouldDrawMajorTickMarks;
- (void)setShouldDrawMajorTickMarks:(BOOL)inValue;
- (BOOL)shouldDrawMinorTickMarks;
- (void)setShouldDrawMinorTickMarks:(BOOL)inValue;
- (BOOL)shouldDrawGrid;
- (void)setShouldDrawGrid:(BOOL)inValue;
- (BOOL)shouldDrawLabels;
- (void)setShouldDrawLabels:(BOOL)inValue;
- (BOOL)shouldDrawLabelsOnFrame;
- (void)setShouldDrawLabelsOnFrame:(BOOL)inValue;

// Text
- (NSAttributedString *)titleString;
- (void)setTitleString:(NSAttributedString *)inValue;
- (NSAttributedString *)xAxisLabelString;
- (void)setXAxisLabelString:(NSAttributedString *)inValue;
- (NSAttributedString *)yAxisLabelString;
- (void)setYAxisLabelString:(NSAttributedString *)inValue;

// Additions for Peacock
- (BOOL)shouldDrawBaseline;
- (void)setShouldDrawBaseline:(BOOL)inValue;
- (BOOL)shouldDrawPeaks;
- (void)setShouldDrawPeaks:(BOOL)inValue;

#pragma mark CALCULATED ACCESSORS
// Zooming
- (NSNumber *)xMinimum;
- (void)setXMinimum:(NSNumber *)inValue;
- (NSNumber *)xMaximum;
- (void)setXMaximum:(NSNumber *)inValue;
- (NSNumber *)yMinimum;
- (void)setYMinimum:(NSNumber *)inValue;
- (NSNumber *)yMaximum;
- (void)setYMaximum:(NSNumber *)inValue;
- (NSString *)keyForXValue;
- (void)setKeyForXValue:(NSString *)inValue;
- (NSString *)keyForYValue;
- (void)setKeyForYValue:(NSString *)inValue;
- (NSNumber *)unitsPerMajorX;
- (void)setUnitsPerMajorX:(NSNumber *)inValue;
- (NSNumber *)unitsPerMajorY;
- (void)setUnitsPerMajorY:(NSNumber *)inValue;
@end
