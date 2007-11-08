//
//  JKFileWell.h
//  JKFileWell
//
//  Created by Johan Kool on 7-11-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKFileWell : NSView {
	NSMutableArray *files;
	NSMutableArray *icons; // Cache for icons

	// Behaviour settings
	NSArray *acceptedFileExtensions;
	BOOL acceptDrops;
	BOOL allowDrags;
	BOOL acceptFolders;
	BOOL acceptFiles;
	BOOL allowEmptySelection;
	BOOL allowMultipleFiles;
	BOOL useAliases; // Requires accepting license!
	
	// Appearance settings
	int iconSize;
	BOOL showLabel;
	BOOL showIcon;
//	int displaySize; // 0 = mini; 1 = small; 2 = regular;
}

- (void)open;
- (void)revealInFinder;
- (void)browse;

@property BOOL showIcon;
@property BOOL acceptDrops;
@property BOOL showLabel;
@property BOOL acceptFiles;
@property BOOL acceptFolders;
@property (retain) NSMutableArray *icons;
@property BOOL allowDrags;
@property int iconSize;
@property (retain) NSMutableArray *files;
@property (retain) NSArray *acceptedFileExtensions;
@property BOOL useAliases;
@property BOOL allowMultipleFiles;
@property BOOL allowEmptySelection;
@end
