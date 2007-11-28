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

@protocol PKPluginProtocol

+ (NSDictionary *)defaultSettings;

- (void)setSettings:(NSDictionary *)theSettings;

- (NSArray *)baselineForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;
- (NSArray *)peaksForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;
- (PKSearchResult *)searchResultForPeak:(PKPeak *)aPeak withError:(NSError **)error;

@end

@protocol PKBaselineDetectionPluginProtocol <PKPluginProtocol>

/*!
    @abstract   Name of the baseline detection method inplementated in the plugin.
 */
+ (NSString *)baselineDetectionMethodName;

/*!    
    @abstract   Finds the baseline for a chromatogram.
    @param aChromatogram The chromatogram for which the baseline will be returned.
    @param error Can be used to inform the calling object of encountered errors.
    @discussion The array should consist of NSDictionaries with a NSNumber for the key "intensity" and at least one NSNumber for the key "time" or the key "seconds".
    @result     Returns an array of baseline points for the chromatogram. Returns nil in case of an error.
*/
- (NSArray *)baselineForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;

@end

@protocol PKPeakDetectionPluginProtocol <PKPluginProtocol>

/*!
 @abstract   Name of the peak detection method inplementated in the plugin.
 */
+ (NSString *)peakDetectionMethodName;

/*!    
 @abstract   Finds the peaks in a chromatogram.
 @param aChromatogram The chromatogram for which the peaks will be returned.
 @param error Can be used to inform the calling object of encountered errors.
 @discussion The array should consist of PKPeak objects.
 @result     Returns an array of peaks for the chromatogram. Returns nil in case of an error.
 */
- (NSArray *)peaksForChromatogram:(PKChromatogram *)aChromatogram withError:(NSError **)error;

@end

