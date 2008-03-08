//
//  CTGradientView.h
//
//  Created by Chad Weider on 12/2/05.
//  Copyright (c) 2005 Cotingent.
//  Some rights reserved: <http://creativecommons.org/licenses/by/2.5/>
//

#import <Cocoa/Cocoa.h>
#import "CTGradient.h"

@interface CTGradientView : NSView
	{
	CTGradient *myGradient;
	
	float angle;
	}

- (IBAction)changeAngle:(id)sender;
- (IBAction)changeStyle:(id)sender;

@end
