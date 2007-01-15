//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class BDAlias;
@class ChromatogramGraphDataSerie;
@class JKChromatogram;
@class JKLibrarySearch;
@class JKMainWindowController;
@class JKPeakRecord;
@class JKSpectrum;
@class SpectrumGraphDataSerie;

extern NSString *const JKGCMSDocument_DocumentDeactivateNotification;
extern NSString *const JKGCMSDocument_DocumentActivateNotification;
extern NSString *const JKGCMSDocument_DocumentLoadedNotification;
extern int const JKGCMSDocument_Version;

/*!
    @class
    @abstract    Document containing GCMS data.
    @discussion  (comprehensive description)
*/
@interface JKGCMSDocument : NSDocument
{
	// Window controller
    JKMainWindowController *mainWindowController;
	
	// File representation
	int ncid;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
	
    BOOL hasSpectra;
    NSMutableArray *chromatograms;    
    
	// Data stored in Peacock's file because it can't be represented in Andi file format
    NSMutableArray *peaks;
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
    NSRect _originalFrame;
    
    // Obsolete
//    float *time;
//    float *totalIntensity;
//	
//	float minimumTime;
//	float maximumTime;
//	float minimumTotalIntensity;
//	float maximumTotalIntensity;
//    NSMutableArray *baseline;
//    
//	// GAML
//    NSString *name;
//    NSDate *collectDate;
//    NSMutableDictionary *parameters;
//	NSMutableArray *experiments;
//    // Data from NetCDF cached for speedier access
// //   int numberOfPoints; // == numberOfScans
//    int intensityCount;
    
}

/*! 
    @functiongroup IMPORT/EXPORT ACTIONS
*/
#pragma mark IMPORT/EXPORT ACTIONS

- (NSString *)exportTabDelimitedText;
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;

- (NSArray *)readJCAMPString:(NSString *)inString;
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument;

/*! 
    @functiongroup Actions
*/
#pragma mark ACTIONS

/*!
    @method     
    @abstract   Identifies peaks using IWV method.
    @discussion Identify Peaks using method described in Jarman2003.
*/
// Should use identifyPeaks in JKChromatogram instead?
//- (void)identifyPeaks;

/*!
    @method     
    @abstract   Reset values for processing data to defaults.
    @discussion The variables used for the processing of the data can be reset to the defaults in Peacock's preferences using this method.
*/
- (void)resetToDefaultValues;
//- (BOOL)searchLibraryForAllPeaks;
- (BOOL)searchLibraryForAllPeaks:(id)sender;
- (void)addChromatogramForMass:(NSString *)inString;
- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak;
- (float)retentionIndexForScan:(int)scan;

/*! 
    @functiongroup Model
*/
#pragma mark MODEL

/*!
    @method     
    @abstract   Returns the TIC chromatogram.
    @discussion This method returns a chromatogram where all ions are totalled together for each scan of the mass spectrometer.
 */
- (JKChromatogram *)ticChromatogram;

/*!
    @method     
    @abstract   Returns the chromatogram for a model.
    @param      model   String containing the masses separated by a "+"- or a "-"-sign, eg. "55+57+63-66".
    @discussion This method returns a chromatogram where the specified ions are totalled together for each scan of the mass spectrometer.
*/
- (JKChromatogram *)chromatogramForModel:(NSString *)model;

/*!
    @method     
     @abstract   Returns the spectrum at index.
     @param      scan   A zero based index of scans.
     @discussion This method returns the specturm at the identified index.
*/
- (JKSpectrum *)spectrumForScan:(int)scan;

/*!
    @functiongroup Accessors
*/
#pragma mark ACCESSORS
- (JKMainWindowController *)mainWindowController;

- (int)ncid;
- (void)setNcid:(int)inValue;

- (BOOL)hasSpectra;
- (void)setHasSpectra:(BOOL)inValue;

- (NSMutableDictionary *)metadata;
- (void)setMetadata:(NSMutableDictionary *)inValue;

- (NSMutableArray *)chromatograms;
- (void)setChromatograms:(NSMutableArray *)inValue;
- (void)insertObject:(JKChromatogram *)chromatogram inChromatogramsAtIndex:(int)index;
- (void)removeObjectFromChromatogramsAtIndex:(int)index;
- (void)startObservingChromatogram:(JKChromatogram *)chromatogram;
- (void)stopObservingChromatogram:(JKChromatogram *)chromatogram;

- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)array;
- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index;
- (void)removeObjectFromPeaksAtIndex:(int)index;
- (void)startObservingPeak:(JKPeakRecord *)peak;
- (void)stopObservingPeak:(JKPeakRecord *)peak;


- (float)retentionIndexForScan:(int)scan;
-(float)timeForScan:(int)scan;
-(int)scanForTime:(float)time;


#pragma mark ACCESSORS (MACROSTYLE)
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


#pragma mark OBSOLETE METHODS?!
//- (ChromatogramGraphDataSerie *)obtainTICChromatogram;
//- (void)obtainBaseline;
//- (ChromatogramGraphDataSerie *)chromatogramForMass:(NSString *)inString;
//
//- (NSMutableArray *)searchLibraryForPeak:(JKPeakRecord *)peak;
//
//    /*!
//    @method     
//     @abstract   Calculates the baseline value at a given scan.
//     @param      scan    Scan for which the baseline value needs to be calculated.
//     @result     Returns the baseline value.
//     */
//- (float)baselineValueAtScan:(int)inValue;
//
//          //- (void)setPeaks:(NSMutableArray *)inValue;
//          //- (NSMutableArray *)peaks;
//- (void)setBaseline:(NSMutableArray *)inValue ;
//- (NSMutableArray *)baseline;
//
////- (SpectrumGraphDataSerie *)spectrumForScan:(int)scan;
//
//
//// Would be better to just return a JKSpectrum or JKChromatogram
//- (float *)massValuesForSpectrumAtScan:(int)scan;
//- (float *)intensityValuesForSpectrumAtScan:(int)scan;
//- (float *)yValuesIonChromatogram:(float)mzValue;
//- (int)startValuesSpectrum:(int)scan;
//- (int)endValuesSpectrum:(int)scan;
//- (int)countOfValuesForSpectrumAtScan:(int)scan;
//- (int)numberOfPoints;
//
//- (int)intensityCount;
//- (void)setIntensityCount:(int)inValue;
//
//- (void)setTime:(float *)inArray withCount:(int)inValue;
//- (float *)time;
//- (float)timeForScan:(int)scan;
//- (int)scanForTime:(float)inTime;
//
//- (void)setTotalIntensity:(float *)inArray withCount:(int)inValue;
//- (float *)totalIntensity;
//
//- (float)maximumTime;
//- (float)minimumTime;
//- (float)maximumTotalIntensity;
//- (float)minimumTotalIntensity;
//
@end
