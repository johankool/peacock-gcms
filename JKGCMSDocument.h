//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class BDAlias;
@class ChromatogramGraphDataSerie;
@class JKLibrarySearch;
@class JKMainWindowController;
@class JKPeakRecord;
@class JKSpectrum;


extern NSString *const JKGCMSDocument_DocumentDeactivateNotification;
extern NSString *const JKGCMSDocument_DocumentActivateNotification;
extern NSString *const JKGCMSDocument_DocumentLoadedNotification;
extern int const JKGCMSDocument_Version;

@interface JKGCMSDocument : NSDocument
{
	// Window controller
    JKMainWindowController *mainWindowController;
	
	// File representation
	int ncid;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
	
	// Data from NetCDF cached for speedier access
    int numberOfPoints;
    int intensityCount;
	
    float *time;
    float *totalIntensity;
	
	float minimumTime;
	float maximumTime;
	float minimumTotalIntensity;
	float maximumTotalIntensity;
	
    BOOL hasSpectra;
	
    NSMutableArray *chromatograms;    
	
	// Data stored in Peacock's file because it can't be represented in Andi file format
    NSMutableArray *peaks;
    NSMutableArray *baseline;
	NSMutableDictionary *metadata;
	
	// Baseline
	NSNumber *baselineWindowWidth;
	NSNumber *baselineDistanceThreshold;
	NSNumber *baselineSlopeThreshold;
	NSNumber *baselineDensityThreshold;
	// Peak identification
	NSNumber *peakIdentificationThreshold;
	// RetentionIndex = retentionSlope * retentionTime +  retentionRemainder
	NSNumber *retentionIndexSlope;     
	NSNumber *retentionIndexRemainder;
	// Search options
	BDAlias *libraryAlias;
	int scoreBasis;
	BOOL penalizeForRetentionIndex;
	NSNumber *markAsIdentifiedThreshold;
	NSNumber *minimumScoreSearchResults;
		
	@private
	BOOL abortAction;
	NSString *remainingString;
	JKGCMSDocument *document;
}

#pragma mark IMPORT/EXPORT ACTIONS

- (NSString *)exportTabDelimitedText;
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;

- (NSArray *)readJCAMPString:(NSString *)inString;
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument;

#pragma mark ACTIONS

- (ChromatogramGraphDataSerie *)obtainTICChromatogram;
- (void)obtainBaseline;
- (void)addChromatogramForMass:(NSString *)inString;
- (ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString;
- (void)identifyPeaks;
- (void)resetToDefaultValues;
- (BOOL)searchLibraryForAllPeaks:(id)sender;
- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak;

#pragma mark HELPER ACTIONS

- (float)baselineValueAtScan:(int)inValue;

#pragma mark ACCESSORS
- (JKMainWindowController *)mainWindowController;
- (void)setNcid:(int)inValue;
- (int)ncid;

- (int)numberOfPoints;

- (void)setHasSpectra:(BOOL)inValue;
- (BOOL)hasSpectra;

- (int)intensityCount;
- (void)setIntensityCount:(int)inValue;

- (void)setTime:(float *)inArray withCount:(int)inValue;
- (float *)time;
- (float)timeForScan:(int)scan;

- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue;
- (float *)totalIntensity;

- (float)maximumTime;
- (float)minimumTime;
- (float)maximumTotalIntensity;
- (float)minimumTotalIntensity;

- (NSMutableArray *)chromatograms;
	//-(void)setChromatograms:(NSMutableArray *)inValue;

//- (void)setPeaks:(NSMutableArray *)inValue;
//- (NSMutableArray *)peaks;
- (void)setBaseline:(NSMutableArray *)inValue ;
- (NSMutableArray *)baseline;
- (NSMutableDictionary *)metadata;

- (float *)xValuesSpectrum:(int)scan;
- (float *)yValuesSpectrum:(int)scan;
- (float *)yValuesIonChromatogram:(float)mzValue;
- (int)startValuesSpectrum:(int)scan;
- (int)endValuesSpectrum:(int)scan;
- (float)retentionIndexForScan:(int)scan;

#pragma mark ACTIONS

//- (NSMutableArray *)searchLibraryForPeak:(JKPeakRecord *)peak;
- (BOOL)searchLibraryForAllPeaks:(id)sender;

#pragma mark ACCESSORS (MACROSTYLE)
//idAccessor_h(peaks, setPeaks);
- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)array;
- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index;
- (void)removeObjectFromPeaksAtIndex:(int)index;
- (void)startObservingPeak:(JKPeakRecord *)peak;
- (void)stopObservingPeak:(JKPeakRecord *)peak;

idAccessor_h(baselineWindowWidth, setBaselineWindowWidth)
idAccessor_h(baselineDistanceThreshold, setBaselineDistanceThreshold)
idAccessor_h(baselineSlopeThreshold, setBaselineSlopeThreshold)
idAccessor_h(baselineDensityThreshold, setBaselineDensityThreshold)
idAccessor_h(peakIdentificationThreshold, setPeakIdentificationThreshold)
idAccessor_h(retentionIndexSlope, setRetentionIndexSlope)
idAccessor_h(retentionIndexRemainder, setRetentionIndexRemainder)
idAccessor_h(libraryAlias, setLibraryAlias)
intAccessor_h(scoreBasis, setScoreBasis)
boolAccessor_h(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor_h(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold)
idAccessor_h(minimumScoreSearchResults, setMinimumScoreSearchResults)

boolAccessor_h(abortAction, setAbortAction)

@end
