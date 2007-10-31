// ===============================================================================
// CAtom.m													 �1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		An atom object holds an atom ID and a multiplicity.
//
// Last Mod:	n/a

#include "CAtom.h"
#include <ctype.h>

@implementation CAtom

//

	// ----------------------------------------------------------------------
	// 		* initFromString								<Parseable      >
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Initialize by reading from a string.
	//
	// Last Mod:	n/a

	- (id) initFromString
		:(char*)parseString
		:(char**)myDataEndsAt
	{
		TElementSym		newSym = 0;
        char*			parse = parseString;
		
		self = [super init];
		
		((char*)(&newSym))[0] = *parse++;
		if (islower(*parse)) {
		  ((char*)(&newSym))[1] = *parse++;
		  if (islower(*parse))
		    ((char*)(&newSym))[2] = *parse++;
		}
		if (isdigit(*parse)) {
		  do {
		    multiplicity = (10 * multiplicity) + (*parse++ - '0');
		  } while (isdigit(*parse));
		}
		if (myDataEndsAt)
		  *myDataEndsAt = parse;
		
		if (LookupSymbol(newSym,NULL) == INVALID_SYMBOL) {
		  [self free];
		  return nil;
		}
		symbol = newSym;
		
		return self;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* writeToDisplay								<Parseable      >
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Write my representation to the screen.
	//
	// Last Mod:	n/a
	
	- (void) writeToDisplay
	{
		[self writeToStream:stdout];
	}
	
//

	// ----------------------------------------------------------------------
	// 		* writeToStream									<Parseable      >
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Write my representation to an arbitrary file stream.
	//
	// Last Mod:	n/a
	
	- (void) writeToStream
		:(FILE*)stream
	{
//		short		i = 0;
		
		fprintf(stream,"%s",(char*)(&symbol));
		if (multiplicity > 0)
		  fprintf(stream,"%hd",multiplicity);
        }

        - (NSString *)writeToString
       {
//            short		i = 0;
            NSString *str = @"";
            //    fprintf(stream,"%s",(char*)(&symbol));
            str = [str stringByAppendingFormat:@"%s", (char*)(&symbol)];
            if (multiplicity > 0)
                //        fprintf(stream,"%hd",multiplicity);
                str = [str stringByAppendingFormat:@"%hd", multiplicity];
     //       JKLogDebug(@"atom %@", str);
            return str; 
        }

        //

	// ----------------------------------------------------------------------
	// 		* calculateWeight								<MolWeight      >
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Calculate my molecular weight.
	//
	// Last Mod:	n/a

	- (float) calculateWeight
	{
		TTableEntry		e;
		
		LookupSymbol(symbol,&e);
		if (multiplicity > 0)
		  return (float)(multiplicity) * e.sWeight;
		else
		  return e.sWeight;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* multiplicity
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Return my current multiplicity.
	//
	// Last Mod:	n/a
	
	- (short) multiplicity
	{
		return multiplicity;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* setMultiplicity
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Return my current multiplicity.
	//
	// Last Mod:	n/a
	
	- (void) setMultiplicity
		:(short)newCount
	{
		if (newCount > 0)
		  multiplicity = newCount;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* symbol
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Return my current element symbol.
	//
	// Last Mod:	n/a
	
	- (TElementSym) symbol
	{
		return symbol;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* setSymbol
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Set my element symbol.
	//
	// Last Mod:	n/a
	
	- (void) setSymbol
		:(TElementSym)newSymbol
	{
		if (LookupSymbol(newSymbol,NULL) != INVALID_SYMBOL)
		  symbol = newSymbol;
	}
	
//

@end
