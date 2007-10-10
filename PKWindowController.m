//
//  PKWindowController.m
//  Peacock
//
//  Created by Johan Kool on 10/9/07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import "PKWindowController.h"

#import "JKGCMSDocument.h"
#import "JKAppDelegate.h"

@implementation PKWindowController

- (void)awakeFromNib
{
    [[documentTabView tabViewItemAtIndex:0] setView:[[[(JKAppDelegate *)[NSApp delegate] summaryController] window] contentView]];
    [[(JKAppDelegate *)[NSApp delegate] summaryController] setWindow:[self window]];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isKindOfClass:[JKGCMSDocument class]]) {
        [[self window] setTitleWithRepresentedFilename:[[tabViewItem identifier] fileName]];
        [[self window] setNextResponder:[[tabViewItem identifier] mainWindowController]];
        [[[tabViewItem identifier] mainWindowController] setWindow:[self window]];
        [self setDocument:[tabViewItem identifier]];
    } else {
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Summary"];
        [[self window] setNextResponder:[(JKAppDelegate *)[NSApp delegate] summaryController]];
        [self setDocument:nil];
	}
}
- (void)performClose:(id)sender
{
   // Don't!
}
@end
