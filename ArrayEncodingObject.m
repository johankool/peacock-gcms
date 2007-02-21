//
//  ArrayEncodingObject.m
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import "ArrayEncodingObject.h"


@implementation ArrayEncodingObject

- (int *)getIntArray {
    return (int *)theIntArray;
}

- (float *)getFloatArray {
    return (float*)theFloatArray;
}

- (double *)getDoubleArray {
    return (double*)theDoubleArray;
}

- (unsigned long)count {
    return theCount;
}

#pragma mark -
#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*) coder {
//    NSLog(@"In %@ initWithCoder", self);
    if ((self = [super init]))        //Parent class is NSObject; no need to call super initWithCoder
    {
        [coder decodeValueOfObjCType:@encode(unsigned int) at:&theElementSize];
        [coder decodeValueOfObjCType:@encode(unsigned int) at:&theElementType];
        [coder decodeValueOfObjCType:@encode(unsigned long) at:&theCount];
        
        switch (theElementType) {
        case 0:
            theIntArray = malloc((theCount) * theElementSize);
            [coder decodeArrayOfObjCType:@encode(int) count:theCount at:theIntArray];
            break;
        case 1:
            theFloatArray = malloc((theCount) * theElementSize);
            [coder decodeArrayOfObjCType:@encode(float) count:theCount at:theFloatArray];
            break;
        case 2:
            theDoubleArray = malloc((theCount) * theElementSize);
            [coder decodeArrayOfObjCType:@encode(double) count:theCount at:theDoubleArray];
            break;
        default:
            theIntArray = nil; //Error!
            theFloatArray = nil; //Error!
            theDoubleArray = nil; //Error!
            break;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder{
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&theElementSize];
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&theElementType];
    [coder encodeValueOfObjCType:@encode(unsigned long) at:&theCount];
    
    switch (theElementType) {
    case 0:
        [coder  encodeArrayOfObjCType:@encode(int)
                                count:theCount
                                   at:theIntArray];
        break;
    case 1:
        [coder  encodeArrayOfObjCType:@encode(float)
                                count:theCount
                                   at:theFloatArray];
        break;
    case 2:
        [coder  encodeArrayOfObjCType:@encode(double)
                                count:theCount
                                   at:theDoubleArray];
        break;
    default:
        break;
    }
}

#pragma mark -
#pragma mark        init/dealloc methods


- (id)initWithIntArray:(int *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theIntArray = anArray;
    theElementSize = theSize;
    theElementType = 0;
    theCount = aCount;
    return self;
}

- (id)initWithFloatArray:(float *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theFloatArray = anArray;
    theElementSize = theSize;
    theElementType = 1;
    theCount = aCount;
    return self;
}

- (id)initWithDoubleArray:(double *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theDoubleArray = anArray;
    theElementSize = theSize;
    theElementType = 2;
    theCount = aCount;
    return self;
}

//This object should NOT free it's data buffer, since it's only job
//is to pass it to another object (and then be autoreleased)
-(void) dealloc       {
    [super dealloc];
}

@end
