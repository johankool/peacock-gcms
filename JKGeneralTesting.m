//
//  JKGeneralTesting.m
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "JKGeneralTesting.h"
#import "JKDataModel.h"
@class JKPeakRecord;

@implementation JKGeneralTesting

-(void)testJKDataModel {
	JKDataModel *object = [[JKDataModel alloc] init];	
	STAssertNotNil(object, @"Could not create instance.");
}

-(void)testJKDataModelNoNCID {
	JKDataModel *object = [[JKDataModel alloc] init];	
//	[object getChromatogramData];
	
}

-(void)testJKPeakRecord {
	JKPeakRecord *object = [[JKPeakRecord alloc] init];	
	STAssertNotNil(object, @"Could not create instance.");
}

-(void)testReadingFile {
//	[NSApp openFile:@"
}

@end
