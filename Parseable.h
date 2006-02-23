// ===============================================================================
// Parseable.h												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		Protocol definition for an object which can initialize itself by
//				parsing a textual string.
//
// Last Mod:	n/a

#include <objc/Object.h>

#include <stdio.h>

@protocol Parseable

	- (id)			initFromString			:(const char*)parseString
											:(char**)myDataEndsAt;
	- (void)		writeToDisplay;
	- (void)		writeToStream			:(FILE*)stream;
	
@end