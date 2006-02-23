/* ===============================================================================
// MolTypes.h												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		Data types shared throughout the program.
//
// Last Mod:	n/a
//*/

#ifndef __MOLTYPES__
#define __MOLTYPES__

	#include <stdio.h>

	/*
	 * An unsigned long is 32-bits long (typically) so
	 * we'll use it to store the element symbol:
	 */
	typedef			unsigned long			TElementSym;
	#define			INVALID_SYMBOL			(TElementSym)(-1)

	/*  Periodic table data entry:  */
	typedef struct TTableEntry {
		TElementSym		sSymbol;
		short			sNumber;
		float			sWeight;
	} TTableEntry;
	
	TElementSym		SymbolFromString		(const char*		string);
	int				CreateSymbolTable		(const char*		fromFile);
	TElementSym		LookupNumber			(short				number,
											 TTableEntry*		entry);
	short			LookupSymbol			(TElementSym		symbol,
											 TTableEntry*		entry);
	void			DumpSymbolTable			(FILE*				stream);

#endif