/* ===============================================================================
// MolTypes.c												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		Shared data.
//
// Last Mod:	n/a
//*/

#include "MolTypes.h"
#include <strings.h>
#include <stdlib.h>
#include <ctype.h>

	short				gTableSize			= 0;
	TTableEntry*		gSymbolTable		= NULL;
	short*				gNumberTable		= NULL;

/**/

	/* ----------------------------------------------------------------------
	// 		* SymbolFromString
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Creates a packed element symbol from a string.
	//
	// Last Mod:	n/a
	//*/
	
	TElementSym
	SymbolFromString(
		const char*		string
	)
	{
		TElementSym		newSym = INVALID_SYMBOL;
		const char*			parse = string;
		
		if (isalpha(*parse)) {
		  newSym = 0;
		  ((char*)(&newSym))[0] = *parse++;
		  if ((isalpha(*parse)) && (islower(*parse))) {
		    ((char*)(&newSym))[1] = *parse++;
			if ((isalpha(*parse)) && (islower(*parse)))
			  ((char*)(&newSym))[2] = *parse;
		  }
		}
		return newSym;
	}
	
/**/

	/* ----------------------------------------------------------------------
	// 		* CreateSymbolTable
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Reads in the periodic table from disk.
	//
	// Last Mod:	n/a
	//*/

	int
	CreateSymbolTable(
		const char*		fromFile
	)
	{
		FILE*			stream;
		short			i;
		
		if (fromFile == NULL)
		  return -1; /*  NULL string error */
		
		if ((stream = fopen(fromFile,"r")) == NULL)
		  return -2; /*  Cannot open file error  */
		  
		if (((fscanf(stream,"%hd",&gTableSize)) != 1) || (gTableSize <= 0))
		  return -3; /*  Bad table size error  */
		
		if (gSymbolTable)
		  free(gSymbolTable);
		if ((gSymbolTable = (TTableEntry*)(calloc(gTableSize,sizeof(TTableEntry)))) == NULL)
		  return -4; /*  Memory exception  */
		if ((gNumberTable = (short*)(calloc(gTableSize,sizeof(short)))) == NULL)
		  return -4; /*  Memory exception  */
		
		for ( i = 0 ; i < gTableSize ; i++ ) {
		  /*  Read an entry: */
		  short			tmpNum;
		  TElementSym	tmpSym = 0;
		  float			tmpWt;
		  short			j,k;
//		  TTableEntry	tmpEnt;
		  
		  fscanf(stream,"%hd %3s %f",&tmpNum,(char*)(&tmpSym),&tmpWt);
		  
		  for ( j = 0 ; j < i ; j++ ) {
		    /*  Find where to insert this one:  */
			if (gSymbolTable[j].sSymbol > tmpSym)
			  break;
		  }
		  if (j < i)
		    for ( k = i ; k > j ; k-- )
			  gSymbolTable[k] = gSymbolTable[k - 1];
		  gSymbolTable[j].sSymbol = tmpSym;
		  gSymbolTable[j].sNumber = tmpNum;
		  gSymbolTable[j].sWeight = tmpWt;
		}
		for ( i = 0 ; i < gTableSize ; i++ )
		  gNumberTable[gSymbolTable[i].sNumber - 1] = i;
		fclose(stream);
		return 0;
	}
	
/**/

	/* ----------------------------------------------------------------------
	// 		* LookupNumber
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Get the symbol for a given atomic number.  If weight is
	//				a non-NULL pointer, then the weight is assigned to the
	//				float it points to.
	//
	// Last Mod:	n/a
	//*/

	TElementSym
	LookupNumber(
		short			number,
		TTableEntry*	entry
	)
	{
		if ((number < 1) || (number > gTableSize))
		  return INVALID_SYMBOL;
		if (entry)
		  *entry = gSymbolTable[gNumberTable[number - 1]];
		return gSymbolTable[gNumberTable[number - 1]].sSymbol;
	}

/**/

	/* ----------------------------------------------------------------------
	// 		* LookupSymbol
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Get the atomic number for a given symbol.  If weight is
	//				a non-NULL pointer, then the weight is assigned to the
	//				float it points to.
	//
	// Last Mod:	n/a
	//*/

	short
	LookupSymbol(
		TElementSym		symbol,
		TTableEntry*	entry
	)
	{
		short		top,bottom,lookAt;
		TElementSym	curSym;
		
		top = gTableSize - 1;
		bottom = 0;
		
		do {
		  curSym = gSymbolTable[lookAt = (top + bottom) / 2].sSymbol;
		  if (curSym == symbol) {
		    if (entry)
		      *entry = gSymbolTable[lookAt];
		    return gSymbolTable[lookAt].sNumber;
		  }
		  if (top == bottom)
		    return -1;
		  if (curSym < symbol)
		    /*  lookAt --> bottom  */
			bottom = lookAt + (top + bottom) % 2;
		  else
		    /*  lookAt --> top  */
		    top = lookAt - (top + bottom) % 2;
		} while (top >= bottom);
		return -1;
	}

/**/

	/* ----------------------------------------------------------------------
	// 		* DumpSymbolTable
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Debugging tool; dumps sorted symbol table to a file.
	//
	// Last Mod:	n/a
	//*/
	
	void
	DumpSymbolTable(
		FILE*		stream
	)
	{
		short		i;
		
		for ( i = 0 ; i < gTableSize ; i++ )
		  fprintf(stream,"%3hd:  { %3hd , %3s }\n",i + 1,gSymbolTable[i].sNumber, \
				(char*)(&gSymbolTable[i].sSymbol));
	}
	
/**/
	
