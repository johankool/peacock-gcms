//
//  NSString+ModelCompare.m
//  Peacock
//
//  Created by Johan Kool on 25-09-07.
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

#import "NSString+ModelCompare.h"
#import "PKGCMSDocument.h"

#import "pk_statistics.h"

@implementation NSString (ModelCompare)

-(BOOL)isEqualToModelString:(NSString *)aModelString {
    NSString *stringACleaned = [self cleanupModelString];
    NSString *stringBCleaned = [aModelString cleanupModelString];
    return [stringACleaned isEqualToString:stringBCleaned];
}

- (NSString *)cleanupModelString {
    int i,j,k,start,end,mzValuesCount,mzValuesCountPlus;
    if ([self isEqualToString:@""]) {
        return @"";
    }
    if ([self isEqualToString:@"TIC"]) {
        return @"TIC";
    }
    
    NSString *trimmedString = [self stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"0123456789-+"] invertedSet]];
    if ([self isEqualToString:@""]) {
        return @"";
    }
    
    // Find out how many values are covered
	NSArray *mzValuesPlus = [trimmedString componentsSeparatedByString:@"+"];
    NSArray *mzValuesMin = nil;
    mzValuesCount = [mzValuesPlus count];
    mzValuesCountPlus = mzValuesCount;
	for (i = 0; i < mzValuesCountPlus; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
            start = [[mzValuesMin objectAtIndex:0] intValue];
            end = [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue];
            mzValuesCount += abs(end-start);
		} 
	}
    // Return empty string if zero (e.g. when string was "-+-+")
    if (mzValuesCount < 1) {
        return @"";
    } 
    
    // Collect the values
    int mzValues[mzValuesCount];
    k = 0;
    for (i = 0; i < mzValuesCountPlus; i++) {
		mzValuesMin = [[mzValuesPlus objectAtIndex:i] componentsSeparatedByString:@"-"];
		if ([mzValuesMin count] > 1) {
            start = [[mzValuesMin objectAtIndex:0] intValue];
            end = [[mzValuesMin objectAtIndex:([mzValuesMin count]-1)] intValue];
			if (start < end) {
				for (j = start; j <= end; j++) {
                    mzValues[k] = j;     
                    k++;
				}
			} else {
				for (j = end; j <= start; j++) {
                    mzValues[k] = j;     
                    k++;
				}
			}
		} else {
            mzValues[k] = [[mzValuesMin objectAtIndex:0] intValue];
            k++;
		}
	}
    
	// Sort mzValues
    insertionSort(mzValues, mzValuesCount);
    
    // Combine into a string with collapsing
	NSString *mzValuesString = [NSString stringWithFormat:@"%d", mzValues[0]];
    if (mzValuesCount > 1) {
        for (i = 1; i < mzValuesCount-1; i++) {
            if ((mzValues[i] == mzValues[i-1]+1) && (mzValues[i+1] > mzValues[i]+1)) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d", mzValues[i]];            
            } else if (mzValues[i] != mzValues[i-1]+1) {
                mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d", mzValues[i]];            
            }
        }	
        if ((mzValues[i] == mzValues[i-1]+1)) {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"-%d", mzValues[i]];            
        } else {
            mzValuesString = [mzValuesString stringByAppendingFormat:@"+%d", mzValues[i]];            
        }        
    }
    
    return mzValuesString;
}


@end
