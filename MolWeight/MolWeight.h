// ===============================================================================
// MolWeight.h												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		Protocol definition for an object which can calculate its own
//				molecular weight.
//
// Last Mod:	n/a

#include <objc/Object.h>

@protocol MolWeight

	- (float)			calculateWeight;
	
@end
