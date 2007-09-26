// ===============================================================================
// CMutableArray.h											 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 08/14/2000
// Purpose:		Implementation of the CMutableArray class.
//
// Last Mod:	n/a

#import <objc/Object.h>
	
	// ----------------------------------------------------------------------
	// Class:		CMutableArray
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Defines an array of ObjC objects -- all entries in the
	//				array are of type 'id'.  The array is dynamic in that it
	//				allows resizing of itself at runtime (hence the mutable
	//				part).
	//
	// Inherits:	Object
	// Protocols:	n/a
	// Last Mod:	n/a

	#define		CMutableArray_initialCapacity		10
	#define		CMutableArray_deltaCapacity		 	4
	
	@interface CMutableArray : Object
	{
		unsigned	capacity;
		unsigned	used;
		id*			objects;
	}
	
	//  Allocation/Initialization/Destruction
	+				arrayOfStandardSize;
	+				arrayWithCapacity				:(unsigned)numItems;
	
	-				initStandardSize;
	-				initWithCapacity				:(unsigned)numItems;
	
	-				free;
	
	//  Object storage/retrieval:
	-				objectAtIndex					:(unsigned)index;
	- (unsigned)	indexForObject					:(id)anObject;
	- (void)		addObject						:(id)anObject;
	- (void)		insertObject					:(id)anObject
													:(unsigned)atIndex;
	- (void)		removeObject					:(id)anObject;
	- (void)		removeLastObject;
	- (void)		removeObjectAtIndex				:(unsigned)index;
	- (void)		removeAllObjects;
	- (void)		removeObjectsInRange			:(unsigned)from
													:(unsigned)to;
	
	//  Array size accessors:
	- (unsigned)	capacity;
	- (unsigned)	inUse;
	- (BOOL)		increaseCapacityBy				:(unsigned)dCapacity;
	
	@end
