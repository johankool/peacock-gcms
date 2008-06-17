//
//  PKAbundanceTest.m
//  Peacock
//
//  Created by Johan Kool on 29-01-08.
//  Copyright 2008 Johan Kool.
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
