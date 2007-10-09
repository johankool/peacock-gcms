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
        [[self window] setTitleWithRepresentedFilename:@""];
        [[self window] setTitle:@"Summary"];
        [self setDocument:nil];
	}
}
- (BOOL)windowShouldClose:(id)sender
{
 	if ([managedDocuments count] > 1) {
        return YES;
    } else {
        return NO;
    }
}
@end
