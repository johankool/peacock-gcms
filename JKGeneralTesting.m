//
//  JKGeneralTesting.m
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKGeneralTesting.h"
#import "JKDataModel.h"
#import "JKGCMSDocument.h"
#import "JKRatio.h"

@class JKPeakRecord;

@implementation JKGeneralTesting

- (void)testJKDataModel {
	JKDataModel *object = [[JKDataModel alloc] init];	
	STAssertNotNil(object, @"Could not create instance.");
}

- (void)testJKDataModelNoNCID {
	JKDataModel *object = [[JKDataModel alloc] init];	
//	[object getChromatogramData];
	
}

- (void)testJKPeakRecord {
	JKPeakRecord *object = [[JKPeakRecord alloc] init];	
	STAssertNotNil(object, @"Could not create instance.");
}

- (void)testReadingAndSavingFiles {
	JKGCMSDocument *CDFDocument;
	JKGCMSDocument *PeacockDocument;
	NSError *error = [[NSError alloc] init];
	BOOL result;
	
	// Open CDF document
	CDFDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01.CDF"] display:YES error:&error];
	STAssertNotNil(CDFDocument, @"Could not open CDF test-file.");
	// Save CDF to Peacock document
	result = [CDFDocument saveToURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01-out.peacock"] ofType:@"Peacock File" forSaveOperation:NSSaveToOperation error:&error];
	STAssertTrue(result, @"CDF test-file was not saved as Peacock file.");
	// Close CDF Document
	[CDFDocument close];

	// Open Peacock document
	PeacockDocument = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02.peacock"] display:YES error:&error];
	STAssertNotNil(PeacockDocument, @"Could not open Peacock test-file.");
	// Save Peacock to Peacock document
	result = [PeacockDocument saveToURL:[NSURL fileURLWithPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02-out.peacock"] ofType:@"Peacock File" forSaveOperation:NSSaveToOperation error:&error];
	STAssertTrue(result, @"Peacock test-file was not saved as Peacock file.");
	// Close Peacock Document
	[PeacockDocument close];
	
	// Clean up 
	[[NSFileManager defaultManager] removeFileAtPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-01-out.peacock" handler:nil];
	[[NSFileManager defaultManager] removeFileAtPath:@"/Users/jkool/Developer/Peacock-related/Test-data/Test-file-02-out.peacock" handler:nil];
	[error release];
}

//-(void)testJKRatio {
//	JKRatio *ratio = [[JKRatio alloc] initWithString:@"(2*[compound A]+0.5*[compound B])/(5*[compound C]) *  100%%"];
////	STFail([ratio formula]);
////	if (![[ratio formula] isEqualToString:@"( 2.0 * [compound A] + 0.5 * [compound B] ) / ( 5.0 * [compound C] ) *  100"]){
////		STFail([ratio formula]);
////		STFail(@"Formula returned in unexpected format.");
////	}
//	-(float)calculateRatioForKey:(NSString *)key inCombinedPeaksArray:(NSArray *)combinedPeaks;
//
//	
//}

@end
