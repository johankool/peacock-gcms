//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "NSView+AMAnimationAdditions.h"

extern NSString *const MyGraphView_DidBecomeFirstResponderNotification;
extern NSString *const MyGraphView_DidResignFirstResponderNotification;

@protocol MyGraphViewDelegateProtocol
-(void)showSpectrumForScan:(int)scan;

@end

@interface MyGraphView : NSView {
	id <MyGraphViewDelegateProtocol> delegate;
	
	// Bindings support
	NSObject *dataSeriesContainer;
    NSString *dataSeriesKeyPath;
	NSObject *dataSeriesSelectionIndexesContainer;
    NSString *dataSeriesSelectionIndexesKeyPath;
	
	NSObject *peaksContainer;
    NSString *peaksKeyPath;
	NSObject *peaksSelectionIndexesContainer;
    NSString *peaksSelectionIndexesKeyPath;

	NSObject *baselineContainer;
    NSString *baselineKeyPath;
	NSObject *baselineSelectionIndexesContainer;
    NSString *baselineSelectionIndexesKeyPath;
	
    NSAffineTransform *trans;          // Van grafiek naar scherm coords     
	NSAffineTransform *inverseTrans;   // Van scherm naar grafiek coords 
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
	NSAttributedString *titleString;
	NSAttributedString *xAxisLabelString;
	NSAttributedString *yAxisLabelString;
	
	// Temporary storage items
	BOOL didDrag;
	NSPoint mouseDownAtPoint;
	NSPoint oldOrigin;
	
	// Additions for Peacock
	BOOL shouldDrawBaseline;
	BOOL shouldDrawPeaks;
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
- (void)zoomOut;
- (void)moveLeft;
- (void)moveRight;
- (void)moveUp;
- (void)moveDown;
- (float)unitsPerMajorGridLine:(float)pixelsPerUnit;

#pragma mark BINDINGS
- (NSMutableArray *)dataSeries;
- (NSObject *)dataSeriesContainer;
- (void)setDataSeriesContainer:(NSObject *)aDataSeriesContainer;
- (NSString *)dataSeriesKeyPath;
- (void)setDataSeriesKeyPath:(NSString *)aDataSeriesKeyPath;

- (NSIndexSet *)dataSeriesSelectionIndexes;
- (NSObject *)dataSeriesSelectionIndexesContainer;
- (void)setDataSeriesSelectionIndexesContainer:(NSObject *)aDataSeriesSelectionIndexesContainer;
- (NSString *)dataSeriesSelectionIndexesKeyPath;
- (void)setDataSeriesSelectionIndexesKeyPath:(NSString *)aDataSeriesSelectionIndexesKeyPath;

- (NSMutableArray *)peaks;
- (NSObject *)peaksContainer;
- (void)setPeaksContainer:(NSObject *)aPeaksContainer;
- (NSString *)peaksKeyPath;
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath;

- (NSIndexSet *)peaksSelectionIndexes;
- (NSObject *)peaksSelectionIndexesContainer;
- (void)setPeaksSelectionIndexesContainer:(NSObject *)aPeaksSelectionIndexesContainer;
- (NSString *)peaksSelectionIndexesKeyPath;
- (void)setPeaksSelectionIndexesKeyPath:(NSString *)aPeaksSelectionIndexesKeyPath;

- (NSMutableArray *)baseline;
- (NSObject *)baselineContainer;
- (void)setBaselineContainer:(NSObject *)aBaselineContainer;
- (NSString *)baselineKeyPath;
- (void)setBaselineKeyPath:(NSString *)aBaselineKeyPath;

- (NSIndexSet *)baselineSelectionIndexes;
- (NSObject *)baselineSelectionIndexesContainer;
- (void)setBaselineSelectionIndexesContainer:(NSObject *)aBaselineSelectionIndexesContainer;
- (NSString *)baselineSelectionIndexesKeyPath;
- (void)setBaselineSelectionIndexesKeyPath:(NSString *)aBaselineSelectionIndexesKeyPath;

#pragma mark ACCESSORS
- (id)delegate;
- (void)setDelegate:(id)inValue;
- (NSAffineTransform *)trans;
- (void)setTrans:(NSAffineTransform *)inValue;
- (NSAffineTransform *)inverseTrans;
- (void)setInverseTrans:(NSAffineTransform *)inValue;
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
