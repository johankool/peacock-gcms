//
//  PKChromatogramTest.h
//  Peacock
//
//  Created by Johan Kool on 7-2-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "PKLog.h"
#import "PKChromatogram.h"

@interface PKChromatogramTest : SenTestCase {
    PKChromatogram *testChromatogram;
}

@property (retain) PKChromatogram *testChromatogram;
@end
