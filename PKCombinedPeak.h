//
//  JKCombinedPeak.h
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKPeakRecord;
@class PKLibraryEntry;

@interface PKCombinedPeak : NSObject {
    NSString *label;
    NSString *symbol;
    NSNumber *retentionIndex;
    PKLibraryEntry *libraryEntry;
    NSMutableDictionary *peaks;
}

#pragma mark Calculated Accessors
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
    
#pragma mark Accessors
- (NSString *)label;
- (void)setLabel:(NSString *)label;      
- (NSString *)symbol;
- (void)setSymbol:(NSString *)label;      

- (NSNumber *)retentionIndex;
- (NSString *)group;

- (PKLibraryEntry *)libraryEntry;
- (void)setLibraryEntry:(PKLibraryEntry *)libraryEntry;


- (NSMutableDictionary *)peaks;
- (void)setPeaks:(NSMutableDictionary *)inValue;
- (int)countOfPeaks;

@end
