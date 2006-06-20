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
    IBOutlet NSMenu *showPresetMenu;
    IBOutlet NSMenu *removeChromatogramMenu;
	IBOutlet MWController *mwWindowController;

    NSWindowController *preferencesWindowController;
	JKBatchProcessWindowController *batchProcessWindowController;

}


#pragma mark IBACTIONS
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)showReadMe:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)showBatchProcessAction:(id)sender;
- (IBAction)showStatisticsAction:(id)sender;

#pragma mark GROWL SUPPORT
- (NSDictionary *)registrationDictionaryForGrowl;

@end
