//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//


@class JKPreferencesWindowController;
@class JKPanelController;
@class MWController;
@class JKBatchProcessWindowController;
@class JKLibrary;
@class JKLibraryEntry;
@class JKManagedLibraryEntry;
@class JKPeakRecord;

#import <Growl/GrowlApplicationBridge.h>

@interface JKAppDelegate : NSApplication <GrowlApplicationBridgeDelegate> {
    IBOutlet NSMenu *showPresetMenu;
    IBOutlet NSMenu *removeChromatogramMenu;
	IBOutlet MWController *mwWindowController;
    IBOutlet NSWindow *welcomeWindow;
    IBOutlet NSMenu *viewColumnsMenu;
    IBOutlet NSTableView *documentListTableView;
    IBOutlet NSPanel *documentListPanel;
        
    NSWindowController *preferencesWindowController;
	JKBatchProcessWindowController *batchProcessWindowController;
    JKLibrary *library;
    NSMutableArray *availableDictionaries;
    NSString *libraryConfigurationLoaded;
    NSArray *autocompleteEntries;
}


#pragma mark IBACTIONS
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)showReadMe:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)showBatchProcessAction:(id)sender;
- (IBAction)showStatisticsAction:(id)sender;
- (IBAction)openTestFile:(id)sender;
- (IBAction)showDocumentList:(id)sender;

- (void)showInFinder;
- (JKLibrary *)library;
- (JKLibrary *)libraryForConfiguration:(NSString *)libraryConfiguration;
- (void)loadLibraryForConfiguration:(NSString *)configuration;
- (BOOL)shouldLoadLibrary:(NSString *)fileName forConfiguration:(NSString *)configuration;
- (JKManagedLibraryEntry *)addLibraryEntryBasedOnPeak:(JKPeakRecord *)aPeak;
- (JKLibraryEntry *)libraryEntryForName:(NSString *)compoundString;

#pragma mark GROWL SUPPORT
- (NSDictionary *)registrationDictionaryForGrowl;

@end
