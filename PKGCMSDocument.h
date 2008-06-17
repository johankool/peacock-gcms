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

@class PKChromatogramDataSeries;
@class PKChromatogram;
@class JKLibrarySearch;
@class PKMainWindowController;
@class PKPeakRecord;
@class PKGCMSPrintView;
@class PKSpectrum;
@class PKSpectrumDataSeries;
@class PKLibraryEntry;

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
    PKSpectrumSearchSpectrum,
    JKCombinedSpectrumSearchSpectrum
} JKSearchSpectra;

/*!
    @class
    @abstract    Document containing GCMS data.
    @discussion  (comprehensive description)
*/
@interface PKGCMSDocument : NSDocument {
	// Window controller
    PKMainWindowController *mainWindowController;
	
	// File representation
	int ncid;
    NSString *uuid;
	NSString *absolutePathToNetCDF;
	NSFileWrapper *peacockFileWrapper;
    
	// Data stored in Peacock's file because it can't be represented in Andi file format
    NSMutableArray *chromatograms;    
	NSMutableDictionary *metadata;
	
    // PlugIn
    NSString *baselineDetectionMethod;
    NSMutableDictionary *baselineDetectionSettings;
    NSString *peakDetectionMethod;
    NSMutableDictionary *peakDetectionSettings;
    NSString *spectraMatchingMethod;
    NSMutableDictionary *spectraMatchingSettings;
    
    // >> MOVE TO PLUGIN
	// Baseline 
	NSNumber *baselineWindowWidth;
	NSNumber *baselineDistanceThreshold;
	NSNumber *baselineSlopeThreshold;
	NSNumber *baselineDensityThreshold;
	// Peak identification
	NSNumber *peakIdentificationThreshold;
    // Search options
    int scoreBasis;

    // << END MOVE TO PLUGIN

	// RetentionIndex = retentionSlope * retentionTime +  retentionRemainder
	NSNumber *retentionIndexSlope;     
	NSNumber *retentionIndexRemainder;
    
	// Search options
    NSString *libraryConfiguration;
    NSString *searchTemplate;
    JKSearchDirections searchDirection;
    JKSearchSpectra spectrumToUse;
	BOOL penalizeForRetentionIndex;
	NSNumber *markAsIdentifiedThreshold;
	NSNumber *minimumScoreSearchResults;
	NSNumber *minimumScannedMassRange;
	NSNumber *maximumScannedMassRange;
    NSNumber *maximumRetentionIndexDifference;
    
    PKGCMSPrintView *printView;
        
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
- (id)objectForSpectraMatching:(NSError **)error;
- (BOOL)performLibrarySearchForChromatograms:(NSArray *)someChromatograms error:(NSError **)error;
- (BOOL)performBackwardSearchAndReturnError:(NSError **)error;
- (BOOL)performBackwardSearchWithLibraryEntries:(NSArray *)libraryEntries maximumRetentionIndexDifference:(float)aMaximumRetentionIndexDifference  error:(NSError **)error;
- (BOOL)performForwardSearchForChromatograms:(NSArray *)someChromatograms error:(NSError **)error;
- (BOOL)performForwardSearchLibraryForPeak:(PKPeakRecord *)aPeak error:(NSError **)error;

//- (void)addChromatogramForMass:(NSString *)inString;
- (void)redistributedSearchResults:(PKPeakRecord *)originatingPeak;
- (float)retentionIndexForScan:(int)scan;
- (NSComparisonResult)metadataCompare:(PKGCMSDocument *)otherDocument;

- (BOOL)isBusy;

//- (void)updateLibraryHits;


#pragma mark PlugIn Support
- (NSString *)baselineDetectionMethod;
- (void)setBaselineDetectionMethod:(NSString *)methodName;
- (BOOL)validateBaselineDetectionMethod:(id *)ioValue error:(NSError **)outError;
- (void)setBaselineDetectionSettings:(NSDictionary *)settings forMethod:(NSString *)methodName;
- (NSDictionary *)baselineDetectionSettingsForMethod:(NSString *)methodName;

- (NSString *)peakDetectionMethod;
- (void)setPeakDetectionMethod:(NSString *)methodName;
- (BOOL)validatePeakDetectionMethod:(id *)ioValue error:(NSError **)outError;
- (void)setPeakDetectionSettings:(NSDictionary *)settings forMethod:(NSString *)methodName;
- (NSDictionary *)peakDetectionSettingsForMethod:(NSString *)methodName;

- (NSString *)spectraMatchingMethod;
- (void)setSpectraMatchingMethod:(NSString *)methodName;
- (BOOL)validateSpectraMatchingMethod:(id *)ioValue error:(NSError **)outError;
- (void)setSpectraMatchingSettings:(NSDictionary *)settings forMethod:(NSString *)methodName;
- (NSDictionary *)spectraMatchingSettingsForMethod:(NSString *)methodName;

#pragma mark -

/*! 
    @functiongroup Model
*/
#pragma mark Model

/*!
    @method     
    @abstract   Returns the TIC chromatogram.
    @discussion This method returns a chromatogram where all ions are totalled together for each scan of the mass spectrometer.
 */
- (PKChromatogram *)ticChromatogram;

/*!
    @method     
    @abstract   Returns the chromatogram for a model.
    @param      model   String containing the masses separated by a "+"- or a "-"-sign, eg. "55+57+63-66".
    @discussion This method returns a chromatogram where the specified ions are totalled together for each scan of the mass spectrometer.
*/
- (PKChromatogram *)chromatogramForModel:(NSString *)model;

/*!
    @method     
     @abstract   Returns the spectrum at index.
     @param      scan   A zero based index of scans.
     @discussion This method returns the specturm at the identified index.
*/
- (PKSpectrum *)spectrumForScan:(int)scan;

/*!
    @functiongroup Accessors
*/

- (BOOL)addChromatogramForModel:(NSString *)modelString;

- (int)nextPeakID;
- (float)confirmedPeaksSurface;

#pragma mark Doublures management
- (BOOL)hasPeakConfirmedAs:(PKLibraryEntry *)libraryHit notBeing:(PKPeakRecord *)originatingPeak;
- (BOOL)hasPeakAtTopScan:(int)topScan notBeing:(PKPeakRecord *)originatingPeak;
- (void)unconfirmPeaksConfirmedAs:(PKLibraryEntry *)libraryHit notBeing:(PKPeakRecord *)originatingPeak;
- (void)removePeaksAtTopScan:(int)topScan notBeing:(PKPeakRecord *)originatingPeak;
#pragma mark -

- (NSString *)sampleCode;
- (NSString *)sampleDescription;

#pragma mark ACCESSORS
- (PKMainWindowController *)mainWindowController;

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
- (PKChromatogram *)objectInChromatogramsAtIndex:(int)index;
- (void)getChromatogram:(PKChromatogram **)someChromatograms range:(NSRange)inRange;
- (void)insertObject:(PKChromatogram *)aChromatogram inChromatogramsAtIndex:(int)index;
- (void)removeObjectFromChromatogramsAtIndex:(int)index;
- (void)replaceObjectInChromatogramsAtIndex:(int)index withObject:(PKChromatogram *)aChromatogram;
- (BOOL)validateChromatogram:(PKChromatogram **)aChromatogram error:(NSError **)outError;

//- (void)startObservingChromatogram:(PKChromatogram *)chromatogram;
//- (void)stopObservingChromatogram:(PKChromatogram *)chromatogram;

- (NSMutableArray *)peaks;
- (void)setPeaks:(NSMutableArray *)array;
//- (void)insertObject:(PKPeakRecord *)peak inPeaksAtIndex:(int)index;
//- (void)removeObjectFromPeaksAtIndex:(int)index;
//- (void)startObservingPeak:(PKPeakRecord *)peak;
//- (void)stopObservingPeak:(PKPeakRecord *)peak;


- (float)retentionIndexForScan:(int)scan;
- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)time;

- (void)setAbsolutePathToNetCDF:(NSString *)aAbsolutePathToNetCDF;
- (NSString *)absolutePathToNetCDF;

- (NSString *)uuid;

#pragma mark ACCESSORS (MACROSTYLE)
idAccessor_h(baselineWindowWidth, setBaselineWindowWidth)
idAccessor_h(baselineDistanceThreshold, setBaselineDistanceThreshold)
idAccessor_h(baselineSlopeThreshold, setBaselineSlopeThreshold)
idAccessor_h(baselineDensityThreshold, setBaselineDensityThreshold)
idAccessor_h(peakIdentificationThreshold, setPeakIdentificationThreshold)
idAccessor_h(retentionIndexSlope, setRetentionIndexSlope)
idAccessor_h(retentionIndexRemainder, setRetentionIndexRemainder)
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

@property (retain) NSDictionary *_documentProxy;
@property (getter=abortAction,setter=setAbortAction:) BOOL abortAction;
@property (getter=hasSpectra,setter=setHasSpectra:) BOOL hasSpectra;
@property int _lastReturnedIndex;
@property (retain,getter=uuid) NSString *uuid;
@property (getter=isBusy) BOOL _isBusy;
@property (getter=ncid,setter=setNcid:) int ncid;
@property (retain) PKGCMSPrintView *printView;
@property (retain) NSFileWrapper *peacockFileWrapper;
@property (retain) NSString *_remainingString;

@end
