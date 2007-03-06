//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
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

typedef enum {
    JKAbundanceScoreBasis,
    JKMZValuesScoreBasis,
    JKLiteratureReferenceScoreBasis
} JKScoreBases;

typedef enum {
    JKForwardSearchDirection,
    JKBackwardSearchDirection
} JKSearchDirections;

typedef enum {
    JKSpectrumSearchSpectrum,
    JKCombinedSpectrumSearchSpectrum
} JKSearchSpectra;

/*!
    @class
    @abstract    Document containing GCMS data.
    @discussion  (comprehensive description)
*/
@interface JKGCMSDocument : NSDocument {
	// Window controller
    JKMainWindowController *mainWindowController;
	
	// File representation
	int ncid;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
	
    
	// Data stored in Peacock's file because it can't be represented in Andi file format
    NSMutableArray *chromatograms;    
//    NSMutableArray *peaks;
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
    JKSearchDirections searchDirection;
    JKSearchSpectra spectrumToUse;
	BOOL penalizeForRetentionIndex;
	NSNumber *markAsIdentifiedThreshold;
	NSNumber *minimumScoreSearchResults;
	NSNumber *minimumScannedMassRange;
	NSNumber *maximumScannedMassRange;

    int peakIDCounter;
		
	@private
	BOOL abortAction;
    BOOL hasSpectra;
    BOOL _isBusy;
	NSString *_remainingString;
    NSDictionary *_documentProxy;
    NSRect _originalFrame;
}

/*! 
    @functiongroup IMPORT/EXPORT ACTIONS
*/
#pragma mark IMPORT/EXPORT ACTIONS

- (NSString *)exportTabDelimitedText;
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;
- (NSArray *)readJCAMPString:(NSString *)inString;

/*! 
    @functiongroup Actions
*/
#pragma mark ACTIONS

/*!
    @method     
    @abstract   Reset values for processing data to defaults.
    @discussion The variables used for the processing of the data can be reset to the defaults in Peacock's preferences using this method.
*/
- (void)resetToDefaultValues;
- (void)renumberPeaks;
//- (BOOL)searchLibraryForAllPeaks;

- (BOOL)performLibrarySearchForChromatograms:(NSArray *)someChromatograms;
- (BOOL)performBackwardSearchForChromatograms:(NSArray *)someChromatograms;
- (BOOL)performForwardSearchForChromatograms:(NSArray *)someChromatograms;

//- (BOOL)searchLibraryForAllPeaks:(id)sender;
//- (void)addChromatogramForMass:(NSString *)inString;
- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak;
- (float)retentionIndexForScan:(int)scan;
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument;

- (BOOL)isBusy;

int intSort(id num1, id num2, void *context);

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

- (void)addChromatogramForModel:(NSString *)modelString;

- (int)nextPeakID;

#pragma mark ACCESSORS
- (JKMainWindowController *)mainWindowController;

- (int)ncid;
- (void)setNcid:(int)inValue;

- (BOOL)hasSpectra;
- (void)setHasSpectra:(BOOL)inValue;

- (NSMutableDictionary *)metadata;
- (void)setMetadata:(NSMutableDictionary *)inValue;

// Mutable To-Many relationship chromatogram
- (NSMutableArray *)chromatograms;
- (void)setChromatograms:(NSMutableArray *)inValue;
- (int)countOfChromatograms;
- (JKChromatogram *)objectInChromatogramsAtIndex:(int)index;
- (void)getChromatogram:(JKChromatogram **)someChromatograms range:(NSRange)inRange;
- (void)insertObject:(JKChromatogram *)aChromatogram inChromatogramsAtIndex:(int)index;
- (void)removeObjectFromChromatogramsAtIndex:(int)index;
- (void)replaceObjectInChromatogramsAtIndex:(int)index withObject:(JKChromatogram *)aChromatogram;
- (BOOL)validateChromatogram:(JKChromatogram **)aChromatogram error:(NSError **)outError;

//- (void)startObservingChromatogram:(JKChromatogram *)chromatogram;
//- (void)stopObservingChromatogram:(JKChromatogram *)chromatogram;

- (NSMutableArray *)peaks;
//- (void)setPeaks:(NSMutableArray *)array;
//- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index;
//- (void)removeObjectFromPeaksAtIndex:(int)index;
//- (void)startObservingPeak:(JKPeakRecord *)peak;
//- (void)stopObservingPeak:(JKPeakRecord *)peak;


- (float)retentionIndexForScan:(int)scan;
- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)time;


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
intAccessor_h(searchDirection, setSearchDirection)
intAccessor_h(spectrumToUse, setSpectrumToUse)

boolAccessor_h(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor_h(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold)
idAccessor_h(minimumScoreSearchResults, setMinimumScoreSearchResults)
boolAccessor_h(abortAction, setAbortAction)
idAccessor_h(minimumScannedMassRange, setMinimumScannedMassRange)
idAccessor_h(maximumScannedMassRange, setMaximumScannedMassRange)

@end
