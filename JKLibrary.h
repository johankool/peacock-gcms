//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKLibraryWindowController;

@interface JKLibrary : NSDocument {
    JKLibraryWindowController *libraryWindowController;
	NSMutableArray *libraryArray;
}

#pragma mark IMPORT/EXPORT ACTIONS
- (NSArray *)readJCAMPString:(NSString *)inString;

- (BOOL)importJCAMPFromFile:(NSString *)fileName;
- (BOOL)exportJCAMPToFile:(NSString *)fileName;

- (BOOL)importAMDISFromFile:(NSString *)fileName;
- (BOOL)exportAMDISToFile:(NSString *)fileName;

#pragma mark ACCESSORS

- (JKLibraryWindowController *)libraryWindowController;
- (NSMutableArray *)libraryArray;

@end
