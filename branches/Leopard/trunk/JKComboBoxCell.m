//
//  JKComboBoxCell.m
//  Peacock
//
//  Created by Johan Kool on 12-7-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "JKComboBoxCell.h"


@implementation JKComboBoxCell
- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    [super drawWithFrame:NSMakeRect(cellFrame.origin.x,cellFrame.origin.y-1,cellFrame.size.width+8,cellFrame.size.height+2) inView:controlView];
}
@end
