//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class MyGraphView;

@protocol GraphDataSerie
- (BOOL)shouldDrawLabels;
- (void)setShouldDrawLabels:(BOOL)shouldDrawLabels;

- (NSColor *)seriesColor;
- (void)setSeriesColor:(NSColor *)inValue;
- (NSNumber *)verticalScale;
- (void)setVerticalScale:(NSNumber *)inValue;
- (NSString *)seriesTitle;
- (void)setSeriesTitle:(NSString *)inValue;

- (NSString *)keyForXValue;
- (void)setKeyForXValue:(NSString *)inValue;
- (NSArray *)acceptableKeysForXValue;
- (void)setAcceptableKeysForXValue:(NSArray *)inValue;

- (NSString *)keyForYValue;
- (void)setKeyForYValue:(NSString *)inValue;
- (NSArray *)acceptableKeysForYValue;
- (void)setAcceptableKeysForYValue:(NSArray *)inValue;

- (NSString *)keyForLabel;
- (void)setKeyForLabel:(NSString *)inValue;
- (NSArray *)acceptableKeysForLabel;
- (void)setAcceptableKeysForLabel:(NSArray *)inValue;

- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view;
- (void)transposeAxes;
- (NSRect)boundingRect;
@end

typedef enum {
    JKPointsSeriesType,
    JKLineSeriesType,
    JKSpectrumSeriesType
} JKSeriesTypes;

@interface MyGraphDataSerie : NSObject <NSCoding, GraphDataSerie> {
	BOOL shouldDrawLabels;
    BOOL observeData;
	JKSeriesTypes seriesType;
	NSColor *seriesColor;
	NSNumber *verticalScale;
	NSString *seriesTitle;
    
	NSMutableArray *dataArray; 
	
    NSString *keyForXValue;
    NSArray *acceptableKeysForXValue;
    
	NSString *keyForYValue;
    NSArray *acceptableKeysForYValue;

    NSString *keyForLabel;
    NSArray *acceptableKeysForLabel;

    BOOL _needsReconstructingPlotPath;
    MyGraphView *_graphView;
    NSAffineTransform *_previousTrans;
    NSArray *_oldData;		
    NSBezierPath *_plotPath;
    NSRect _boundsRect;
    float _lowestX, _highestX, _lowestY, _highestY;
}

#pragma mark Drawing Routines
- (void)plotDataWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view;
- (void)drawLabelsWithTransform:(NSAffineTransform *)trans inView:(MyGraphView *)view;
- (void)constructPlotPath;
#pragma mark -

#pragma mark Helper Routines
- (void)transposeAxes;
- (NSRect)boundingRect;
#pragma mark -

#pragma mark Key Value Observing Management
- (void)startObservingData:(NSArray *)data;
- (void)stopObservingData:(NSArray *)data;
#pragma mark -

#pragma mark Misc
- (void)loadDataPoints:(int)npts withXValues:(float *)xpts andYValues:(float *)ypts ;
#pragma mark -

#pragma mark Accessors
- (NSMutableArray *)dataArray;
- (void)setDataArray:(NSMutableArray *)inValue;
- (NSString *)seriesTitle;
- (void)setSeriesTitle:(NSString *)inValue;
- (NSString *)keyForXValue;
- (void)setKeyForXValue:(NSString *)inValue;
- (NSString *)keyForYValue;
- (void)setKeyForYValue:(NSString *)inValue;
- (NSString *)keyForLabel ;
- (void)setKeyForLabel:(NSString *)inValue;
- (NSColor *)seriesColor;
- (void)setSeriesColor:(NSColor *)inValue;
- (int)seriesType;
- (void)setSeriesType:(int)inValue;
- (NSBezierPath *)plotPath;
- (void)setPlotPath:(NSBezierPath *)inValue;
- (BOOL)shouldDrawLabels;
- (void)setShouldDrawLabels:(BOOL)inValue;
- (NSNumber *)verticalScale;
- (void)setVerticalScale:(NSNumber *)inValue;
#pragma mark -

#pragma mark Private Methods
- (NSArray *)oldData;
- (void)setOldData:(NSArray *)anOldData;
- (NSAffineTransform *)oldTrans;
- (void)setOldTrans:(NSAffineTransform *)anOldTrans;
@end
