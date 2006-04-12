/*
 *  jk_statistics.c
 *  Peacock
 *
 *  Created by Johan Kool on 10-4-06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#include "jk_statistics.h"
#include "math.h"

#pragma mark FUNCTIONS

void normalize(float *input, int count) {
    int i;
	float maximum;
	
	maximum = fabs(input[0]);
	for (i = 1; i < count; i++) {
		if (fabs(input[i]) > maximum) maximum = fabs(input[i]);
	}
	
	for (i = 0; i < count; i++) {
		input[i] = input[i]/maximum;
	}
}

float jk_stats_float_min(float *data, int count) {
	int i;
	float min = data[0];
	
	for (i=0; i < count; i++) {
		if (data[i] < min) {
			min = data[i];
		}
	}
	return min;
}

float jk_stats_float_max(float *data, int count) {
	int i;
	float max = data[0];
	
	for (i=0; i < count; i++) {
		if (data[i] > max) {
			max = data[i];
		}
	}
	return max;
}
