//
//  NSCoder+CArrayEncoding.h
//
//  Created by Johan Kool on 20-2-07.
//  Copyright 2007 Duncan Champney & Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSCoder (CArrayEncoding) 

- (void)encodeIntArray:(int *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key;
//- (void)encodeInt32Array:(int32_t*)anArray withCount:(unsigned long)aCount forKey:(NSString *)key;
//- (void)encodeInt64Array:(int64_t*)anArray withCount:(unsigned long)aCount forKey:(NSString *)key;
- (void)encodeFloatArray:(float *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key;
- (void)encodeDoubleArray:(double *)anArray withCount:(unsigned long)aCount forKey:(NSString *)key;

- (int *)decodeIntArrayForKey:(NSString *)key returnedCount:(unsigned *)countp;
//- (int32_t *)decodeInt32ArrayForKey:(NSString *)key returnedCount:(unsigned *)countp;
//- (int64_t *)decodeInt64ArrayForKey:(NSString *)key returnedCount:(unsigned *)countp;
- (float *)decodeFloatArrayForKey:(NSString *)key returnedCount:(unsigned *)countp;
- (double *)decodeDoubleArrayForKey:(NSString *)key returnedCount:(unsigned *)countp;

@end
