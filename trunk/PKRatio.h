//
//  JKRatio.h
//  Peacock
//
//  Created by Johan Kool on 19-12-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
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
