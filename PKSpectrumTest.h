//
//  PKSpectrumTest.h
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "PKLog.h"
#import "PKSpectrum.h"

@interface PKSpectrumTest : SenTestCase {
    PKSpectrum *testSpectrum1;
    PKSpectrum *testSpectrum2;
    PKSpectrum *testSpectrum3;
    PKSpectrum *testSpectrum4;
    PKSpectrum *testSpectrum5;
}

@property (retain) PKSpectrum *testSpectrum2;
@property (retain) PKSpectrum *testSpectrum4;
@property (retain) PKSpectrum *testSpectrum1;
@property (retain) PKSpectrum *testSpectrum5;
@property (retain) PKSpectrum *testSpectrum3;
@end
