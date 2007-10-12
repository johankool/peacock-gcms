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
    [[documentTabView tabViewItemAtIndex:1] setView:[[[(JKAppDelegate *)[NSApp delegate] ratiosController] window] contentView]];
    [[(JKAppDelegate *)[NSApp delegate] ratiosController] setWindow:[self window]];
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if ([[tabViewItem identifier] isKindOfClass:[JKGCMSDocument class]]) {
        [[self window] setTitleWithRepresentedFilename:[[tabViewItem identifier] fileName]];
        [[self window] setNextResponder:[[tabViewItem identifier] mainWindowController]];
        [[[tabViewItem identifier] mainWindowController] setWindow:[self window]];
        [self setDocument:[tabViewItem identifier]];
    } else if ([[tabViewItem identifier] isEqualToString:@"summary"]) {
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Summary"];
        [[self window] setNextResponder:(NSResponder *)[(JKAppDelegate *)[NSApp delegate] summaryController]];
        [self setDocument:nil];
    } else if ([[tabViewItem identifier] isEqualToString:@"ratios"]) {
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Ratios"];
        [[self window] setNextResponder:(NSResponder *)[(JKAppDelegate *)[NSApp delegate] ratiosController]];
        [self setDocument:nil];
	}
}

@end
