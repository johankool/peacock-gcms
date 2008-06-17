//
//  PKSpectrumTest.m
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006-2008 Johan Kool.
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

#import "PKSpectrumTest.h"

#import "PKGCMSDocument.h"

@implementation PKSpectrumTest

- (void)setUp {
    // Create data structures here.
    testSpectrum1 = [[PKSpectrum alloc] init];
    testSpectrum2 = [[PKSpectrum alloc] init];
    testSpectrum3 = [[PKSpectrum alloc] init];
    testSpectrum4 = [[PKSpectrum alloc] init];
    testSpectrum5 = [[PKSpectrum alloc] init];
    float masses[10];
    float intensities[10];

    masses[0] = 50.0f;
    masses[1] = 60.0f;
    masses[2] = 70.0f;
    masses[3] = 80.0f;
    masses[4] = 90.0f;
    masses[5] = 100.0f;
    masses[6] = 110.0f;
    masses[7] = 120.0f;
    masses[8] = 130.0f;
    masses[9] = 140.0f;
    intensities[0] = 100.0f;
    intensities[1] = 90.0f;
    intensities[2] = 80.0f;
    intensities[3] = 90.0f;
    intensities[4] = 100.0f;
    intensities[5] = 120.0f;
    intensities[6] = 130.0f;
    intensities[7] = 200.0f;
    intensities[8] = 100.0f;
    intensities[9] = 100.0f;
    [testSpectrum1 setMasses:masses withCount:10];
    [testSpectrum1 setIntensities:intensities withCount:10];
    
    masses[0] = 50.0f;
    masses[1] = 60.0f;
    masses[2] = 70.0f;
    masses[3] = 80.0f;
    masses[4] = 90.0f;
    masses[5] = 100.0f;
    masses[6] = 110.0f;
    masses[7] = 120.0f;
    masses[8] = 130.0f;
    masses[9] = 140.0f;
    intensities[0] = 50.0f;
    intensities[1] = 50.0f;
    intensities[2] = 50.0f;
    intensities[3] = 50.0f;
    intensities[4] = 50.0f;
    intensities[5] = 50.0f;
    intensities[6] = 50.0f;
    intensities[7] = 50.0f;
    intensities[8] = 50.0f;
    intensities[9] = 50.0f;
    [testSpectrum2 setMasses:masses withCount:10];
    [testSpectrum2 setIntensities:intensities withCount:10];
    
    masses[0] = 50.0f;
    masses[1] = 60.1f;
    masses[2] = 70.2f;
    masses[3] = 80.3f;
    masses[4] = 90.4f;
    masses[5] = 99.9f;
    masses[6] = 109.8f;
    masses[7] = 119.7f;
    masses[8] = 129.6f;
    masses[9] = 139.5f;
    intensities[0] = 100.0f;
    intensities[1] = 100.0f;
    intensities[2] = 100.0f;
    intensities[3] = 100.0f;
    intensities[4] = 100.0f;
    intensities[5] = 100.0f;
    intensities[6] = 100.0f;
    intensities[7] = 100.0f;
    intensities[8] = 100.0f;
    intensities[9] = 100.0f;
    [testSpectrum3 setMasses:masses withCount:10];
    [testSpectrum3 setIntensities:intensities withCount:10];
    
    masses[0] = 55.0f;
    masses[1] = 65.0f;
    masses[2] = 75.0f;
    masses[3] = 85.0f;
    masses[4] = 95.0f;
    masses[5] = 105.0f;
    masses[6] = 115.0f;
    masses[7] = 125.0f;
    masses[8] = 135.0f;
    masses[9] = 145.0f;
    intensities[0] = 100.0f;
    intensities[1] = 90.0f;
    intensities[2] = 80.0f;
    intensities[3] = 90.0f;
    intensities[4] = 100.0f;
    intensities[5] = 120.0f;
    intensities[6] = 130.0f;
    intensities[7] = 200.0f;
    intensities[8] = 100.0f;
    intensities[9] = 100.0f;
    [testSpectrum4 setMasses:masses withCount:10];
    [testSpectrum4 setIntensities:intensities withCount:10];
    
    masses[0] = 50.0f;
    masses[1] = 60.0f;
    masses[2] = 70.0f;
    masses[3] = 80.0f;
    masses[4] = 90.0f;
    masses[5] = 100.0f;
    masses[6] = 110.0f;
    masses[7] = 121.0f;
    masses[8] = 130.0f;
    masses[9] = 140.0f;
    intensities[0] = 50.0f;
    intensities[1] = 45.0f;
    intensities[2] = 40.0f;
    intensities[3] = 45.0f;
    intensities[4] = 50.0f;
    intensities[5] = 60.0f;
    intensities[6] = 65.0f;
    intensities[7] = 200.0f;
    intensities[8] = 50.0f;
    intensities[9] = 50.0f;
    [testSpectrum5 setMasses:masses withCount:10];
    [testSpectrum5 setIntensities:intensities withCount:10];
}

- (void)tearDown {
    // Release data structures here.
    [testSpectrum1 release];
    [testSpectrum2 release];
    [testSpectrum3 release];
    [testSpectrum4 release];
    [testSpectrum5 release];
}

- (void)testCase1 {
    PKSpectrum *spectrum = [[PKSpectrum alloc] init];
    STAssertNotNil(spectrum, @"Could not create instance of PKSpectrum.");
}

- (void)testCaseSubtracting {
	PKSpectrum *spectrum3 = [testSpectrum1 spectrumBySubtractingSpectrum:testSpectrum2];
    float *masses = [spectrum3 masses];
    float *intensities = [spectrum3 intensities];
    
    STAssertEquals(masses[3], 80.0f, @"Error substracting spectrum");
    STAssertEquals(intensities[3], 40.0f, @"Error substracting spectrum");
	STAssertNotNil(spectrum3, @"Could not return subtracted instance of PKSpectrum.");
}

- (void)testCaseAveraging {
	PKSpectrum *spectrum = [testSpectrum2 spectrumByAveragingWithSpectrum:testSpectrum3];
	STAssertNotNil(spectrum, @"Could not return averaged instance of PKSpectrum.");

    float *masses = [spectrum masses];
    float *intensities = [spectrum intensities];
    STAssertEquals(masses[0], 50.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[0], 75.0f, @"Error averaging spectrum");
    STAssertEquals(masses[3], 80.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[3], 75.0f, @"Error averaging spectrum");
    STAssertEquals(masses[9], 140.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[9], 75.0f, @"Error averaging spectrum");
}

- (void)testCaseAveragingReverse {
	PKSpectrum *spectrum = [testSpectrum3 spectrumByAveragingWithSpectrum:testSpectrum2];
	STAssertNotNil(spectrum, @"Could not return averaged instance of PKSpectrum.");
    
    float *masses = [spectrum masses];
    float *intensities = [spectrum intensities];
    STAssertEquals(masses[0], 50.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[0], 75.0f, @"Error averaging spectrum");
    STAssertEquals(masses[3], 80.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[3], 75.0f, @"Error averaging spectrum");
    STAssertEquals(masses[9], 140.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[9], 75.0f, @"Error averaging spectrum");
}

- (void)testCaseAveragingWithWeight {
	PKSpectrum *spectrum = [testSpectrum1 spectrumByAveragingWithSpectrum:testSpectrum3 withWeight:0.8];
	STAssertNotNil(spectrum, @"Could not return averaged instance of PKSpectrum.");
    
    float *masses = [spectrum masses];
    float *intensities = [spectrum intensities];
    STAssertEquals(masses[0], 50.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[0], 100.0f, @"Error averaging spectrum");
    STAssertEquals(masses[3], 80.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[3], 98.0f, @"Error averaging spectrum");
    STAssertEquals(masses[5], 100.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[5], 104.0f, @"Error averaging spectrum");
}

- (void)testCaseNormalizedSpectrum {
	PKSpectrum *spectrum = [testSpectrum1 normalizedSpectrum];
	STAssertNotNil(spectrum, @"Could not return averaged instance of PKSpectrum.");
    
    float *masses = [spectrum masses];
    float *intensities = [spectrum intensities];
    STAssertEquals(masses[0], 50.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[0], 0.50f, @"Error averaging spectrum");
    STAssertEquals(masses[3], 80.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[3], 90.0f/200.0f, @"Error averaging spectrum");
    STAssertEquals(masses[9], 140.0f, @"Error averaging spectrum");
    STAssertEquals(intensities[9], 0.50f, @"Error averaging spectrum");
}


- (void)testCaseScoringSpectrum {
//	float score = [testSpectrum1 scoreComparedTo:testSpectrum1 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKAbundanceScoreBasis spectrum1");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum1 usingMethod:JKMZValuesScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKMZValuesScoreBasis spectrum1");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum1 usingMethod:JKLiteratureReferenceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKLiteratureReferenceScoreBasis spectrum1");
//    score = [testSpectrum1 scoreComparedTo:testSpectrum4 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 0.0f, @"Error JKAbundanceScoreBasis spectrum1-4");
//    score = [testSpectrum1 scoreComparedTo:testSpectrum5 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
////    STAssertEquals(score, 50.0f, @"Error JKAbundanceScoreBasis spectrum1-5");
//    
//	score = [testSpectrum2 scoreComparedTo:testSpectrum2 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKAbundanceScoreBasis spectrum2");
//	score = [testSpectrum2 scoreComparedTo:testSpectrum2 usingMethod:JKMZValuesScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKMZValuesScoreBasis spectrum2");
//	score = [testSpectrum2 scoreComparedTo:testSpectrum2 usingMethod:JKLiteratureReferenceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKLiteratureReferenceScoreBasis spectrum2");
//    
//	score = [testSpectrum3 scoreComparedTo:testSpectrum3 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKAbundanceScoreBasis spectrum3");
//	score = [testSpectrum3 scoreComparedTo:testSpectrum3 usingMethod:JKMZValuesScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKMZValuesScoreBasis spectrum3");
//	score = [testSpectrum3 scoreComparedTo:testSpectrum3 usingMethod:JKLiteratureReferenceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKLiteratureReferenceScoreBasis spectrum3");
    
//    score = [testSpectrum1 scoreComparedTo:testSpectrum2 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKAbundanceScoreBasis spectrum1-2");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum2 usingMethod:JKMZValuesScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKMZValuesScoreBasis spectrum1-2");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum2 usingMethod:JKLiteratureReferenceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKLiteratureReferenceScoreBasis spectrum1-2");
//    
//    score = [testSpectrum1 scoreComparedTo:testSpectrum3 usingMethod:JKAbundanceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKAbundanceScoreBasis spectrum1-3");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum3 usingMethod:JKMZValuesScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKMZValuesScoreBasis spectrum1-3");
//	score = [testSpectrum1 scoreComparedTo:testSpectrum3 usingMethod:JKLiteratureReferenceScoreBasis penalizingForRententionIndex:NO];
//    STAssertEquals(score, 100.0f, @"Error JKLiteratureReferenceScoreBasis spectrum1-3");
    
}

@synthesize testSpectrum4;
@synthesize testSpectrum2;
@synthesize testSpectrum1;
@synthesize testSpectrum5;
@synthesize testSpectrum3;
@end
