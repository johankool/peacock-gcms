//
//  JKCombinedPeak.h
//  Peacock
//
//  Created by Johan Kool on 6-3-07.
//  Copyright 2007-2008 Johan Kool.
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

//- (NSNumber *)retentionIndex;
- (NSString *)group;

- (PKLibraryEntry *)libraryEntry;
- (void)setLibraryEntry:(PKLibraryEntry *)libraryEntry;


- (NSMutableDictionary *)peaks;
- (void)setPeaks:(NSMutableDictionary *)inValue;
- (int)countOfPeaks;

@end
