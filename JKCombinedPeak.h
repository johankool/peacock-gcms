//
//  JKCombinedPeak.h
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKSpectrum;
@class JKPeakRecord;
@class JKStatisticsDocument;
@class JKLibraryEntry;

@interface JKCombinedPeak : NSObject <NSCoding> {
    NSString *label;
    NSNumber *symbol;
    NSNumber *retentionIndex;
    NSString *model;
    JKSpectrum *spectrum;
    JKLibraryEntry *libraryEntry;
    NSMutableDictionary *peaks;
    BOOL unknownCompound;
    JKStatisticsDocument *document;
}

#pragma mark CALCULATED ACCESSORS
- (NSNumber *)certainty;
- (NSNumber *)averageRetentionIndex;
- (NSNumber *)averageSurface;
- (NSNumber *)averageHeight;
- (NSNumber *)standardDeviationRetentionIndex;
- (NSNumber *)standardDeviationSurface;
- (NSNumber *)standardDeviatioHeight;
                
#pragma mark SPECIAL ACCESSORS
- (id)valueForUndefinedKey:(NSString *)key;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
    
#pragma mark ACCESSORS
- (JKStatisticsDocument *)document;
- (void)setDocument:(JKStatisticsDocument *)document;
- (NSString *)label;
- (void)setLabel:(NSString *)label;      
- (NSNumber *)symbol;
- (void)setSymbol:(NSNumber *)symbol;
- (NSNumber *)retentionIndex;
- (void)setRetentionIndex:(NSNumber *)retentionIndex;
- (NSString *)model;
- (void)setModel:(NSString *)model;
- (JKSpectrum *)spectrum;
- (void)setSpectrum:(JKSpectrum *)spectrum;
- (JKLibraryEntry *)libraryEntry;
- (void)setLibraryEntry:(JKLibraryEntry *)libraryEntry;
- (BOOL)unknownCompound;
- (void)setUnknownCompound:(BOOL)unknownCompound;

- (NSMutableDictionary *)peaks;
- (void)setPeaks:(NSMutableDictionary *)inValue;
- (int)countOfPeaks;

@end
