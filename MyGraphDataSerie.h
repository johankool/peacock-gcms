//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@protocol GraphDataSerie
-(NSString *)seriesTitle;
-(void)setSeriesTitle:(NSString *)inValue;
-(NSString *)keyForXValue;
-(void)setKeyForXValue:(NSString *)inValue;
-(NSString *)keyForYValue;
-(void)setKeyForYValue:(NSString *)inValue;
-(NSColor *)seriesColor;
-(void)setSeriesColor:(NSColor *)inValue;

-(void)plotDataWithTransform:(NSAffineTransform *)trans;
-(void)transposeAxes;
-(NSRect)boundingRect;
@end

@interface MyGraphDataSerie : NSObject <GraphDataSerie> {
	NSMutableArray *dataArray; 
	NSString *seriesTitle;
	NSString *keyForXValue;
	NSString *keyForYValue;
	NSColor *seriesColor;
	int seriesType; // 0 = points, 1 = lines, 2 = spectrum
	NSBezierPath *plotPath;
	BOOL shouldDrawLabels;
	NSNumber *verticalScale;
	
	NSArray *oldData;		
}

#pragma mark DRAWING ROUTINES
-(void)plotDataWithTransform:(NSAffineTransform *)trans;
-(void)drawLabelsWithTransform:(NSAffineTransform *)trans;
-(void)constructPlotPath;

#pragma mark HELPER ROUTINES
-(void)transposeAxes;
-(NSRect)boundingRect;

#pragma mark KEY VALUE OBSERVING MANAGEMENT
- (void)startObservingData:(NSArray *)data;
- (void)stopObservingData:(NSArray *)data;

#pragma mark MISC
-(NSArray *)dataArrayKeys;
-(void)loadDataPoints:(int)npts withXValues:(double *)xpts andYValues:(double *)ypts ;

#pragma mark ACCESSORS
-(NSMutableArray *)dataArray;
-(void)setDataArray:(NSMutableArray *)inValue;
-(NSString *)seriesTitle;
-(void)setSeriesTitle:(NSString *)inValue;
-(NSString *)keyForXValue;
-(void)setKeyForXValue:(NSString *)inValue;
-(NSString *)keyForYValue;
-(void)setKeyForYValue:(NSString *)inValue;
-(NSColor *)seriesColor;
-(void)setSeriesColor:(NSColor *)inValue;
-(int)seriesType;
-(void)setSeriesType:(int)inValue;
-(NSBezierPath *)plotPath;
-(void)setPlotPath:(NSBezierPath *)inValue;
-(BOOL)shouldDrawLabels;
-(void)setShouldDrawLabels:(BOOL)inValue;
-(NSNumber *)verticalScale;
-(void)setVerticalScale:(NSNumber *)inValue;

- (NSArray *)oldData;
- (void)setOldData:(NSArray *)anOldData;
@end
