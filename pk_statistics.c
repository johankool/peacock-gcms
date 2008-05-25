/*
 *  pk_statistics.c
 *  Peacock
 *
 *  Created by Johan Kool on 10-4-06.
 *  Copyright 2006 Johan Kool. All rights reserved.
 *
 */

#include "pk_statistics.h"
#include "math.h"

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
