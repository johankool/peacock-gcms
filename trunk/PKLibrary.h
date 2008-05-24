//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "PKTargetObjectProtocol.h"

@class PKLibraryWindowController;
@class PKManagedLibraryEntry;

@interface PKLibrary : NSPersistentDocument {
    PKLibraryWindowController *libraryWindowController;
}
- (BOOL)isMainLibrary;
- (BOOL)isSuperDocumentEdited;

#pragma mark IMPORT/EXPORT ACTIONS
- (void)readJCAMPString:(NSString *)inString;

- (BOOL)importJCAMPFromFile:(NSString *)fileName;
- (BOOL)exportJCAMPToFile:(NSString *)fileName;

//- (BOOL)importAMDISFromFile:(NSString *)fileName;
//- (BOOL)exportAMDISToFile:(NSString *)fileName;
- (BOOL)requiresObjectForPredicateForSearchTemplate:(NSString *)searchTemplateName;
- (NSPredicate *)predicateForSearchTemplate:(NSString *)searchTemplateName andObject:(id <PKTargetObjectProtocol>)targetObject;
- (NSArray *)libraryEntriesWithPredicate:(NSPredicate *)predicate;

#pragma mark ACCESSORS
- (NSArray *)libraryEntries;
- (PKLibraryWindowController *)libraryWindowController;

@property (retain,getter=libraryWindowController) PKLibraryWindowController *libraryWindowController;
@end
