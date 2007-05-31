//
//  JKPathPopUpButton.m
//  Peacock
//
//  Created by Johan Kool on 15-5-06.
//  Copyright 2006-2007 Johan Kool. All rights reserved.
//

#import "JKPathPopUpButton.h"

#import "BDAlias.h"

@implementation JKPathPopUpButton

+ (void)initialize {
	// Bindings support
	[self exposeBinding:@"fileAlias"];
}

- (id)initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag{
	self = [super initWithFrame:frameRect pullsDown:NO];
	if (self != nil) {
		[self setupMenu];
	}
	return self;
}

- (void) dealloc {
	[self unbind:@"fileAlias"];

	[super dealloc];
}

- (void)awakeFromNib{
	[self setupMenu];
}

- (NSArray *)exposedBindings {
	return [[super exposedBindings] arrayByAddingObject:@"fileAlias"];
}
#pragma mark BINDINGS
- (void)bind:(NSString *)bindingName
	toObject:(id)observableObject
 withKeyPath:(NSString *)observableKeyPath
	 options:(NSDictionary *)options{
	
    if ([bindingName isEqualToString:@"fileAlias"])
	{		
		[self setFileAliasContainer:observableObject];
		[self setFileAliasKeyPath:observableKeyPath];
		[fileAliasContainer addObserver:self
							  forKeyPath:fileAliasKeyPath
								 options:nil
								 context:nil];
    } else {
		[super bind:bindingName
		   toObject:observableObject
		withKeyPath:observableKeyPath
			options:options];
		
	}

    [self setupMenu];
}


- (void)unbind:(NSString *)bindingName {
    if ([bindingName isEqualToString:@"fileAlias"]) {
		[fileAliasContainer removeObserver:self forKeyPath:fileAliasKeyPath];
		[self setFileAliasContainer:nil];
		[self setFileAliasKeyPath:nil];
    }

	[super unbind:bindingName];
	[self setupMenu];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context{
	[self setupMenu];
}		

- (void)setupMenu {
	[self removeAllItems];
	
	NSMenuItem *noSelectionItem = [[NSMenuItem alloc] initWithTitle:@"No Selection" action:@selector(selectNone:) keyEquivalent:@""];
	[noSelectionItem setTarget:self];
	[[self menu] addItem:noSelectionItem];
	[self selectItem:noSelectionItem];
	[noSelectionItem release];
	
	[[self menu] addItem:[NSMenuItem separatorItem]];
	
	if ([self filePath]) {
		NSMenuItem *selectedFileItem = [[NSMenuItem alloc] initWithTitle:[[NSFileManager defaultManager] displayNameAtPath:[self filePath]] action:nil keyEquivalent:@""];
		NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:[self filePath]];
		[image setSize:NSMakeSize(16,16)];
		[selectedFileItem setImage:image];
		[[self menu] addItem:selectedFileItem];
		[self selectItem:selectedFileItem];
		[selectedFileItem release];

		[[self menu] addItem:[NSMenuItem separatorItem]];
		
	}
	
	NSMenuItem *chooseExistingPathItem = [[NSMenuItem alloc] initWithTitle:@"Other..." action:@selector(chooseExistingPath:) keyEquivalent:@""];
	[chooseExistingPathItem setTarget:self];
	[[self menu] addItem:chooseExistingPathItem];	
	[chooseExistingPathItem release];
}

- (IBAction)chooseExistingPath:(id)sender {
	fileTypes = [NSArray arrayWithObjects:@"jdx",@"dx",@"hpj",@"peacock-library",nil];

	int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
	if ([self fileAlias]) {
		result = [oPanel runModalForDirectory:[[self filePath] stringByDeletingLastPathComponent] 
										 file:[[self filePath] lastPathComponent]
										types:fileTypes];		
	} else {
		result = [oPanel runModalForDirectory:nil 
										 file:nil
										types:fileTypes];		
	}
	
    if (result == NSOKButton) {
		[self setFileAlias:[BDAlias aliasWithPath:[[oPanel filenames] objectAtIndex:0]]];
    }
	[self setupMenu];
}

- (IBAction)selectNone:(id)sender{
	[self setFileAlias:nil];
	[self setupMenu];
}

- (NSString *)filePath {
	//NSNoSelectionMarker?
	if ([self fileAlias] != NSNoSelectionMarker) {
		return [[self fileAlias] fullPath];
	} else {
		return nil;
	}
}

//idAccessor(fileAlias, setFileAlias);
- (BDAlias *)fileAlias{
	return [fileAliasContainer valueForKeyPath:fileAliasKeyPath];	
}

- (void)setFileAlias:(id)inValue{
	[fileAliasContainer setValue:inValue forKeyPath:fileAliasKeyPath];
}

- (id)fileAliasContainer {
	return fileAliasContainer;
}
- (void)setFileAliasContainer:(id)aFileAliasContainer {
	fileAliasContainer = aFileAliasContainer;
}
- (id)fileAliasKeyPath {
	return fileAliasKeyPath;
}
- (void)setFileAliasKeyPath:(id)aFileAliasKeyPath {
	fileAliasKeyPath = aFileAliasKeyPath;
}
//
//
//idAccessor(fileAliasContainer, setFileAliasContainer)
//idAccessor(fileAliasKeyPath, setFileAliasKeyPath)

@end
