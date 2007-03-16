//
//  ArrayEncodingObject.m
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import "ArrayEncodingObject.h"


@implementation ArrayEncodingObject

- (int *)getIntArray {
    return (int *)theArray;
}

- (float *)getFloatArray {
    return (float*)theArray;
}

- (double *)getDoubleArray {
    return (double*)theArray;
}

- (unsigned long)count {
    return theCount;
}

#pragma mark -
#pragma mark NSCoding methods

- (id)initWithCoder:(NSCoder*) coder {
//    JKLogDebug(@"In %@ initWithCoder", self);
    if ((self = [super init]))        //Parent class is NSObject; no need to call super initWithCoder
    {
        [coder decodeValueOfObjCType:@encode(unsigned int) at:&theElementSize];
        [coder decodeValueOfObjCType:@encode(unsigned int) at:&theElementType];
        [coder decodeValueOfObjCType:@encode(unsigned long) at:&theCount];
        
        theArray = malloc((theCount) * theElementSize);
        switch (theElementType) {
        case 0:
            [coder decodeArrayOfObjCType:@encode(int) count:theCount at:theArray];
            break;
        case 1:
            [coder decodeArrayOfObjCType:@encode(float) count:theCount at:theArray];
            break;
        case 2:
            [coder decodeArrayOfObjCType:@encode(double) count:theCount at:theArray];
            break;
        default:
            theArray = nil; //Error!
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
                                   at:theArray];
        break;
    case 1:
        [coder  encodeArrayOfObjCType:@encode(float)
                                count:theCount
                                   at:theArray];
        break;
    case 2:
        [coder  encodeArrayOfObjCType:@encode(double)
                                count:theCount
                                   at:theArray];
        break;
    default:
        break;
    }
}

#pragma mark -
#pragma mark        init/dealloc methods


- (id)initWithIntArray:(int *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theArray = anArray;
    theElementSize = theSize;
    theElementType = 0;
    theCount = aCount;
    return self;
}

- (id)initWithFloatArray:(float *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theArray = anArray;
    theElementSize = theSize;
    theElementType = 1;
    theCount = aCount;
    return self;
}

- (id)initWithDoubleArray:(double *)anArray elementSize:(int)theSize andCount:(unsigned long)aCount {
    self = [super init];
    theArray = anArray;
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
