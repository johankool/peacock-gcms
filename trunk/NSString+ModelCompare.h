//
//  NSString+ModelCompare.h
//  Peacock
//
//  Created by Johan Kool on 25-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString (ModelCompare) 

-(BOOL)isEqualToModelString:(NSString *)aModelString;
- (NSString *)cleanupModelString:(NSString *)model;

@end
