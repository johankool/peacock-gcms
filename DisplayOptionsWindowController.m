//
//  DisplayOptionsWindowController.m
//  HebX
//
//  Created by Andreas on 27.08.05.
//  Copyright 2005 Andreas Mayer. All rights reserved.
//

#import "DisplayOptionsWindowController.h"


@implementation DisplayOptionsWindowController

- (id)init
{
	self = [self initWithWindowNibName:@"DisplayOptions"];
	[self setWindowFrameAutosaveName:@"DisplayOptions"];
	return self;
}

- (void)dealloc
{
	[icon release];
	[heading release];
	[options release];
	[super dealloc];
}


// ============================================================
#pragma mark -
#pragma mark ━ accessor methods ━
// ============================================================

- (id)delegate
{
	return delegate; 
}

- (void)setDelegate:(id)newDelegate
{
	// do not retain
	delegate = newDelegate;
}

- (NSArray *)options
{
	return options; 
}

- (void)setOptions:(NSArray *)newOptions
{
	if (options != newOptions) {
		[newOptions retain];
		[options release];
		options = newOptions;
	}
}

- (NSString *)heading
{
	return heading; 
}

- (void)setHeading:(NSString *)newHeading
{
	if (heading != newHeading) {
		[newHeading retain];
		[heading release];
		heading = newHeading;
		[headingField setStringValue:heading];
	}
}

- (NSImage *)icon
{
	return icon; 
}

- (void)setIcon:(NSImage *)newIcon
{
	if (icon != newIcon) {
		[newIcon retain];
		[icon release];
		icon = newIcon;
		[iconView setImage:icon];
	}
}


// ============================================================
#pragma mark -
#pragma mark ━ action methods ━
// ============================================================

- (IBAction)ok:(id)sender
{
	[NSApp stopModal];
	[[self window] orderOut:self];
	if ([delegate respondsToSelector:@selector(setViewOptions:)]) {
		[delegate performSelector:@selector(setViewOptions:) withObject:options];
	}
	[self release];
}

- (IBAction)cancel:(id)sender
{
	[NSApp stopModal];
	[[self window] orderOut:self];
	[self release];
}

- (IBAction)toggleOption:(id)sender
{
	int index = [[(NSMatrix *)sender selectedCell] tag];
	BOOL selected = [[(NSMatrix *)sender selectedCell] state] == NSOnState;
	[(NSMutableDictionary *)[options objectAtIndex:index] setValue:[NSNumber numberWithBool:selected] forKey:@"selected"];
}


// ============================================================
#pragma mark -
#pragma mark ━ window controller methods ━
// ============================================================

- (IBAction)showWindow:(id)sender
{
	// calculate new matrix size
	[self window];
	int columns = 2;
	int rows = ([options count]+1)/2;
	[optionsMatrix renewRows:rows columns:columns];
	int i = 0;
	int row = 0;
	int column = 0;
	NSButtonCell *cell = nil;
	NSEnumerator *enumerator = [options objectEnumerator];
	NSDictionary *option;
	while (option = [enumerator nextObject]) {
		cell = [optionsMatrix cellAtRow:row column:column];
		[cell setTitle:[option valueForKey:@"title"]];
		[cell setEnabled:[[option valueForKey:@"enabled"] boolValue]];
		[cell setState:([[option valueForKey:@"selected"] boolValue] ? NSOnState : NSOffState)];
		[cell setTag:i++];
		
		row++;
		if (row == rows) {
			column++;
			row = 0;
		}
	}
	if (row < rows) {
		// remove last cell
		NSCell *emptyCell = [[[NSCell alloc] init] autorelease];
		[emptyCell setEnabled:NO];
		[optionsMatrix putCell:emptyCell atRow:row column:column];
	}
	[[self window] center];
	[super showWindow:sender];
	[self retain];
	[NSApp runModalForWindow:[self window]];
}

- (void)windowDidLoad
{
	if (heading) {
		[headingField setStringValue:heading];
	}
	[iconView setImage:icon];
}



@end
