//
//  PKAbundanceTest.m
//  Peacock
//
//  Created by Johan Kool on 29-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import "PKAbundanceTest.h"

#import "PKAbundanceSpectraMatchingMethod.h"
#import "PKSpectrum.h"
#import "PKManagedLibraryEntry.h"

@implementation PKAbundanceTest

- (void)testInit {
    PKAbundanceSpectraMatchingMethod *matchObject = [[PKAbundanceSpectraMatchingMethod alloc] init];
    STAssertNotNil(matchObject, @"Could not init PKAbundanceSpectraMatchingMethod.");
}

- (void)testCalculations {
    PKAbundanceSpectraMatchingMethod *matchObject = [[PKAbundanceSpectraMatchingMethod alloc] init];
    STAssertNotNil(matchObject, @"Could not init PKAbundanceSpectraMatchingMethod.");
    NSError *error = nil;
    PKSpectrum *spectrum = [[PKSpectrum alloc] init];
    PKManagedLibraryEntry *libraryEntry = [[PKManagedLibraryEntry alloc] init];
    CGFloat result = [matchObject matchingScoreForSpectrum:spectrum comparedToLibraryEntry:libraryEntry error:&error];
    STAssertEquals(result, 100.0f, @"Unexpected result");
    [spectrum release];
    [libraryEntry release];
}
    
@end
