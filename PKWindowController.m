//
//  PKWindowController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKWindowController.h"

#import "JKGCMSDocument.h"

@implementation PKWindowController
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isKindOfClass:[JKGCMSDocument class]]) {
        [[self window] setTitleWithRepresentedFilename:[[tabViewItem identifier] fileName]];
        [[self window] setNextResponder:[[tabViewItem identifier] mainWindowController]];
        [[[tabViewItem identifier] mainWindowController] setWindow:[self window]];
        [self setDocument:[tabViewItem identifier]];
    } else {
        if (![[documentTabView tabViewItemAtIndex:0] view] != [[[[NSApp delegate] summaryController] window] contentView]) {
            [[documentTabView tabViewItemAtIndex:0] setView:[[[[NSApp delegate] summaryController] window] contentView]];
            [[[NSApp delegate] summaryController] setWindow:[self window]];
        }
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Summary"];
        [[self window] setNextResponder:[[NSApp delegate] summaryController]];
        [self setDocument:nil];
	}
}
- (void)performClose:(id)sender
{
   // Don't!
}
@end
