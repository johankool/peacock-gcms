//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
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
