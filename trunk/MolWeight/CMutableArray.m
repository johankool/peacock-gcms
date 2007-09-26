// ===============================================================================
// CMutableArray.m											 ©1999-2000, J.T. Frey
// ===============================================================================
// Written:		J.T. Frey, 08/14/2000
// Purpose:		Implementation of the CMutableArray class.
//
// Last Mod:	n/a

#include "CMutableArray.h"

@implementation CMutableArray

	// ----------------------------------------------------------------------
	// 		* arrayOfStandardSize
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Create a new array with standard capacity.
	//
	// Last Mod:	n/a
	
	+ arrayOfStandardSize
	{
		return [[CMutableArray alloc] initStandardSize];
	}
	
//

	// ----------------------------------------------------------------------
	// 		* arrayWithCapacity
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Create a new array with a specific capacity.
	//
	// Last Mod:	n/a

	+ arrayWithCapacity
		:(unsigned)numItems
	{
		return [[CMutableArray alloc] initWithCapacity:numItems];
	}

//

	// ----------------------------------------------------------------------
	// 		* initStandardSize
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Initialize a new array with standard capacity.
	//
	// Last Mod:	n/a

	- initStandardSize
	{
		capacity	= CMutableArray_initialCapacity;
		used		= 0;
		objects		= (id*)(calloc(sizeof(id),capacity));
		
		return self;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* initWithCapacity
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Initialize a new array with a specific capacity.
	//
	// Last Mod:	n/a

	- initWithCapacity
		:(unsigned)numItems
	{
		capacity	= numItems;
		used		= 0;
		objects		= (id*)(calloc(sizeof(id),capacity));
		
		return self;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* free
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Dispose on an entire array.  This routine disposes of the
	//				objects in the array, as well.
	//
	// Last Mod:	n/a

	- free
	{
		while (used)
		  [objects[--used] free];
		free(objects);
		return nil;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* objectAtIndex
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Retrieve the (id) of the object at a specific index in
	//				the array.  Array indices are zero-based.
	//
	// Last Mod:	n/a

	- objectAtIndex
		:(unsigned)index
	{
		if (index >= used)
		  return nil;
		else
		  return objects[index];	
	}
	
//

	// ----------------------------------------------------------------------
	// 		* indexForObject
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Return the index of the specified object within the
	//				array; remember, indexes are zero-based.  The unsigned
	//				value of (-1) is returned if the object is not in the
	//				array.
	//
	// Last Mod:	n/a

	- (unsigned) indexForObject
		:(id)anObject
	{
		unsigned	i = 0;
		
		while (i < used)
		  if ([objects[i] isEqual:anObject])
		    return i;
		  else
		    i++;
		return -1;
	}

//

	// ----------------------------------------------------------------------
	// 		* addObject
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Add an object to the array.  The object in question is
	//				always placed at the end of the used segment of the array
	//				and the array is automatically resized if there are no
	//				array cells available.
	//
	// Last Mod:	n/a

	- (void) addObject
		:(id)anObject
	{
		if (used == capacity)
		  if (![self increaseCapacityBy:CMutableArray_deltaCapacity])
		    return;
		objects[used++] = anObject;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* insertObject
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Insert an object into the array at a specific index
	//				value.  The object(s) from the index value up are shifted
	//				and the array is automatically resized if there are no
	//				array cells available.
	//
	// Last Mod:	n/a

	- (void) insertObject
		:(id)anObject
		:(unsigned)atIndex
	{
		unsigned	index;
		
		if (used == capacity)
		  if (![self increaseCapacityBy:CMutableArray_deltaCapacity])
		    return;
		    
		//  Shift all objects from 'atIndex' up one position:
		for ( index = used++ ; index > atIndex ; index-- )
		  objects[index] = objects[index - 1];
		objects[atIndex] = anObject;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* removeObject
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Remove a particular object from the array.  Removal is
	//				based on matching (id)'s for the objects.  This routine
	//				also disposes of the object.
	//
	// Last Mod:	n/a

	- (void) removeObject
		:(id)anObject
	{
		unsigned	index = 0;
		
		while ((index < used) && (objects[index] != anObject)) index++;
		if (index < used)
		  [self removeObjectAtIndex:index];
	}

//

	// ----------------------------------------------------------------------
	// 		* removeLastObject
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Remove the object at the highest currently-occupied index
	//				in the array.  This routine also disposes of the object.
	//
	// Last Mod:	n/a

	- (void) removeLastObject
	{
		[objects[--used] free];
	}
	
//

	// ----------------------------------------------------------------------
	// 		* removeObjectAtIndex
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Remove the object occupying a particular index in the
	//				array.  This routine also disposes of the object.
	//
	// Last Mod:	n/a

	- (void) removeObjectAtIndex
		:(unsigned)atIndex
	{
		unsigned	index;
		
		if (atIndex < used) {
		  [objects[atIndex] free];
		  used--;
		
		  //  Shift all objects from 'atIndex'+1 down one position:
		  for ( index = atIndex ; index < used ; index++ )
		    objects[index] = objects[index + 1];
		}
	}

//

	// ----------------------------------------------------------------------
	// 		* removeAllObjects
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Remove every object in the array.  This does not free the
	//				array storage, just the objects which were in the array.
	//
	// Last Mod:	n/a

	- (void) removeAllObjects
	{
		while (used)
		  [objects[--used] free];
	}
	
//

	// ----------------------------------------------------------------------
	// 		* removeObjectsInRange
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Remove all the objects from one index to another (i.e. a
	//				range of index values).  The objects are disposed of.
	//
	// Last Mod:	n/a

	- (void) removeObjectsInRange
		:(unsigned)from
		:(unsigned)to
	{
		if ((from < used) && (to < used)) {
		  unsigned	index;
		  
		  //  First, dispose of all objects in the range:
		  for ( index = from ; index <= to ; index++ )
		    [objects[index] free];
		  //  Now, shift the remaining objects down:
		  for ( ; index < used ; index++ )
		    objects[from + index - to - 1] = objects[index];
		  used = (used - (to - from + 1));
		}
	}
	
//

	// ----------------------------------------------------------------------
	// 		* capacity
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Return the current capacity of the array, i.e. the
	//				maximum number of objects it can hold without resizing.
	//
	// Last Mod:	n/a

	- (unsigned) capacity
	{
		return capacity;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* inUse
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		For an array of an arbitrary capacity, how many of the
	//				array cells are currently being used (i.e. how many
	//				objects have been stored)?
	//
	// Last Mod:	n/a

	- (unsigned) inUse
	{
		return used;
	}
	
//

	// ----------------------------------------------------------------------
	// 		* increaseCapacityBy
	// ----------------------------------------------------------------------
	// Updated:		Jeff Frey, 08/14/2000
	// Purpose:		Add to the capacity of this array.  If the increase can
	//				be made, YES is returned.  Otherwise, NO is returned.
	//
	// Last Mod:	n/a

	- (BOOL) increaseCapacityBy
		:(unsigned)dCapacity
	{
		id*		newObjects;
		
		newObjects = (id*)(realloc(objects,(capacity + dCapacity) * sizeof(id)));
		if (newObjects) {
		  capacity += dCapacity;
		  objects = newObjects;
		  return YES;
		}
		else
		  return NO;
	}
	
//

@end
