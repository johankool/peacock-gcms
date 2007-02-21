//
//  NSKeyedArchiver+CArrayEncoding.m
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import "NSKeyedArchiver+CArrayEncoding.h"

#import "ArrayEncodingObject.h"

@implementation NSKeyedArchiver (CArrayEncoding)

//- (void)encodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(const void *)address forKey:(NSString *)key {
//    //Create a temporary arrayObject to hold our buffer.
//    ArrayEncodingObject *myEncodeObject = [[[ArrayEncodingObject alloc] initWithArray: &address
//                                                                          elementType: itemType
//                                                                             andCount: count] autorelease];
//    //Ecode the arrayObject using NSArchiver, which allows writing arrays of C data types
//    NSData *myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
//    
//    //Now encode the resulting data object into our keyed archive.
//    [self encodeObject:myDataObject forKey:key];        
//}
//
//- (void)decodeArrayOfObjCType:(const char *)itemType count:(unsigned)count at:(void *)address forKey:(NSString *)key {
//    //Get the NSData object which contains an NSArchiver archive of an arrayObject
//    //Containing our iteration buffer (UGH!!!!)
//    NSData *myDataObject = [self decodeObjectForKey:key];
//    ArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData:myDataObject];
//    int *theIterationBuffer = [theArrayObject getArrayOfObjCType:(const char *)itemType];
//    *countp = [theArrayObject count];
//    return theIterationBuffer;
//    
//}


- (void)encodeIntArray:(int *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key{
    ArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[ArrayEncodingObject alloc] initWithIntArray: anArray
                                               elementSize: (int) sizeof(int)
                                                  andCount: aCount] autorelease];
    //encode the arrayObject using NSArchiver, which allows writing arrays of C data types
    myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
    
    //Now encode the resulting data object into our keyed archive.
    [self  encodeObject: myDataObject forKey: key];    
}

- (void)encodeFloatArray:(float *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key {
    ArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[ArrayEncodingObject alloc] initWithFloatArray: anArray
                                                     elementSize: (int) sizeof(float)
                                                        andCount: aCount] autorelease];
    //encode the arrayObject using NSArchiver, which allows writing arrays of C data types
    myDataObject = [NSArchiver archivedDataWithRootObject:myEncodeObject];
    
    //Now encode the resulting data object into our keyed archive.
    [self  encodeObject: myDataObject forKey: key];        
}

- (void)encodeDoubleArray:(double *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key {
    ArrayEncodingObject* myEncodeObject;
    NSData* myDataObject;
    //Create a temporary arrayObject to hold our Iteration buffer.
    myEncodeObject = [[[ArrayEncodingObject alloc] initWithDoubleArray: anArray
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
    ArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    int *theIterationBuffer = [theArrayObject getIntArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;
}
- (float *)decodeFloatArrayForKey:(NSString *)key returnedCount:(unsigned *)countp {
    //Get the NSData object which contains an NSArchiver archive of an arrayObject
    //Containing our iteration buffer (UGH!!!!)
    NSData *myDataObject = [self decodeObjectForKey: key];
    ArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    float *theIterationBuffer = [theArrayObject getFloatArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;
}
- (double *)decodeDoubleArrayForKey:(NSString *)key returnedCount:(unsigned *)countp {
    //Get the NSData object which contains an NSArchiver archive of an arrayObject
    //Containing our iteration buffer (UGH!!!!)
    NSData *myDataObject = [self decodeObjectForKey:key];
    ArrayEncodingObject *theArrayObject = [NSUnarchiver unarchiveObjectWithData: myDataObject];
    double *theIterationBuffer = [theArrayObject getDoubleArray];
    *countp = [theArrayObject count];
    return theIterationBuffer;    
}

@end
