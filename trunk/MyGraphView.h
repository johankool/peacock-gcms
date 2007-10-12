//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class JKPeakRecord;
@class JKChromatogram;

extern NSString *const MyGraphView_DidBecomeFirstResponderNotification;
extern NSString *const MyGraphView_DidResignFirstResponderNotification;

@protocol MyGraphViewDelegateProtocol
- (void)showSpectrumForScan:(int)scan;
- (void)showChromatogramForModel:(NSString *)modelString;
@end

typedef enum {
    JKNormalDrawingMode,
    JKStackedDrawingMode
} JKDrawingModes;

typedef enum {
    JKNoOperation,
    JKDragOperation,
    JKZoomOperation,
    JKZoomHorizontalOnlyOperation,
    JKZoomVerticalOnlyOperation,
    JKZoomOutOperation,
    JKSelectPeakOperation,
    JKSelectBaselinePointsOperation,
    JKLeftResizePlottingAreaOperation,
    JKRightResizePlottingAreaOperation,
    JKTopResizePlottingAreaOperation,
    JKBottomResizePlottingAreaOperation,
    JKAddPeakOperation,
    JKDragLegendOperation
} JKOperations;

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
	NSColor *baselineColor;
	BOOL shouldDrawLegend;
	BOOL shouldDrawAxes;
	BOOL shouldDrawAxesHorizontal;
	BOOL shouldDrawAxesVertical;
    BOOL shouldDrawFrame;
    BOOL shouldDrawFrameLeft;
    BOOL shouldDrawFrameBottom;
	BOOL shouldDrawMajorTickMarks;
	BOOL shouldDrawMajorTickMarksHorizontal;
	BOOL shouldDrawMajorTickMarksVertical;
	BOOL shouldDrawMinorTickMarks;
	BOOL shouldDrawMinorTickMarksHorizontal;
	BOOL shouldDrawMinorTickMarksVertical;
	BOOL shouldDrawGrid;
	BOOL shouldDrawLabels;
	BOOL shouldDrawLabelsOnFrame;
	BOOL shouldDrawLabelsOnFrameLeft;
	BOOL shouldDrawLabelsOnFrameBottom;
	BOOL shouldDrawShadow;
    NSFont *labelFont;
    NSFont *axesLabelFont;
    NSFont *legendFont;
    JKDrawingModes drawingMode;
    
	// Additions for Peacock
	BOOL shouldDrawBaseline;
	BOOL shouldDrawPeaks;
	int selectedScan;
    
	NSAttributedString *titleString;
	NSAttributedString *xAxisLabelString;
	NSAttributedString *yAxisLabelString;
	
	// Temporary storage items
    JKOperations _startedOperation;
	BOOL _didDrag;
	BOOL _startedInsidePlottingArea;
	BOOL _startedInsideLegendArea;
	BOOL _startedResizePlottingAreaLeft;
	BOOL _startedResizePlottingAreaRight;
	BOOL _startedResizePlottingAreaTop;
	BOOL _startedResizePlottingAreaBottom;
    
	NSPoint _mouseDownAtPoint;
	NSPoint _oldOrigin;
	NSPoint _oldLegendOrigin;
	int _lastSelectedPeakIndex;
    float _lowestXOriginLabelsYAxis;
    float _lowestYOriginLabelsXAxis;
}

#pragma mark DRAWING ROUTINES
- (void)drawGrid;
- (void)drawMajorTickMarks;
- (void)drawMinorTickMarks;
- (void)drawFrame;
- (void)drawMajorTickMarksOnFrame;
- (void)drawMinorTickMarksOnFrame;
- (void)drawLegend;
- (void)drawAxes;
- (void)drawTitles;
- (void)drawLabels;
- (void)drawLabelsOnFrame;
- (void)refresh;

// Additions for Peacock
//- (void)drawBaseline;
//- (void)drawPeaks;

#pragma mark ACTION ROUTINES
- (void)centerOrigin:(id)sender;
- (void)lowerLeftOrigin:(id)sender;
- (void)squareAxes:(id)sender;
- (IBAction)showAll:(id)sender;

#pragma mark HELPER ROUTINES
- (void)calculateCoordinateConversions;
- (void)scaleVertically;
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

- (int)scanAtPoint:(NSPoint)aPoint;
- (JKPeakRecord *)peakAtPoint:(NSPoint)aPoint;
- (JKChromatogram *)chromatogramAtPoint:(NSPoint)aPoint;
- (NSMutableDictionary *)pointAtPoint:(NSPoint)aPoint;
- (int)massAtPoint:(NSPoint)aPoint;

#pragma mark BINDINGS
- (NSMutableArray *)dataSeries;
- (NSArrayController *)dataSeriesContainer;
- (void)setDataSeriesContainer:(NSArrayController *)aDataSeriesContainer;
- (NSString *)dataSeriesKeyPath;
- (void)setDataSeriesKeyPath:(NSString *)aDataSeriesKeyPath;

- (NSMutableArray *)peaks;
- (NSArrayController *)peaksContainer;
- (void)setPeaksContainer:(NSArrayController *)aPeaksContainer;
- (NSString *)peaksKeyPath;
- (void)setPeaksKeyPath:(NSString *)aPeaksKeyPath;

//- (NSMutableArray *)baseline;
//- (NSObject *)baselineContainer;
//- (void)setBaselineContainer:(NSObject *)aBaselineContainer;
//- (NSString *)baselineKeyPath;
//- (void)setBaselineKeyPath:(NSString *)aBaselineKeyPath;

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
- (NSColor *)baselineColor;
- (void)setBaselineColor:(NSColor *)inValue;

// Drawing options
- (JKDrawingModes)drawingMode;
- (void)setDrawingMode:(JKDrawingModes)drawingMode;
- (BOOL)shouldDrawLegend;
- (void)setShouldDrawLegend:(BOOL)inValue;
- (BOOL)shouldDrawAxes;
- (void)setShouldDrawAxes:(BOOL)inValue;
- (BOOL)shouldDrawAxesHorizontal;
- (void)setShouldDrawAxesHorizontal:(BOOL)inValue;
- (BOOL)shouldDrawAxesVertical;
- (void)setShouldDrawAxesVertical:(BOOL)inValue;
- (BOOL)shouldDrawFrameLeft;
- (void)setShouldDrawFrameLeft:(BOOL)inValue;
- (BOOL)shouldDrawFrameBottom;
- (void)setShouldDrawFrameBottom:(BOOL)inValue;
- (BOOL)shouldDrawFrame;
- (void)setShouldDrawFrame:(BOOL)inValue;
- (BOOL)shouldDrawMajorTickMarks;
- (void)setShouldDrawMajorTickMarks:(BOOL)inValue;
- (BOOL)shouldDrawMajorTickMarksHorizontal;
- (void)setShouldDrawMajorTickMarksHorizontal:(BOOL)inValue;
- (BOOL)shouldDrawMajorTickMarksVertical;
- (void)setShouldDrawMajorTickMarksVertical:(BOOL)inValue;
- (BOOL)shouldDrawMinorTickMarks;
- (void)setShouldDrawMinorTickMarks:(BOOL)inValue;
- (BOOL)shouldDrawMinorTickMarksHorizontal;
- (void)setShouldDrawMinorTickMarksHorizontal:(BOOL)inValue;
- (BOOL)shouldDrawMinorTickMarksVertical;
- (void)setShouldDrawMinorTickMarksVertical:(BOOL)inValue;
- (BOOL)shouldDrawGrid;
- (void)setShouldDrawGrid:(BOOL)inValue;
- (BOOL)shouldDrawLabels;
- (void)setShouldDrawLabels:(BOOL)inValue;
- (BOOL)shouldDrawLabelsOnFrame;
- (void)setShouldDrawLabelsOnFrame:(BOOL)inValue;
- (BOOL)shouldDrawLabelsOnFrameLeft;
- (void)setShouldDrawLabelsOnFrameLeft:(BOOL)inValue;
- (BOOL)shouldDrawLabelsOnFrameBottom;
- (void)setShouldDrawLabelsOnFrameBottom:(BOOL)inValue;
- (BOOL)shouldDrawShadow;
- (void)setShouldDrawShadow:(BOOL)inValue;

// Text
- (NSAttributedString *)titleString;
- (void)setTitleString:(NSAttributedString *)inValue;
- (NSAttributedString *)xAxisLabelString;
- (void)setXAxisLabelString:(NSAttributedString *)inValue;
- (NSAttributedString *)yAxisLabelString;
- (void)setYAxisLabelString:(NSAttributedString *)inValue;
- (NSFont *)labelFont;
- (void)setLabelFont:(id)inValue;
- (NSFont *)legendFont;
- (void)setLegendFont:(id)inValue;
- (NSFont *)axesLabelFont;
- (void)setAxesLabelFont:(id)inValue;

// Additions for Peacock
- (BOOL)shouldDrawBaseline;
- (void)setShouldDrawBaseline:(BOOL)inValue;
- (BOOL)shouldDrawPeaks;
- (void)setShouldDrawPeaks:(BOOL)inValue;
- (int)selectedScan;
- (void)setSelectedScan:(int)inValue;

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
//- (NSArray *)availableKeys;
- (NSNumber *)unitsPerMajorX;
- (void)setUnitsPerMajorX:(NSNumber *)inValue;
- (NSNumber *)unitsPerMajorY;
- (void)setUnitsPerMajorY:(NSNumber *)inValue;
@end
