//
//  PKFlipView.m
//  Peacock
//
//  Created by Johan Kool on 04-12-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKFlipView.h"


@implementation PKFlipView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
 
	[[NSColor whiteColor] set];
    NSSize paperSize = [[NSPrintInfo sharedPrintInfo] paperSize];
    NSRect paperRect = NSMakeRect(0.0f, 0.0f, paperSize.width, paperSize.height);

	[[NSBezierPath bezierPathWithRect:paperRect] fill];
        
}

- (BOOL)isFlipped {
    return YES;
}

@end
