//
//  JKRatio.h
//  Peacock
//
//  Created by Johan Kool on 19-12-05.
//  Copyright 2005-2008 Johan Kool.
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

@class GCMathParser;

@interface PKRatio : NSObject <NSCoding> {
	NSString *name;
	NSString *formula;
    NSString *valueType;
    
    GCMathParser *_parser;
    NSMutableDictionary *_varKeys;
    NSString *_expression;
    NSMutableDictionary *_cachedResults;
}

- (id)initWithString:(NSString *)string; //Designated initializer
- (void)reset;
- (double)calculateRatioForKey:(NSString *)key inCombinedPeaksArray:(NSArray *)combinedPeaks;

- (NSString *)formula;
- (void)setFormula:(NSString *)inValue;
- (NSString *)name;
- (void)setName:(NSString *)inValue;
- (NSString *)valueType;
- (void)setValueType:(NSString *)inValue;

@end
