//
//  NSString+ModelCompare.m
//  Peacock
//
//  Created by Johan Kool on 25-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "NSString+ModelCompare.h"
#import "JKGCMSDocument.h"

#import "jk_statistics.h"

@implementation NSString (ModelCompare)

-(BOOL)isEqualToModelString:(NSString *)aModelString {
    NSString *stringACleaned = [self cleanupModelString:self];
    NSString *stringBCleaned = [self cleanupModelString:aModelString];
    return [stringACleaned isEqualToString:stringBCleaned];
}

- (NSString *)cleanupModelString:(NSString *)model {
    int i,j,mzValuesCount;
    if ([model isEqualToString:@""]) {
        return @"";
    }
    if ([model isEqualToString:@"TIC"]) {
        return @"TIC";
    }
    
    NSMutableArray *mzValues = [NSMutableArray array];
    [model stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
    if ([model isEqualToString:@""]) {
        return @"";
    }
	NSArray *mzValuesPlus = [model componentsSeparatedByString:@"+"];
	NSArray *mzValuesMin = nil;
	for (i = 0; i < [mzValuesPlus count]; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
			if ([[mzValuesMin objectAtIndex:0] intValue] < [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]) {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j++) {
                    [mzValues addObject:[NSNumber numberWithInt:j]];                        
				}
			} else {
				for (j = (unsigned)[[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue]; j <= (unsigned)[[mzValuesMin objectAtIndex:0] intValue]; j++) {
                        [mzValues addObject:[NSNumber numberWithInt:j]];
                    
				}
			}
		} else {
            j = [[mzValuesMin objectAtIndex:0] intValue];
  
                [mzValues addObject:[NSNumber numberWithInt:j]];
            
		}
	}
    if ([mzValues count] < 1) {
        return nil;
    } 
	// Short mzValues
    mzValues = [[mzValues sortedArrayUsingFunction:intSort context:NULL] mutableCopy];
    
	NSString *mzValuesString = [NSString stringWithFormat:@"%d",[[mzValues objectAtIndex:0] intValue]];
	mzValuesCount = [mzValues count];
    float mzValuesF[mzValuesCount];
	for (i = 0; i < mzValuesCount; i++) {
        mzValuesF[i] = [[mzValues objectAtIndex:i] floatValue];
    }
    if (mzValuesCount > 1) {
        for (i = 1; i < mzValuesCount-1; i++) {
            if ((mzValuesF[i] == mzValuesF[i-1]+1.0f) && (mzValuesF[i+1] > mzValuesF[i]+1.0f)) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d",[[mzValues objectAtIndex:i] intValue]];            
            } else if (mzValuesF[i] != mzValuesF[i-1]+1.0f) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];            
            }
        }	
        if ((mzValuesF[i] == mzValuesF[i-1] + 1.0f)) {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d",[[mzValues objectAtIndex:i] intValue]];            
        } else {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d",[[mzValues objectAtIndex:i] intValue]];            
        }        
    }
    //    JKLogDebug(@"%@ %@",mzValuesString,[mzValues description]);
    return mzValuesString;
}


@end
