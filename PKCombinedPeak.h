//
//  JKCombinedPeak.h
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKSpectrum;
@class PKPeakRecord;
@class PKLibraryEntry;

@interface PKCombinedPeak : NSObject {
    NSString *label;
    NSString *symbol;
//    int index;
    NSNumber *retentionIndex;
    NSString *model;
    NSString *group;
    PKSpectrum *spectrum;
    PKLibraryEntry *libraryEntry;
    NSMutableDictionary *peaks;
    BOOL unknownCompound;
}

#pragma mark CALCULATED ACCESSORS
- (NSNumber *)certainty;
- (NSNumber *)averageRetentionIndex;
- (NSNumber *)averageSurface;
- (NSNumber *)averageHeight;
- (NSNumber *)standardDeviationRetentionIndex;
- (NSNumber *)standardDeviationSurface;
- (NSNumber *)standardDeviationHeight;
                
- (BOOL)isValidDocumentKey:(NSString *)aKey;
- (void)addConfirmedPeak:(PKPeakRecord *)aPeak;
- (void)removeUnconfirmedPeak:(PKPeakRecord *)aPeak;

- (BOOL)isCombinedPeakForPeak:(PKPeakRecord *)aPeak;
- (BOOL)isCompound:(NSString *)aString;

#pragma mark SPECIAL ACCESSORS
- (id)valueForUndefinedKey:(NSString *)key;
- (void)setValue:(id)value forUndefinedKey:(NSString *)key;
    
#pragma mark ACCESSORS
- (NSString *)label;
- (void)setLabel:(NSString *)label;      
- (NSString *)symbol;
- (void)setSymbol:(NSString *)symbol;
//- (NSNumber *)retentionIndex;
- (NSString *)group;
- (void)setGroup:(NSString *)group;
//- (void)setRetentionIndex:(NSNumber *)retentionIndex;
//- (NSString *)model;
//- (void)setModel:(NSString *)model;
//- (JKSpectrum *)spectrum;
//- (void)setSpectrum:(JKSpectrum *)spectrum;
- (PKLibraryEntry *)libraryEntry;
- (void)setLibraryEntry:(PKLibraryEntry *)libraryEntry;
- (BOOL)unknownCompound;
- (void)setUnknownCompound:(BOOL)unknownCompound;
- (NSString *)group;
- (void)setGroup:(NSString *)aGroup;

- (NSMutableDictionary *)peaks;
- (void)setPeaks:(NSMutableDictionary *)inValue;
- (int)countOfPeaks;

@property (getter=unknownCompound,setter=setUnknownCompound:) BOOL unknownCompound;
@property (getter=index,setter=setIndex:) int index;
@end
