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
@class JKLibraryPanelController;
@class JKManagedLibraryEntry;
@class JKPeakRecord;
@class JKSummaryController;
@class JKSummarizer;
@class JKRatiosController;

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
    JKLibraryPanelController *libraryPanelController;
    
    JKSummaryController *summaryController;
    JKRatiosController *ratiosController;
    JKSummarizer *summarizer;
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
- (JKManagedLibraryEntry *)libraryEntryForName:(NSString *)compoundString;

- (NSArray *)autocompleteEntries;
//- (void)setAutocompleteEntries:(NSArray *)aAutocompleteEntries;
//- (NSArray *)autocompleteEntriesForModel:(NSString *)model;

- (JKSummaryController *)summaryController;
- (JKSummarizer *)summarizer;
- (JKRatiosController *)ratiosController;

#pragma mark GROWL SUPPORT
- (NSDictionary *)registrationDictionaryForGrowl;


- (void)printStackTrace:(NSException *)e;

@property (retain) NSWindowController *preferencesWindowController;
@property (retain) JKBatchProcessWindowController *batchProcessWindowController;
@property (retain) NSTableView *documentListTableView;
@property (retain,getter=summarizer) JKSummarizer *summarizer;
@property (retain) NSString *libraryConfigurationLoaded;
@property (retain) NSMenu *showPresetMenu;
@property (retain) NSPanel *documentListPanel;
@property (retain,getter=library) JKLibrary *library;
@property (retain) NSMenu *removeChromatogramMenu;
@property (retain) MWController *mwWindowController;
@property (retain) NSWindow *welcomeWindow;
@property (retain) NSMenu *viewColumnsMenu;
@end
