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
@class JKGCMSPrintView;
@class JKSpectrum;
@class SpectrumGraphDataSerie;
@class JKLibraryEntry;

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
    NSString *libraryConfiguration;
    NSString *searchTemplate;
	int scoreBasis;
    JKSearchDirections searchDirection;
    JKSearchSpectra spectrumToUse;
	BOOL penalizeForRetentionIndex;
	NSNumber *markAsIdentifiedThreshold;
	NSNumber *minimumScoreSearchResults;
	NSNumber *minimumScannedMassRange;
	NSNumber *maximumScannedMassRange;
    NSNumber *maximumRetentionIndexDifference;
    
    JKGCMSPrintView *printView;
        
	@private
	BOOL abortAction;
    BOOL hasSpectra;
    BOOL _isBusy;
	NSString *_remainingString;
    NSDictionary *_documentProxy;
    NSRect _originalFrame;
    int _lastReturnedIndex;
}

/*! 
    @functiongroup IMPORT/EXPORT ACTIONS
*/
#pragma mark Import/Export Actions

- (NSString *)exportTabDelimitedText;
- (BOOL)readNetCDFFile:(NSString *)fileName error:(NSError **)anError;
- (NSArray *)readJCAMPString:(NSString *)inString;

/*! 
    @functiongroup Actions
*/
#pragma mark Actions

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
- (BOOL)performBackwardSearchForChromatograms:(NSArray *)someChromatograms withLibraryEntries:(NSArray *)libraryEntries maximumRetentionIndexDifference:(float)aMaximumRetentionIndexDifference;
- (BOOL)performForwardSearchForChromatograms:(NSArray *)someChromatograms;
- (BOOL)performForwardSearchLibraryForPeak:(JKPeakRecord *)aPeak;

//- (BOOL)searchLibraryForAllPeaks:(id)sender;
//- (void)addChromatogramForMass:(NSString *)inString;
- (void)redistributedSearchResults:(JKPeakRecord *)originatingPeak;
- (float)retentionIndexForScan:(int)scan;
- (NSComparisonResult)metadataCompare:(JKGCMSDocument *)otherDocument;

- (BOOL)isBusy;
- (NSString *)cleanupModelString:(NSString *)model;
- (BOOL)modelString:(NSString *)stringA isEqualToString:(NSString *)stringB;
int intSort(id num1, id num2, void *context);

- (void)updateLibraryHits;

/*! 
    @functiongroup Model
*/
#pragma mark Model

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

- (BOOL)addChromatogramForModel:(NSString *)modelString;

- (int)nextPeakID;

#pragma mark Doublures management
- (BOOL)hasPeakConfirmedAs:(JKLibraryEntry *)libraryHit notBeing:(JKPeakRecord *)originatingPeak;
- (BOOL)hasPeakAtTopScan:(int)topScan notBeing:(JKPeakRecord *)originatingPeak;
- (void)unconfirmPeaksConfirmedAs:(JKLibraryEntry *)libraryHit notBeing:(JKPeakRecord *)originatingPeak;
- (void)removePeaksAtTopScan:(int)topScan notBeing:(JKPeakRecord *)originatingPeak;
#pragma mark -


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
- (void)setPeaks:(NSMutableArray *)array;
//- (void)insertObject:(JKPeakRecord *)peak inPeaksAtIndex:(int)index;
//- (void)removeObjectFromPeaksAtIndex:(int)index;
//- (void)startObservingPeak:(JKPeakRecord *)peak;
//- (void)stopObservingPeak:(JKPeakRecord *)peak;


- (float)retentionIndexForScan:(int)scan;
- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)time;

- (void)setAbsolutePathToNetCDF:(NSString *)aAbsolutePathToNetCDF;
- (NSString *)absolutePathToNetCDF;

#pragma mark ACCESSORS (MACROSTYLE)
idAccessor_h(baselineWindowWidth, setBaselineWindowWidth)
idAccessor_h(baselineDistanceThreshold, setBaselineDistanceThreshold)
idAccessor_h(baselineSlopeThreshold, setBaselineSlopeThreshold)
idAccessor_h(baselineDensityThreshold, setBaselineDensityThreshold)
idAccessor_h(peakIdentificationThreshold, setPeakIdentificationThreshold)
idAccessor_h(retentionIndexSlope, setRetentionIndexSlope)
idAccessor_h(retentionIndexRemainder, setRetentionIndexRemainder)
idAccessor_h(libraryAlias, setLibraryAlias)
idAccessor_h(libraryConfiguration, setLibraryConfiguration)
idAccessor_h(searchTemplate, setSearchTemplate)

intAccessor_h(scoreBasis, setScoreBasis)
intAccessor_h(searchDirection, setSearchDirection)
intAccessor_h(spectrumToUse, setSpectrumToUse)

boolAccessor_h(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor_h(markAsIdentifiedThreshold, setMarkAsIdentifiedThreshold)
idAccessor_h(minimumScoreSearchResults, setMinimumScoreSearchResults)
boolAccessor_h(abortAction, setAbortAction)
idAccessor_h(minimumScannedMassRange, setMinimumScannedMassRange)
idAccessor_h(maximumScannedMassRange, setMaximumScannedMassRange)
idAccessor_h(maximumRetentionIndexDifference, setMaximumRetentionIndexDifference)

@end
