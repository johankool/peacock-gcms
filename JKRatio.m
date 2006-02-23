//
//  JKRatio.m
//  Peacock
//
//  Created by Johan Kool on 19-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JKRatio.h"


@implementation JKRatio

-(id)init {
	return [self initWithString:@""];
}

-(id)initWithString:(NSString *)string { //Designated initializer
	self = [super init];
	if (self != nil) {
		formula = string;
		name = @"";
			}
	return self;
}
- (void) dealloc {
	[super dealloc];
}

-(float)calculateRatioForKey:(NSString *)key inCombinedPeaksArray:(NSArray *)combinedPeaks {	
	int i,j;
	float nominator = 0.0;
	float denominator = 0.0;
	float multiplier = 1.0;
	float concentration = 0.0;
	BOOL knownCombinedPeak = NO;
	int knownCombinedPeakIndex = 0;
	NSString *nominatorComponent;
	NSString *denominatorComponent;
	NSString *combinedPeakName;
	NSString *keyPath;
	int combinedPeaksCount = [combinedPeaks count];
	
	for (i = 0; i < [[self nominatorArray] count]; i++) {
		concentration = 0.0;
		knownCombinedPeak = NO;
		multiplier = [[[[self nominatorArray] objectAtIndex:i] valueForKey:@"multiplier"] floatValue];
		nominatorComponent = [[[[self nominatorArray] objectAtIndex:i] valueForKey:@"component"] lowercaseString];
		
		// Find concentration in combinedPeaksArray
		for (j = 0; j < combinedPeaksCount; j++) {
			combinedPeakName = [[[combinedPeaks objectAtIndex:j] valueForKey:@"label"] lowercaseString];
			
			if ([nominatorComponent isEqualToString:combinedPeakName]) {
				knownCombinedPeak = YES;
				knownCombinedPeakIndex = j;
			} 
		}
		if (knownCombinedPeak) {
			keyPath =[NSString stringWithFormat:@"%@.normalizedSurface", key];
			if ([[combinedPeaks objectAtIndex:knownCombinedPeakIndex] valueForKeyPath:key] != nil) {
				concentration = [[[combinedPeaks objectAtIndex:knownCombinedPeakIndex] valueForKeyPath:keyPath] floatValue];
				nominator = nominator + (multiplier * concentration);
			}
		}
	}
	
	for (i = 0; i < [[self denominatorArray] count]; i++) {
		concentration = 0.0;
		knownCombinedPeak = NO;
		multiplier = [[[[self denominatorArray] objectAtIndex:i] valueForKey:@"multiplier"] floatValue];
		denominatorComponent = [[[self denominatorArray] objectAtIndex:i] valueForKey:@"component"];
		
		// Find concentration in combinedPeaksArray
		for (j = 0; j < combinedPeaksCount; j++) {
			combinedPeakName = [[combinedPeaks objectAtIndex:j] valueForKey:@"label"];
			
			if ([denominatorComponent isEqualToString:combinedPeakName]) {
				knownCombinedPeak = YES;
				knownCombinedPeakIndex = j;
			} 
		}
		if (knownCombinedPeak) {
			keyPath =[NSString stringWithFormat:@"%@.normalizedSurface", key];
			if ([[combinedPeaks objectAtIndex:knownCombinedPeakIndex] valueForKeyPath:key] != nil) {
				concentration = [[[combinedPeaks objectAtIndex:knownCombinedPeakIndex] valueForKeyPath:keyPath] floatValue];
				denominator = denominator + (multiplier * concentration);
			}
		}
	}
	return nominator/denominator;
}

-(NSString *)getNominator {
	if ([formula length] == 0){
		JKLogDebug(@"Oops! %@", name);		
	}
	NSRange dividerRange;
	dividerRange = [formula rangeOfString:@") / ("];
	if(dividerRange.location+2 > [formula length]) {
		JKLogDebug(@"Yikes! %@", formula);
	}
	return [[formula substringToIndex:dividerRange.location+2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"() "]];
}

-(NSString *)getDenominator {
	if ([formula length] == 0){
		JKLogDebug(@"Oops! %@", name);		
	}
	
	NSRange dividerRange;
	dividerRange = [formula rangeOfString:@") / ("];
	if(dividerRange.location+2+1 > [formula length]) {
		JKLogDebug(@"Yikes! %@", formula);
	}
	return [[formula substringFromIndex:dividerRange.location+1+2] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"() *100%"]];
}

-(NSArray *)compoundsInString:(NSString *)string {
	NSArray *array1;// = [[NSArray alloc] init];
	NSMutableArray *array2= [[NSMutableArray alloc] init];
	array1 = [string componentsSeparatedByString:@"+"];
	NSString *string2;
	NSRange multiplierRange;

	int i;
	for (i = 0; i < [array1 count]; i++) {
		NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
		string2 = [array1 objectAtIndex:i];
		multiplierRange = [string2 rangeOfString:@"*"];
		if (multiplierRange.location == NSNotFound) {
			[mutDict setValue:@"1.0" forKey:@"multiplier"];
			multiplierRange.location = -1;
		} else {
			[mutDict setValue:[[string2 substringToIndex:multiplierRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]] forKey:@"multiplier"];
		}
		
		string2 = [[string2 substringFromIndex:multiplierRange.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" []"]];
		[mutDict setValue:string2 forKey:@"component"];
		[array2 addObject:mutDict];
		[mutDict release];
	}
	
//	[array1 release];
	[array2 autorelease];
	return array2;
}

-(void)setFormula:(NSString *)inValue {
	if (inValue != formula) {
		NSRange dividerRange;
		dividerRange = [inValue rangeOfString:@"/"];
		if(dividerRange.location == NSNotFound) {
			inValue = [inValue stringByAppendingString:@" / ( 1 ) * 100%"];
			dividerRange = [inValue rangeOfString:@"/"];
		}
		
		NSArray *nominatorArrayLocal = [self compoundsInString:[[inValue substringToIndex:dividerRange.location] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" () "]]];
		NSArray *denominatorArrayLocal = [self compoundsInString:[[inValue substringFromIndex:dividerRange.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" () *100%"]]];
		
		NSString *outString = @"( ";
		int i;
		if ([nominatorArrayLocal count] == 0) {
			outString = [outString stringByAppendingString:@"1"];
		} else {			
			for (i = 0; i < [nominatorArrayLocal count]; i++) {
				if ([[[nominatorArrayLocal objectAtIndex:i] valueForKey:@"multiplier"] floatValue] == 1.0) {
					outString = [outString stringByAppendingFormat:@"[%@]", [[nominatorArrayLocal objectAtIndex:i] valueForKey:@"component"]];
				} else {
					outString = [outString stringByAppendingFormat:@"%.1f * [%@]", [[[nominatorArrayLocal objectAtIndex:i] valueForKey:@"multiplier"] floatValue], [[nominatorArrayLocal objectAtIndex:i] valueForKey:@"component"]];
				}
				if (i < [nominatorArrayLocal count]-1)
					outString = [outString stringByAppendingString:@" + "];
			}
		}
		outString = [outString stringByAppendingString:@" ) / ( "];
		if ([denominatorArrayLocal count] == 0) {
			outString = [outString stringByAppendingString:@"1"];
		} else {
			for (i = 0; i < [denominatorArrayLocal count]; i++) {
				if ([[[denominatorArrayLocal objectAtIndex:i] valueForKey:@"multiplier"] floatValue] == 1.0) {
					outString = [outString stringByAppendingFormat:@"[%@]", [[denominatorArrayLocal objectAtIndex:i] valueForKey:@"component"]];
				} else {
					outString = [outString stringByAppendingFormat:@"%.1f * [%@]", [[[denominatorArrayLocal objectAtIndex:i] valueForKey:@"multiplier"] floatValue], [[denominatorArrayLocal objectAtIndex:i] valueForKey:@"component"]];
				}
				if (i < [denominatorArrayLocal count]-1)
					outString = [outString stringByAppendingString:@" + "];
			}			
		}

		outString = [outString stringByAppendingString:@" ) * 100%"];
		[formula release];
		[outString retain];
		formula = outString;
		[self didChangeValueForKey:@"formula"];
	}
		

}
-(NSString *)formula {
	return formula;
}

-(NSArray *)nominatorArray {
	return [self compoundsInString:[self getNominator]];
}

-(NSArray *)denominatorArray {
	return [self compoundsInString:[self getDenominator]];
}

#pragma mark Encoding

-(void)encodeWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) { // Assuming 10.2 is quite safe!!
        [coder encodeInt:1 forKey:@"version"];
		[coder encodeObject:name forKey:@"name"];
		[coder encodeObject:formula forKey:@"formula"];
    } 
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
    if ( [coder allowsKeyedCoding] ) {
        // Can decode keys in any order
		name = [[coder decodeObjectForKey:@"name"] retain];
		formula = [[coder decodeObjectForKey:@"formula"] retain];
    } 
    return self;
}

idAccessor(name, setName);
//idAccessor(formula, setFormula);
@end