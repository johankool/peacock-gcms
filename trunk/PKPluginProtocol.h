/*
 *  PKPluginProtocol.h
 *  Peacock
 *
 *  Created by Johan Kool on 28-11-07.
 *  Copyright 2007 Johan Kool. All rights reserved.
 *
 */

@class PKChromatogram;
@class PKSpectrum;
@class PKPeak;
@class PKSearchResult;
@class PKLibraryEntry;

@protocol PKPluginProtocol

/*!
 @abstract   Returns an array of NSStrings for baseline detection methods implemented through the plugin.
 */
+ (NSArray *)baselineDetectionMethodNames;

/*!
 @abstract   Returns an array of NSStrings for peak detection methods implemented through the plugin.
 */
+ (NSArray *)peakDetectionMethodNames;

/*!
 @abstract   Returns an array of NSStrings for forward search methods implemented through the plugin.
 */
+ (NSArray *)forwardSearchMethodNames;

/*!
 @abstract   Returns an array of NSStrings for backward search methods implemented through the plugin.
 */
+ (NSArray *)backwardSearchMethodNames;

/*!    
 @abstract   Returns an object that implements the method.
 @param methodName The name of the method. This should be one of the strings returned by one of the +(NSArray *)...MethodNames; methods.
 @discussion Used to find the object that implements the method with the name methodName. The returned object should conform to the related protocol.
 @result     Returns an object that implements the method. Returns nil in case of an error.
 */
- (id)sharedObjectForMethod:(NSString *)methodName;

@end
#pragma mark -

@protocol PKMethodProtocol

/*!
 @abstract   Name of the method implementated in the class.
 */
+ (NSString *)methodName;


/*!    
 @abstract   Returns an object that implements the method.
 @param methodName The name of the method. This should be one of the strings returned by one of the +(NSArray *)...MethodNames; methods.
 @discussion Used to find the object that implements the method with the name methodName.
 @result     Returns an object that implements the method. Returns nil in case it doesn't require a settings view.
 */
- (NSView *)settingsView;

/*!
 @abstract  Used to store settings for using the method in defaults and documents. It may only contain plist-compatible values.
 */
+ (NSDictionary *)defaultSettings;

/*!
 @abstract  Used to store settings for using the method in defaults and documents. It may only contain plist-compatible values.
 */
- (NSDictionary *)settings;

/*!
 @abstract  Used to store settings for using the method in defaults and documents. It may only contain plist-compatible values.
 */
- (void)setSettings:(NSDictionary *)theSettings;

@end
#pragma mark -

@protocol PKBaselineDetectionMethodProtocol <PKMethodProtocol>

/*!    
    @abstract   Finds the baseline for a chromatogram.
    @param aChromatogram The chromatogram for which the baseline will be returned.
    @param error Can be used to inform the calling object of encountered errors.
    @discussion The array should consist of NSDictionaries with a NSNumber for the key "intensity" and at least one NSNumber for the key "time" or the key "seconds".
    @result     Returns an array of baseline points for the chromatogram. Returns nil in case of an error.
*/
- (NSArray *)baselineForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;

- (void)prepareForAction;
- (void)cleanUpAfterAction;

@end
#pragma mark -

@protocol PKPeakDetectionMethodProtocol <PKMethodProtocol>

/*!    
 @abstract   Finds the peaks in a chromatogram.
 @param aChromatogram The chromatogram for which the peaks will be returned.
 @param error Can be used to inform the calling object of encountered errors.
 @discussion The array should consist of PKPeak objects.
 @result     Returns an array of peaks for the chromatogram. Returns nil in case of an error.
 */
- (NSArray *)peaksForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;

- (void)prepareForAction;
- (void)cleanUpAfterAction;

@end
#pragma mark -

@protocol PKForwardSearchMethodProtocol <PKMethodProtocol>

/*!    
 @abstract   Finds the peaks in a chromatogram.
 @param aChromatogram The chromatogram for which the peaks will be returned.
 @param error Can be used to inform the calling object of encountered errors.
 @discussion The array should consist of PKPeak objects.
 @result     Returns an array of peaks for the chromatogram. Returns nil in case of an error.
 */
- (PKSearchResult *)searchResultForPeak:(PKPeak *)aPeak withError:(NSError **)error;

- (void)prepareForAction;
- (void)cleanUpAfterAction;

@end
#pragma mark -

@protocol PKBackwardSearchMethodProtocol <PKMethodProtocol>

/*!    
 @abstract   Finds the peaks in a chromatogram.
 @param aChromatogram The chromatogram for which the peaks will be returned.
 @param error Can be used to inform the calling object of encountered errors.
 @discussion The array should consist of PKPeak objects.
 @result     Returns an array of peaks for the chromatogram. Returns nil in case of an error.
 */
- (PKPeak *)peakForLibraryEntry:(PKLibraryEntry *)aLibraryEntry withError:(NSError **)error;

- (void)prepareForAction;
- (void)cleanUpAfterAction;

@end

@interface PKChromatogram (Public)

- (id)document;
- (NSString *)model;

- (int)scanCount;

/*! Returns array of floats for the time. */
- (float *)times;

/*! Returns array of floats for the intensity. */
- (float *)intensities;

/*! Convenience methods. */
- (float)timeForScan:(int)scan;
- (int)scanForTime:(float)inTime;

- (float)baselineValueAtScan:(int)inValue;

- (float)maxTime;
- (float)minTime;
- (float)maxTotalIntensity;
- (float)minTotalIntensity;

@end

@interface PKPeak (Public)

- (NSString *)uuid;
- (void)setPeakID:(int)inValue;
- (int)peakID;

- (void)setStart:(int)inValue;
- (int)start;
- (void)setEnd:(int)inValue;
- (int)end;
- (void)setBaselineLeft:(NSNumber *)inValue;
- (NSNumber *)baselineLeft;
- (void)setBaselineRight:(NSNumber *)inValue;
- (NSNumber *)baselineRight;

- (void)setLabel:(NSString *)inValue;
- (NSString *)label;
- (void)setSymbol:(NSString *)inValue;
- (NSString *)symbol;
- (void)setIdentified:(BOOL)inValue;
- (BOOL)identified;
- (void)setConfirmed:(BOOL)inValue;
- (BOOL)confirmed;
- (void)setFlagged:(BOOL)inValue;
- (BOOL)flagged;

- (BOOL)isCompound:(NSString *)compoundString;

- (NSNumber *)deltaRetentionIndex;
- (NSNumber *)startTime;
- (NSNumber *)endTime;
- (int)top;
- (NSNumber *)topTime;
- (NSNumber *)retentionIndex;
- (NSNumber *)startRetentionIndex;
- (NSNumber *)endRetentionIndex;
- (NSNumber *)height;
- (NSNumber *)normalizedHeight;
- (NSNumber *)surface;
- (NSNumber *)normalizedSurface;
- (NSNumber *)width;
- (PKSpectrum *)spectrum;
- (PKSpectrum *)combinedSpectrum;
- (NSNumber *)score;
- (NSString *)library;
- (PKLibraryEntry *)libraryHit;
- (id)document;
- (NSString *)model;

@end