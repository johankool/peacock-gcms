//
//  JKGeneralTesting.m
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

#import "PKGeneralTesting.h"
#import "PKGCMSDocument.h"
#import "PKRatio.h"
#import "PKPeakRecord.h"
#import "PKChromatogram.h"

@implementation PKGeneralTesting

- (void) setUp
{
    // Create data structures here.
    NSError *error = nil;
	BOOL result;
	
	// Open CDF document
	CDFDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01.CDF"] display:YES error:&error];
	STAssertNotNil(CDFDocument, @"Could not open CDF test-file.");
	// Save CDF to Peacock document
	result = [CDFDocument saveToURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01-out.peacock"] ofType:@"Peacock File" forSaveOperation:NSSaveToOperation error:&error];
	STAssertTrue(result, @"CDF test-file was not saved as Peacock file.");
    
	// Open Peacock document
	PeacockDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02.peacock"] display:YES error:&error];
	STAssertNotNil(PeacockDocument, @"Could not open Peacock test-file.");
	// Save Peacock to Peacock document
	result = [PeacockDocument saveToURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02-out.peacock"] ofType:@"Peacock File" forSaveOperation:NSSaveToOperation error:&error];
	STAssertTrue(result, @"Peacock test-file was not saved as Peacock file.");
    
    [error release];
}

- (void) tearDown
{
    // Release data structures here.
 	// Close CDF Document
	[CDFDocument close];

    // Close Peacock Document
	[PeacockDocument close];
	
	// Clean up 
	[[NSFileManager defaultManager] removeFileAtPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01-out.peacock" handler:nil];
	[[NSFileManager defaultManager] removeFileAtPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02-out.peacock" handler:nil];

}

- (void)testPKPeakRecord {
	PKPeakRecord *object = [[PKPeakRecord alloc] init];	
	STAssertNotNil(object, @"Could not create instance.");
}

- (void)testAccessingChromatograms {
    PKChromatogram *tic = [PeacockDocument ticChromatogram];
    STAssertNotNil(tic, @"Could not get TIC");
    PKChromatogram *chrom100 = [PeacockDocument chromatogramForModel:@"100"];
    STAssertNotNil(chrom100, @"Could not get m/z 100 chromatogram");
    PKChromatogram *chrom100min = [PeacockDocument chromatogramForModel:@"100-101"];
    STAssertNotNil(chrom100min, @"Could not get m/z 100-101 chromatogram");
    PKChromatogram *chrom100plus = [PeacockDocument chromatogramForModel:@"100+101"];
    STAssertNotNil(chrom100plus, @"Could not get m/z 100+101 chromatogram");
    STAssertTrue([PeacockDocument addChromatogramForModel:@"100-101"], @"Could not add 100-101 chrom");
    STAssertFalse([PeacockDocument addChromatogramForModel:@"100+101"], @"Could add 100+101 chrom");
    chrom100plus = [PeacockDocument chromatogramForModel:@"100+101"];
    chrom100min = [PeacockDocument chromatogramForModel:@"100-101"];
    STAssertEqualObjects(chrom100min, chrom100plus, @"m/z 100-101 chromatogram should be equal to m/z 100+101 chromatogram");
}

- (void)testDetectingBaseline {
    [PeacockDocument addChromatogramForModel:@"100"];
    PKChromatogram *chrom100 = [PeacockDocument chromatogramForModel:@"100"];
    STAssertNotNil(chrom100, @"Could not get m/z 100 chromatogram");
    NSError *error = nil;
    BOOL result = [chrom100 detectBaselineAndReturnError:&error];
    [error release];
    STAssertTrue(result, @"Could not detect baseline");
    STAssertTrue([chrom100 countOfBaselinePoints] > 0, @"No baseline points found");
}

- (void)testDetectingPeaks {
    [PeacockDocument addChromatogramForModel:@"100"];
    PKChromatogram *chrom100 = [PeacockDocument chromatogramForModel:@"100"];
    STAssertNotNil(chrom100, @"Could not get m/z 100 chromatogram");
    NSError *error = nil;
    BOOL result = [chrom100 detectPeaksAndReturnError:&error];
    [error release];
    STAssertTrue(result, @"Could not detect baseline");
    STAssertTrue([chrom100 peaks] > 0, @"No baseline points found");
}



@end
