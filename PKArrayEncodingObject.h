//
//  ArrayEncodingObject.h
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKArrayEncodingObject : NSObject <NSCoding> {
    int* theIntArray;
    float* theFloatArray;
    double* theDoubleArray;
//    id theArray;
    int theElementType;
    int theElementSize;
    unsigned long theCount;
}

//- (unsigned short*) getShortArray;
//- (unsigned long*) getLongArray;
- (int *)getIntArray;
- (float *)getFloatArray;
- (double *)getDoubleArray;

- (unsigned long)count;

- (id)initWithIntArray:(int *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount;
- (id)initWithFloatArray:(float *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount;
- (id)initWithDoubleArray:(double *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount;

@end
