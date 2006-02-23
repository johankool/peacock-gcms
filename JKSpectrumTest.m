//
//  JKSpectrumTest.m
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKSpectrumTest.h"

#import "JKSpectrum.h"

@implementation JKSpectrumTest

-(void)testCase1 {
	JKSpectrum *spectrum = [[JKSpectrum alloc] init];
	
   STAssertNotNil(spectrum, @"Could not create instance of JKSpectrum.");
}

-(void)testCase2 {
	JKSpectrum *spectrum = [[JKSpectrum alloc] init];
	JKSpectrum *spectrum2 = [[JKSpectrum alloc] init];

	JKSpectrum *spectrum3 = [spectrum spectrumBySubtractingSpectrum:spectrum2];

	STAssertNotNil(spectrum3, @"Could not return subtracted instance of JKSpectrum.");
}

@end
