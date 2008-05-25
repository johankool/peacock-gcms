/*
 *  pk_statistics.c
 *  Peacock
 *
 *  Created by Johan Kool on 10-4-06.
 *  Copyright 2006 Johan Kool. All rights reserved.
 *
 */

#import "pk_statistics.h"
#import "math.h"

//#import "JKGCMSDocument.h"

#pragma mark FUNCTIONS

void normalize(float *input, int count) {
    int i;
	float maximum;
	
	maximum = fabsf(input[0]);
	for (i = 1; i < count; i++) {
		if (fabsf(input[i]) > maximum) maximum = fabsf(input[i]);
	}
	
	for (i = 0; i < count; i++) {
		input[i] = input[i]/maximum;
	}
}

float pk_stats_float_min(float *data, int count) {
	int i;
	float min = data[0];
	
	for (i=0; i < count; i++) {
		if (data[i] < min) {
			min = data[i];
		}
	}
	return min;
}

float pk_stats_float_max(float *data, int count) {
	int i;
	float max = data[0];
	
	for (i=0; i < count; i++) {
		if (data[i] > max) {
			max = data[i];
		}
	}
	return max;
}

NSString *GetUUID(void) {
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *)string autorelease];
}

int intSort(id num1, id num2, void *context)
{
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 < v2)
        return NSOrderedAscending;
    else if (v1 > v2)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}


void insertionSort(int numbers[], int array_size)
{
    int i, j, index;
    
    for (i=1; i < array_size; i++)
    {
        index = numbers[i];
        j = i;
        while ((j > 0) && (numbers[j-1] > index))
        {
            numbers[j] = numbers[j-1];
            j = j - 1;
        }
        numbers[j] = index;
    }
}

//static inline void NSSwapHostFloatArrayToBig(float *array, UInt32  count) {
//    int i;
//    
//    for(i = 0; i < count; i++) {
//        array[i] = NSSwapHostFloatToBig(array[i]);
//    }
//}


//void NSSwapHostFloatArrayToLittle(float *array, UInt32  count) {
//    int i;
//    
//    for(i = 0; i < count; i++) {
//        array[i] = NSSwapHostFloatToLittle(arrayOfSwappedFloats[i]);
//    }
//}
//
//void NSSwapLittleFloatArrayToHost(float *array, UInt32  count) {
//    int i;
//    
//    for(i = 0; i < count; i++) {
//        arrayOfSwappedFloats[i] = NSSwapLittleFloatToHost(array[i]);
//    }
//}
