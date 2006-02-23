// ===============================================================================
// CFragment.m												 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 03/11/2001
// Purpose:		A fragment object holds atoms and other fragments.
//
// Last Mod:	n/a

#include "CFragment.h"
#include "CAtom.h"
#include <ctype.h>

@implementation CFragment

//

	// ----------------------------------------------------------------------
	// 		* initFromString								<Parseable      >
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 03/11/2001
	// Purpose:		Initialize by reading from a string.
	//
	// Last Mod:	n/a

	- (id) initFromString
		:(const char*)parseString
		:(char**)myDataEndsAt
	{
		char*			parse = parseString;
		id				tmpObj;
		
		self = [super init];
		
		entities = [CMutableArray arrayOfStandardSize];
		while ((*parse != '\0') && (*parse != ')')) {
		  if ((!isalnum(*parse)) && (*parse != '(')) {
		    parse++;
		  } else if (*parse == '(') {
		    /*  We're gonna do a new fragment!  */
			if ((tmpObj = [[CFragment alloc] initFromString:++parse:&parse]))
			  [entities addObject:tmpObj];
		  } else {
		    /*  Just an atom.  */
			if ((tmpObj = [[CAtom alloc] initFromString:parse:&parse]))
			  [entities addObject:tmpObj];
		  }
		}
		if (isdigit(*(++parse))) {
		  do {
		    multiplicity = (10 * multiplicity) + (*parse++ - '0');
		  } while (isdigit(*parse));
		}
		if (myDataEndsAt)
		  *myDataEndsAt = parse;
		
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
		unsigned	counter = 0;
		unsigned	maxCount = [entities inUse];
		id			curObj;
		
		if (multiplicity > 0)
		  fprintf(stream,"(");
		while (counter < maxCount)
		  if ([(curObj = [entities objectAtIndex:counter++]) isKindOf:[CFragment class]]) {
			[curObj writeToStream:stream];
		  } else
		    [curObj writeToStream:stream];
		if (multiplicity > 0) 
		  fprintf(stream,")%hd",multiplicity);
	}
-(NSString *) writeToString
{
    unsigned	counter = 0;
    unsigned	maxCount = [entities inUse];
    id			curObj;
    NSString *str = @"";
    
    if (multiplicity > 0)
        str = [str stringByAppendingString:@"("];
    while (counter < maxCount)
        if ([(curObj = [entities objectAtIndex:counter++]) isKindOf:[CFragment class]]) {
 //           [curObj writeToStream:stream];
            str = [str stringByAppendingString:[curObj writeToString]];
  
        } else
            str = [str stringByAppendingString:[curObj writeToString]];
    if (multiplicity > 0) 
//        fprintf(stream,")%hd",multiplicity);
       str = [str stringByAppendingFormat:@")%hd",multiplicity];
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
		float		wt = 0.0;
		unsigned	counter = 0;
		unsigned	maxCount = [entities inUse];
		
		while (counter < maxCount)
		  wt += [[entities objectAtIndex:counter++] calculateWeight];		
		if (multiplicity > 0)
		  wt *= (float)(multiplicity);
		return wt;
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

@end