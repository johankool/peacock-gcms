//
//  CTGradient.h
//
//  Created by Chad Weider on 12/3/05.
//  Copyright (c) 2005 Cotingent.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import <Cocoa/Cocoa.h>

typedef struct _CTGradientElement 
	{
	float red, green, blue, alpha;
	float position;
	
	struct _CTGradientElement *nextElement;
	} CTGradientElement;


@interface CTGradient : NSObject
	{
	CTGradientElement* elementList;
	
	CGFunctionRef gradientFunction;
	}

+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;

+ (id)aquaSelectedGradient;
+ (id)aquaNormalGradient;
+ (id)aquaPressedGradient;

+ (id)unifiedSelectedGradient;
+ (id)unifiedNormalGradient;
+ (id)unifiedPressedGradient;
+ (id)unifiedDarkGradient;

- (CTGradient *)gradientWithAlphaComponent:(float)alpha;

- (void)addColorStop:(NSColor *)color atPosition:(float)position;	//positions given relative to [0,1]
- (BOOL)removeColorStopAtPosition:(float)position;
- (NSColor *)colorAtPosition:(float)position;

- (void)fillRect:(NSRect)rect angle:(float)angle;					//angle in degrees

@end
