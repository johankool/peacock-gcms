//
//  PKChromatogramTest.m
//  Peacock
//
//  Created by Johan Kool on 7-2-07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "PKChromatogramTest.h"

#import "PKPeakRecord.h"

@implementation PKChromatogramTest
- (void)setUp {
    // Create data structures here.
    testChromatogram = [[PKChromatogram alloc] init];

    float times[10];
    float intensities[10];
    
    times[0] = 0.0f;
    times[1] = 1.0f;
    times[2] = 2.0f;
    times[3] = 3.0f;
    times[4] = 4.0f;
    times[5] = 5.0f;
    times[6] = 6.0f;
    times[7] = 7.0f;
    times[8] = 8.0f;
    times[9] = 9.0f;
    intensities[0] = 10.0f;
    intensities[1] = 9.0f;
    intensities[2] = 11.0f;
    intensities[3] = 10.0f;
    intensities[4] = 100.0f;
    intensities[5] = 200.0f;
    intensities[6] = 100.0f;
    intensities[7] = 10.0f;
    intensities[8] = 21.0f;
    intensities[9] = 19.0f;
    [testChromatogram setTime:times withCount:10];
    [testChromatogram setTotalIntensity:intensities withCount:10];
}

- (void)tearDown {
    // Release data structures here.
    [testChromatogram release];
}

- (void)testCaseNil {
    STAssertNotNil(testChromatogram, @"Could not create instance for testChromatogram.");
}

- (void)testCaseMinMax {
    STAssertEquals([testChromatogram minTime], 0.0f, @"Min time incorrect");
    STAssertEquals([testChromatogram maxTime], 9.0f, @"Max time incorrect");
    STAssertEquals([testChromatogram minTotalIntensity], 9.0f, @"Min intensity incorrect");
    STAssertEquals([testChromatogram maxTotalIntensity], 200.0f, @"Max intensity incorrect");
}

- (void)testCaseTimeForScan {
    STAssertEquals([testChromatogram timeForScan:0], 0.0f, @"Time for scan 0");
    STAssertEquals([testChromatogram timeForScan:2], 2.0f, @"Time for scan 2");
    STAssertEquals([testChromatogram timeForScan:5], 5.0f, @"Time for scan 5");
    STAssertEquals([testChromatogram timeForScan:6], 6.0f, @"Time for scan 6");
    STAssertEquals([testChromatogram timeForScan:9], 9.0f, @"Time for scan 9");
}

- (void)testCaseScanForTime {
    STAssertEquals([testChromatogram scanForTime:-90.0f], 0, @"Time for scan 0");
    STAssertEquals([testChromatogram scanForTime:0.0f], 0, @"Time for scan 0");
    STAssertEquals([testChromatogram scanForTime:1.5f], 2, @"Time for scan 2");
    STAssertEquals([testChromatogram scanForTime:5.0f], 5, @"Time for scan 5");
    STAssertEquals([testChromatogram scanForTime:6.3f], 6, @"Time for scan 6");
    STAssertEquals([testChromatogram scanForTime:8.8f], 9, @"Time for scan 9");
    STAssertEquals([testChromatogram scanForTime:998.8f], 9, @"Time for scan 9");
}

- (void)testCaseBaseline {
    [testChromatogram detectBaselineAndReturnError:nil];
    int count= 2; // is expected value?
    STAssertEquals([testChromatogram countOfBaselinePoints], count, @"Number of baseline points");
}

- (void)testCaseAddPeak {
    [testChromatogram detectBaselineAndReturnError:nil];
    PKPeakRecord *peak = [testChromatogram peakFromScan:3 toScan:7];
    [testChromatogram insertObject:peak inPeaksAtIndex:0];
    unsigned int count= 1; // is expected value?
    STAssertEquals([[testChromatogram peaks] count], count, @"Number of baseline points");
    peak = [[testChromatogram peaks] objectAtIndex:0];
    STAssertEquals([peak start], 3, @"Peak start");
    STAssertEquals([peak end], 7, @"Peak end");
    STAssertEquals([peak top], 5, @"Peak top");
    STAssertEquals([[peak baselineLeft] floatValue], 10.0f, @"Peak baselineLeft");
    STAssertEquals([[peak baselineRight] floatValue], 10.0f, @"Peak baselineRight");
    STAssertEquals([[peak surface] floatValue], 370.0f, @"Peak surface");
    STAssertEquals([[peak height] floatValue], 190.0f, @"Peak height");
    STAssertEquals([[peak normalizedSurface] floatValue], 1.0f, @"Peak normalizedSurface");
    STAssertEquals([[peak normalizedHeight] floatValue], 1.0f, @"Peak normalizedHeight");

}

@synthesize testChromatogram;
@end
