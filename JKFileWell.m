//
//  JKFileWell.m
//  JKFileWell
//
//  Created by Johan Kool on 7-11-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "JKFileWell.h"


@implementation JKFileWell

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		acceptDrops = YES;
		allowDrags = NO;
		acceptFolders = NO;
		acceptFiles = YES;
		allowEmptySelection = YES;
		allowMultipleFiles = NO;
		showLabel = YES;
		showIcon = YES;
		iconSize = 32;
//		displaySize = 2;
		
		acceptedFileExtensions = [[NSArray arrayWithObjects:@"jdx",nil] retain];

		
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
		
		files = [[NSMutableArray alloc] init];
		icons = [[NSMutableArray alloc] init];

		NSPopUpButton *popupButton = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0,[self bounds].size.height-iconSize-20,[self bounds].size.width,20) pullsDown:YES];
		[popupButton setBordered:NO];
		[popupButton setTitle:@""];
		NSMenu *popupMenu = [[NSMenu alloc] init];
		NSMenuItem *removeAllMenu;
		if (allowMultipleFiles) {
			removeAllMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove All",@"") action:nil keyEquivalent:@""];	
		} else {
			removeAllMenu = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Remove",@"") action:@selector(remove) keyEquivalent:@""];
		}
		[popupMenu addItemWithTitle:@"" action:nil keyEquivalent:@""];
		[popupMenu addItem:removeAllMenu];
		[popupMenu addItem:[NSMenuItem separatorItem]];
		[popupMenu addItemWithTitle:NSLocalizedString(@"Open",@"") action:@selector(open) keyEquivalent:@""];
		[popupMenu addItemWithTitle:NSLocalizedString(@"Reveal in Finder",@"") action:@selector(revealInFinder) keyEquivalent:@""];
//		[popupMenu addItemWithTitle:@"<your own actions here?>" action:nil keyEquivalent:@""];
		[popupMenu addItem:[NSMenuItem separatorItem]];
		[popupMenu addItemWithTitle:NSLocalizedString(@"Choose File...",@"") action:@selector(browse) keyEquivalent:@""];
		[popupButton setMenu:popupMenu];
		[popupButton setAutoresizingMask:(NSViewWidthSizable|NSViewMinYMargin)];
		[self addSubview:popupButton];
		
		// Debug
//		[files addObject:[NSString stringWithString:@"/Users/jkool/Desktop/Test map"]];
//		[files addObject:[NSString stringWithString:@"/Users/jkool/Desktop/Test map/Test.rtf"]];
//		[files addObject:[NSString stringWithString:@"/Users/jkool/Developer/JKFileWell/JKFileWell.h"]];
//		[icons addObject:[[NSWorkspace sharedWorkspace] iconForFile:@"/Users/jkool/Desktop/Test map"]]; 
//		[icons addObject:[[NSWorkspace sharedWorkspace] iconForFile:@"/Users/jkool/Desktop/Test map/Test.rtf"]];
//		[icons addObject:[[NSWorkspace sharedWorkspace] iconForFile:@"/Users/jkool/Developer/JKFileWell/JKFileWell.h"]];
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
	NSImage *icon;
	NSMutableString *labelString;
	NSSize labelSize;
//	int iconSize =64;// [self bounds].size.width/[files count];
	int i;
	// Calculate areas
	
	
	// Drawing code here.
	if ([files count] == 0) {
		icon = [NSImage imageNamed: @"questionmark"];
		[icon drawInRect:NSMakeRect(([self bounds].size.width-iconSize)/2,[self bounds].size.height-iconSize,iconSize,iconSize)  fromRect:NSMakeRect(0,0,iconSize,iconSize) operation:NSCompositeSourceAtop fraction:1.0];

//		labelString = [NSMutableString stringWithString:@"No Selection"];			
//		labelSize = [labelString sizeWithAttributes:nil];
//		[labelString drawAtPoint:NSMakePoint(([self bounds].size.width-labelSize.width)/2,[self bounds].size.height-iconSize-labelSize.height) withAttributes:nil];
		return;
	}
	if (showIcon) {
		for (i = 0; i < [files count]; i++) {
			icon = [icons objectAtIndex:i];
			[icon setSize:NSMakeSize(iconSize,iconSize)];
			[icon drawInRect:NSMakeRect(([self bounds].size.width-iconSize)/2-([files count]*6)+12*i+6,[self bounds].size.height-iconSize,iconSize,iconSize)  fromRect:NSMakeRect(0,0,iconSize,iconSize) operation:NSCompositeSourceAtop fraction:1.0];
		}
	}
	if (showLabel) {
		if ([files count] > 1) {
			labelString = [NSMutableString stringWithString:NSLocalizedString(@"Multiple Files Selected",@"")];
		} else if ([files count] == 1) {
			labelString =  [NSMutableString stringWithString:[[NSFileManager defaultManager] displayNameAtPath:[files objectAtIndex:0]]];
		} else {
			labelString = [NSMutableString stringWithString:NSLocalizedString(@"No Selection",@"")];			
		}
		labelSize = [labelString sizeWithAttributes:nil];
		[labelString drawAtPoint:NSMakePoint(([self bounds].size.width-labelSize.width)/2,[self bounds].size.height-iconSize-labelSize.height) withAttributes:nil];
	}
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (!allowDrags || [files count] == 0) {
		return;		
	}
	
    NSImage *dragImage;
    NSPoint dragPosition;
    // Write data to the pasteboard
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType]
				   owner:nil];
    [pboard setPropertyList:files forType:NSFilenamesPboardType];

    // Start the drag operation
    dragImage = [[NSWorkspace sharedWorkspace] iconForFiles:files];
    dragPosition = [self convertPoint:[theEvent locationInWindow]
							 fromView:nil];
    dragPosition.x -= 16;
    dragPosition.y -= 16;
    [self dragImage:dragImage 
				 at:dragPosition
			 offset:NSZeroSize
			  event:theEvent
		 pasteboard:pboard
			 source:self
		  slideBack:YES];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	if (!acceptDrops) {
		return NSDragOperationNone;		
	}
	
	int i;
	BOOL isDirectory;
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

    if ( [[pboard types] containsObject:NSFilenamesPboardType] ) {
 		NSArray *filesComingIn = [pboard propertyListForType:NSFilenamesPboardType];
		for (i = 0; i < [filesComingIn count]; i++) {
			// Do we get a real file?
			if ([[NSFileManager defaultManager] fileExistsAtPath:[filesComingIn objectAtIndex:i] isDirectory:&isDirectory]) {
				// Is it a folder? Do we accept it?
				if ((isDirectory && acceptFolders) || (!isDirectory && acceptFiles)) {
					// Need to check if we accept this file extension
					 return NSDragOperationLink;
				}
			}
		}
		
    }
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	if (!acceptDrops) {
		return NO;		
	}

	int i;
	BOOL isDirectory;
    NSPasteboard *pboard;
    NSDragOperation sourceDragMask;
    sourceDragMask = [sender draggingSourceOperationMask];
    pboard = [sender draggingPasteboard];

	if ( [[pboard types] containsObject:NSFilenamesPboardType]  ) {
        NSArray *filesComingIn = [pboard propertyListForType:NSFilenamesPboardType];
		for (i = 0; i < [filesComingIn count]; i++) {
			// Do we get a real file?
			if ([[NSFileManager defaultManager] fileExistsAtPath:[filesComingIn objectAtIndex:i] isDirectory:&isDirectory]) {
				// Is it a folder? Do we accept it?
				if ((isDirectory && acceptFolders) || (!isDirectory && acceptFiles)) {
					if (allowMultipleFiles) {
						// Need to check if we accept this file extension 
						// Need to check if we not already have a link to the file/folder
						[files addObject:[filesComingIn objectAtIndex:i]];
						[icons addObject:[[NSWorkspace sharedWorkspace] iconForFile:[filesComingIn objectAtIndex:i]]];
					} else {
						[files removeAllObjects];
						[icons removeAllObjects];
						[files insertObject:[filesComingIn objectAtIndex:i] atIndex:0];
						[icons insertObject:[[NSWorkspace sharedWorkspace] iconForFile:[filesComingIn objectAtIndex:i]] atIndex:0];
						// We accept only the first file we recognize, then get back.
						return YES;
					}
					
				}
			}
		}

		[self setNeedsDisplay:YES];
    }
    return YES;
}

-(void)open {
	[[NSWorkspace sharedWorkspace] openFile:[files objectAtIndex:0] fromImage:[icons objectAtIndex:0] at:NSZeroPoint inView:self];
}

-(void)revealInFinder {
	[[NSWorkspace sharedWorkspace] selectFile:[files objectAtIndex:0] inFileViewerRootedAtPath:nil];
}

-(void)browse {
	int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:allowMultipleFiles];
    result = [oPanel runModalForDirectory:nil
									 file:nil types:acceptedFileExtensions];
    if (result == NSOKButton) {
//        NSArray *filesToOpen = [oPanel filenames];
		files = [[oPanel filenames] mutableCopy];
//        int i, count = [filesToOpen count];
//        for (i=0; i<count; i++) {
//            NSString *aFile = [filesToOpen objectAtIndex:i];
//			[[NSUserDefaults standardUserDefaults] setValue:aFile forKey:@"defaultLibrary"];
//        }
    }
}

-(void)remove {
	if (allowEmptySelection) {
		[files removeAllObjects];
		return;
	}
	return;
}
@end
