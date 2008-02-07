//
//  JKSpectrumTest.h
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "JKLog.h"
#import "JKSpectrum.h"

@interface JKSpectrumTest : SenTestCase {
    JKSpectrum *testSpectrum1;
    JKSpectrum *testSpectrum2;
    JKSpectrum *testSpectrum3;
    JKSpectrum *testSpectrum4;
    JKSpectrum *testSpectrum5;
}

@property (retain) JKSpectrum *testSpectrum5;
@property (retain) JKSpectrum *testSpectrum1;
@property (retain) JKSpectrum *testSpectrum3;
@property (retain) JKSpectrum *testSpectrum2;
@property (retain) JKSpectrum *testSpectrum4;
@end