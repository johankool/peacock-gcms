//
//  JKChromatogramTest.h
//  Peacock
//
//  Created by Johan Kool on 7-2-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "JKLog.h"
#import "PKChromatogram.h"

@interface JKChromatogramTest : SenTestCase {
    PKChromatogram *testChromatogram;
}

@property (retain) PKChromatogram *testChromatogram;
@end
