//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//


@class JKPreferencesWindowController;
@class JKPanelController;
@class MWController;
@class JKBatchProcessWindowController;
//@class JKStatisticsWindowController;

#import <Growl/GrowlApplicationBridge.h>

@interface JKAppDelegate : NSApplication <GrowlApplicationBridgeDelegate> {
    NSWindowController *preferencesWindowController;
	//JKPanelController *panelWindowController;
    IBOutlet MWController *mwWindowController;
	JKBatchProcessWindowController *batchProcessWindowController;
	//JKStatisticsWindowController *statisticsWindowController;
}


#pragma mark ACTIONS
-(IBAction)openPreferencesWindowAction:(id)sender;
//-(IBAction)checkForNewVersion:(id)sender;
//-(void)checkVersion:(BOOL)quiet;
-(IBAction)showReadMe:(id)sender;
-(IBAction)showLicense:(id)sender;
-(IBAction)showBatchProcessAction:(id)sender;
-(IBAction)showStatisticsAction:(id)sender;

#pragma mark GROWL SUPPORT
-(NSDictionary *)registrationDictionaryForGrowl;

@end
