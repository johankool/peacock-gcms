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
@class PKGraphicalController;

#import <Growl/GrowlApplicationBridge.h>

@interface JKAppDelegate : NSApplication <GrowlApplicationBridgeDelegate> {
    IBOutlet NSMenu *showPresetMenu;
    IBOutlet NSMenu *removeChromatogramMenu;
    IBOutlet NSWindow *welcomeWindow;
    IBOutlet NSMenu *viewColumnsMenu;
        
    // Window controllers
   	IBOutlet MWController *mwWindowController;
    NSWindowController *preferencesWindowController;
	JKBatchProcessWindowController *batchProcessWindowController;
    JKSummaryController *summaryController;
    JKRatiosController *ratiosController;
    PKGraphicalController *graphicalController;
    
    // Summary
    JKSummarizer *summarizer;
    
    // Libraries
    JKLibrary *library;
    NSMutableArray *availableDictionaries;
    NSString *libraryConfigurationLoaded;
    NSArray *autocompleteEntries;
    JKLibraryPanelController *libraryPanelController;
    
    // PlugIns
    NSMutableDictionary *baselineDetectionMethods;
    NSMutableDictionary *peakDetectionMethods;
    NSMutableDictionary *spectraMatchingMethods;
}


#pragma mark IBACTIONS
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)showReadMe:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)showBatchProcessAction:(id)sender;
- (IBAction)showStatisticsAction:(id)sender;
- (IBAction)openTestFile:(id)sender;

- (void)showInFinder;
- (JKLibrary *)library;
- (JKLibrary *)libraryForConfiguration:(NSString *)libraryConfiguration;
- (void)loadLibraryForConfiguration:(NSString *)configuration;
- (BOOL)shouldLoadLibrary:(NSString *)fileName forConfiguration:(NSString *)configuration;
- (JKManagedLibraryEntry *)addLibraryEntryBasedOnPeak:(JKPeakRecord *)aPeak;
- (JKManagedLibraryEntry *)libraryEntryForName:(NSString *)compoundString;

- (IBAction)editLibrary:(id)sender;
- (NSArray *)autocompleteEntries;
//- (void)setAutocompleteEntries:(NSArray *)aAutocompleteEntries;
//- (NSArray *)autocompleteEntriesForModel:(NSString *)model;

- (JKSummaryController *)summaryController;
- (JKSummarizer *)summarizer;
- (JKRatiosController *)ratiosController;
- (PKGraphicalController *)graphicalController;

#pragma mark Plugins
- (void)loadAllPlugins;
- (NSMutableArray *)allBundles;
- (BOOL)plugInClassIsValid:(Class)plugInClass;
- (NSArray *)baselineDetectionMethodNames;
- (NSArray *)peakDetectionMethodNames;
- (NSArray *)spectraMatchingMethodNames;
- (NSDictionary *)baselineDetectionMethods;
- (NSDictionary *)peakDetectionMethods;
- (NSDictionary *)spectraMatchingMethods;
#pragma mark -

#pragma mark GROWL SUPPORT
- (NSDictionary *)registrationDictionaryForGrowl;
#pragma mark -

- (void)printStackTrace:(NSException *)e;

@property (retain) NSWindowController *preferencesWindowController;
@property (retain) JKBatchProcessWindowController *batchProcessWindowController;
@property (retain,getter=summarizer) JKSummarizer *summarizer;
@property (retain) NSString *libraryConfigurationLoaded;
@property (retain) NSMenu *showPresetMenu;
@property (retain,getter=library) JKLibrary *library;
@property (retain) NSMenu *removeChromatogramMenu;
@property (retain) MWController *mwWindowController;
@property (retain) NSWindow *welcomeWindow;
@property (retain) NSMenu *viewColumnsMenu;
@end
