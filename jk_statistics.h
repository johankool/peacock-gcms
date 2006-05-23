/*
 *  jk_statistics.h
 *  Peacock
 *
 *  Created by Johan Kool on 10-4-06.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#pragma mark FUNCTIONS
void normalize(float *input, int count);

//int jk_stats_float_minmax(float *min, float *max, float *data, const stride, const n);
float jk_stats_float_min(float *data, int count);
float jk_stats_float_max(float *data, int count);