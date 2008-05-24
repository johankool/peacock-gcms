//
//  NSCoder+CArrayEncoding.m
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import "NSCoder+CArrayEncoding.h"

#import "PKArrayEncodingObject.h"

@implementation NSCoder (CArrayEncoding)

- (void)encodeIntArray:(int *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key{
    PKArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[PKArrayEncodingObject alloc] initWithIntArray: anArray
                                                        elementSize: (int) sizeof(int)
                                                           andCount: aCount] autorelease];
    //encode the arrayObject using NSArchiver, which allows writing arrays of C data types
    myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
    
    //Now encode the resulting data object into our keyed archive.
    [self  encodeObject: myDataObject forKey: key];    
}

- (void)encodeFloatArray:(float *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key {
    PKArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[PKArrayEncodingObject alloc] initWithFloatArray: anArray
                                                          elementSize: (int) sizeof(float)
                                                             andCount: aCount] autorelease];
    //encode the arrayObject using NSArchiver, which allows writing arrays of C data types
    myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
    
    //Now encode the resulting data object into our keyed archive.
    [self  encodeObject: myDataObject forKey: key];        
}

- (void)encodeDoubleArray:(double *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key {
    PKArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[PKArrayEncodingObject alloc] initWithDoubleArray: anArray
                                                           elementSize: (int) sizeof(double)
                                                              andCount: aCount] autorelease];
    //encode the arrayObject using NSArchiver, which allows writing arrays of C data types
    myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
    
    //Now encode the resulting data object into our keyed archive.
    [self  encodeObject: myDataObject forKey: key];            
}

- (int *)decodeIntArrayForKey:(NSString *)key returnedCount:(unsigned *)countp {
    //Get the NSData object which contains an NSArchiver archive of an arrayObject
    //Containing our iteration buffer (UGH!!!!)
    NSData *myDataObject = [self decodeObjectForKey: key];
    PKArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    int *theIterationBuffer = [theArrayObject getIntArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;
}
- (float *)decodeFloatArrayForKey:(NSString *)key returnedCount:(unsigned *)countp {
    //Get the NSData object which contains an NSArchiver archive of an arrayObject
    //Containing our iteration buffer (UGH!!!!)
    NSData *myDataObject = [self decodeObjectForKey: key];
    PKArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    float *theIterationBuffer = [theArrayObject getFloatArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;
}
- (double *)decodeDoubleArrayForKey:(NSString *)key returnedCount:(unsigned *)countp {
    //Get the NSData object which contains an NSArchiver archive of an arrayObject
    //Containing our iteration buffer (UGH!!!!)
    NSData *myDataObject = [self decodeObjectForKey:key];
    PKArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    double *theIterationBuffer = [theArrayObject getDoubleArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;    
}

@end
