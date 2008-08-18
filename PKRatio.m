//
//  JKRatio.m
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

#import "PKRatio.h"

#import "PKGCMSDocument.h"
#import "PKSummarizer.h"
#import "PKAppDelegate.h"
#import "GCExpressionParser/GCMathParser.h"
#import "PKCombinedPeak.h"

@interface PKRatio (Private)
- (NSString *)expression;
- (void)setExpression:(NSString *)inValue;    
@end

@implementation PKRatio

- (id)init {
	return [self initWithString:@""];
}

- (id)initWithString:(NSString *)string { //Designated initializer
	self = [super init];
	if (self != nil) {
        formula = [string retain];
        name = [@"" retain];
        valueType = [@"normalizedSurface2" retain]; // Normalized by the total surface of confirmed peaks
        
        _parser = [[GCMathParser alloc] init];
        _varKeys = [[NSMutableDictionary alloc] init];
        _expression = [[NSString alloc] init];
        _cachedResults = [[NSMutableDictionary alloc] init];
    }
	return self;
}

- (void) dealloc {
    [formula release];
    [name release];
    [valueType release];
    [_parser release];
    [_varKeys release];
    [_expression release];
    [_cachedResults release];
	[super dealloc];
}

- (void)reset {
    [_cachedResults removeAllObjects];
}
- (void)detectVariables {
    [self reset];
    if (![self formula])
        return;
    NSMutableString *formulaString = [NSMutableString stringWithString:[self formula]];
    if ([formulaString hasSuffix:@"%"]) {
        [formulaString deleteCharactersInRange:NSMakeRange([formulaString length]-1, 1)];
    }
    NSRange range1, range2, compoundRange, compoundRangePlus;
    NSString *compoundName;
    NSString *varName;
    int index, length, varCount;
    
    [_varKeys removeAllObjects];
    varCount = 0;
    index = 0;
    while (index < [formulaString length]) {
        length = [formulaString length];
        range1 = [formulaString rangeOfString:@"[" options:0 range:NSMakeRange(index, length-index)];
        if (range1.location != NSNotFound) {
            range2 = [formulaString rangeOfString:@"]" options:0 range:NSMakeRange(range1.location, length-range1.location)];
            if (range2.location != NSNotFound) {
                varCount++;
                compoundRange = NSMakeRange(range1.location+1, range2.location - range1.location-1);
                compoundRangePlus = NSMakeRange(range1.location, range2.location - range1.location+1); // includes brackets
                compoundName = [formulaString substringWithRange:compoundRange];
                varName = [NSString stringWithFormat:@"v%d", varCount];
                [_varKeys setObject:compoundName forKey:varName];
                [formulaString replaceCharactersInRange:compoundRangePlus withString:varName];
                index = range1.location + [varName length];
            } else {
                index = [formulaString length];
            } 
        } else {
            index = [formulaString length];
        }     
    }
    
    [self setExpression:formulaString];
 }



- (double)calculateRatioForKey:(NSString *)key inCombinedPeaksArray:(NSArray *)combinedPeaks {
    // Set variables
    for (NSString *varKey in [_varKeys allKeys]) {
        NSString *compoundName = [_varKeys objectForKey:varKey];
        // Set to 0 as default value
        @try {
            [_parser evaluate:[NSString stringWithFormat:@"%@=0", varKey]];
        }
        @catch (NSException *e) {
            PKLogDebug(@"Exception: %@ in ratio %@", e, name);
        }
        //[_parser setSymbolValue:0.0 forKey:key]; // This doesn't seem to be working properly, the above alternative does, but is supposed to be slower
        
		// Find concentration in combinedPeaksArray
		for (PKCombinedPeak *combinedPeak in combinedPeaks) {
            if ([combinedPeak isCompound:compoundName]) {
				NSString *keyPath =[NSString stringWithFormat:@"%@.%@", key, valueType];
                if ([combinedPeak valueForKeyPath:key] != nil) {
                    @try {
                        [_parser evaluate:[NSString stringWithFormat:@"%@=%g", varKey,[[combinedPeak valueForKeyPath:keyPath] doubleValue]]]; 
                    }
                    @catch (NSException *e) {
                        PKLogDebug(@"Exception: %@ in ratio %@", e, name);
                    }
                    //[_parser setSymbolValue:[[combinedPeak valueForKeyPath:keyPath] doubleValue] forKey:key];
                    //PKLogDebug(@"symbol %@ [%@] = %g (%g)", compoundName, varKey, [[combinedPeak valueForKeyPath:keyPath] doubleValue], [_parser symbolValueForKey:varKey]);
                }
			} 
		}
	}

    double result = NAN;
    @try {
         result = [_parser evaluate:_expression];
    }
    
    @catch (NSException *e) {
        PKLogDebug(@"Exception: %@ in ratio %@", e, name);
        result = NAN;
    }
    
    @finally {
        return result;
    }
}

- (BOOL)isValidDocumentKey:(NSString *)aKey
{
    NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
    NSDocument *aDocument;
    
    for (aDocument in documents) {
        if ([aDocument isKindOfClass:[PKGCMSDocument class]]) {
            if ([[(PKGCMSDocument *)aDocument uuid] isEqualToString:aKey])
                return YES;
        }
    }
    PKLogDebug(@"Rejected key: %@", aKey);
    return NO;
}

- (id)valueForUndefinedKey:(NSString *)key {
    if ([self isValidDocumentKey:key]) {
        if (![_cachedResults objectForKey:key]) {
            [_cachedResults setObject:[NSNumber numberWithDouble:[self calculateRatioForKey:key inCombinedPeaksArray:[[(PKAppDelegate *)[NSApp delegate] summarizer] combinedPeaks]]] forKey:key];
        } 
        return [_cachedResults objectForKey:key];
    } else {
        return [super valueForUndefinedKey:key];
    }
}


- (void)setFormula:(NSString *)inValue {
	[inValue retain];
	[formula release];
	formula = inValue;
    [self detectVariables];
}

- (NSString *)formula {
	return formula;
}

- (void)setExpression:(NSString *)inValue {
	[inValue retain];
	[_expression release];
	_expression = inValue;
}

- (NSString *)expression {
	return _expression;
}

- (NSString *)name {
	return name;
}

- (void)setName:(NSString *)inValue {
	[inValue retain];
	[name release];
	name = inValue;
}

- (NSString *)valueType {
	return valueType;
}

- (void)setValueType:(NSString *)inValue {
	[inValue retain];
	[valueType release];
	valueType = inValue;
}

#pragma mark Encoding
- (void)encodeWithCoder:(NSCoder *)coder{
    if ([coder allowsKeyedCoding]) { // Assuming 10.2 is quite safe!!
        [coder encodeInt:2 forKey:@"version"];
		[coder encodeObject:name forKey:@"name"];
		[coder encodeObject:formula forKey:@"formula"];
        [coder encodeObject:valueType forKey:@"valueType"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
    if ([coder allowsKeyedCoding]) {
        // Can decode keys in any order
        int version = [coder decodeIntForKey:@"version"];
		name = [[coder decodeObjectForKey:@"name"] retain];
		formula = [[coder decodeObjectForKey:@"formula"] retain];
        if (version > 1) {
            valueType = [[coder decodeObjectForKey:@"valueType"] retain];
        } else {
            valueType = [@"surface" retain];
        }
        
        _parser = [[GCMathParser alloc] init];
        _varKeys = [[NSMutableDictionary alloc] init];
        _expression = [[NSString alloc] init];
        _cachedResults = [[NSMutableDictionary alloc] init];
        [self detectVariables];
    } 
    return self;
}


@end
