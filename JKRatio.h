//
//  JKRatio.h
//  Peacock
//
//  Created by Johan Kool on 19-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKRatio : NSObject <NSCoding> {
	NSString *name;
	NSString *formula;

	NSArray *nominatorArray;
	NSArray *denominatorArray;
}

-(id)initWithString:(NSString *)string; //Designated initializer

-(float)calculateRatioForKey:(NSString *)key inCombinedPeaksArray:(NSArray *)combinedPeaks;

-(NSString *)getNominator;
-(NSString *)getDenominator;
-(NSArray *)compoundsInString:(NSString *)string;
-(NSArray *)nominatorArray;
-(NSArray *)denominatorArray;

idAccessor_h(name, setName);

@end