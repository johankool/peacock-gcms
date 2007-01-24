//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class JKLibraryWindowController;
@class JKLibraryEntry;

@interface JKLibrary : NSDocument {
    JKLibraryWindowController *libraryWindowController;
	NSMutableArray *libraryEntries;
}

#pragma mark IMPORT/EXPORT ACTIONS
- (NSArray *)readJCAMPString:(NSString *)inString;

- (BOOL)importJCAMPFromFile:(NSString *)fileName;
- (BOOL)exportJCAMPToFile:(NSString *)fileName;

- (BOOL)importAMDISFromFile:(NSString *)fileName;
- (BOOL)exportAMDISToFile:(NSString *)fileName;

#pragma mark ACCESSORS

- (JKLibraryWindowController *)libraryWindowController;
- (NSMutableArray *)libraryEntries;
- (void)setLibraryEntries:(NSMutableArray *)array;
- (void)insertObject:(JKLibraryEntry *)libraryEntry inLibraryEntriesAtIndex:(int)index;
- (void)removeObjectFromLibraryEntriesAtIndex:(int)index;

@end
