// ===============================================================================
// CAtom.h													 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		An atom object holds an atom ID and a multiplicity.
//
// Last Mod:	n/a

#include <objc/Object.h>
#import "Parseable.h"
#import "MolWeight.h"

#import "MolTypes.h"

	// ----------------------------------------------------------------------
	// Class:		CAtom
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		A class which holds an element symbol and an arbitrary
	//				multiplicity.
	//
	// Inherits:	Object
	// Protocols:	MolWeight,Parseable
	// Last Mod:	n/a
	
	@interface CAtom : Object <Parseable,MolWeight>
	{
		TElementSym		symbol;
		short			multiplicity;
	}
	
	- (short)			multiplicity;
	- (void)			setMultiplicity					:(short)newCount;
	
	- (TElementSym)		symbol;
	- (void)			setSymbol						:(TElementSym)newSymbol;
-(NSString *)writeToString;
	@end