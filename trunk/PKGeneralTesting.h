//
//  JKGeneralTesting.h
//  Peacock
//
//  Created by Johan Kool on 28-1-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

// -------------------------------------------
//
// TESTS THAT NEED TO BE WRITTEN:
//
// CDF files can be opened
// CDF files can be saved as Peacock files
// Peacock files can be opened
// Peacock files can be saved
// JCAMP-DX files can be opened
// JCAMP-DX files can be saved
// JCAMP-DX files can be saved as Peacock-library files
// HP-JCAMP-DX files can be opened
// HP-JCAMP-DX files can be saved as JCAMP-DX files
// Peacock-library files can be opened
// Peacock-library files can be saved
// Baseline detection can be run
// Peak detection can be run
// Forward search can be run
// Backward search can be run
// 


#import <SenTestingKit/SenTestingKit.h>

#import "AccessorMacros.h"
#import "PKLog.h"

@class PKGCMSDocument;

@interface PKGeneralTesting : SenTestCase {
	PKGCMSDocument *CDFDocument;
	PKGCMSDocument *PeacockDocument;
}

@end
