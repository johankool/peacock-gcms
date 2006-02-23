// ===============================================================================
// CFragment.h												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		A fragment object holds atoms and other fragments.
//
// Last Mod:	n/a

#include <objc/Object.h>
#import "Parseable.h"
#import "MolWeight.h"
#import "CMutableArray.h"

	// ----------------------------------------------------------------------
	// Class:		CFragment
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		A class which manages an array of atoms and fragments.
	//
	// Inherits:	Object
	// Protocols:	MolWeight,Parseable
	// Last Mod:	n/a
	
	@interface CFragment : Object <Parseable,MolWeight>
	{
		CMutableArray*	entities;
		short			multiplicity;
	}
	
	- (short)			multiplicity;
	- (void)			setMultiplicity					:(short)newCount;
-(NSString *) writeToString;
	@end