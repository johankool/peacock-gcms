//
//  JKPathPopUpButton.h
//  Peacock
//
//  Created by Johan Kool on 15-5-06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BDAlias;

@interface JKPathPopUpButton : NSPopUpButton {
//	BOOL includeApplications;
//	BOOL includeDirectories;
//	BOOL includeFiles;
//	
//	BOOL createNewPaths;
//	BOOL chooseExistingPaths;
//	
//	BOOL showChoosePanelAsSheet;
//	
//	BOOL showStandardPaths;
//	BOOL showPathComponents;
//	BOOL showPlaceHolder;
//	
//	NSString *placeHolder;
	NSArray *fileTypes;
//	BDAlias *fileAlias;
	
	NSObject *fileAliasContainer;
    NSString *fileAliasKeyPath;

}

- (NSString *)filePath;

- (void)setupMenu;
- (BDAlias *)fileAlias;
- (void)setFileAlias:(id)inValue;
	
idAccessor_h(fileAliasContainer, setFileAliasContainer)
idAccessor_h(fileAliasKeyPath, setFileAliasKeyPath)

@end
