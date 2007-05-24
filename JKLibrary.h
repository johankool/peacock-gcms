//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class JKLibraryWindowController;
@class JKLibraryEntry;

@interface JKLibrary : NSPersistentDocument {
    JKLibraryWindowController *libraryWindowController;
}

#pragma mark IMPORT/EXPORT ACTIONS
- (void)readJCAMPString:(NSString *)inString;

- (BOOL)importJCAMPFromFile:(NSString *)fileName;
- (BOOL)exportJCAMPToFile:(NSString *)fileName;

//- (BOOL)importAMDISFromFile:(NSString *)fileName;
//- (BOOL)exportAMDISToFile:(NSString *)fileName;

#pragma mark ACCESSORS
- (NSArray *)libraryEntries;
- (JKLibraryWindowController *)libraryWindowController;

@end
