//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//


@class PKPreferencesWindowController;
@class PKPanelController;
@class PKMassWeightController;
@class PKBatchProcessWindowController;
@class PKLibrary;
@class PKLibraryEntry;
@class PKLibraryPanelController;
@class PKManagedLibraryEntry;
@class PKPeakRecord;
@class PKSummaryController;
@class PKSummarizer;
@class PKRatiosController;
@class PKGraphicalController;

#import <Growl/GrowlApplicationBridge.h>

@interface PKAppDelegate : NSApplication <GrowlApplicationBridgeDelegate> {
    IBOutlet NSMenu *showPresetMenu;
    IBOutlet NSMenu *removeChromatogramMenu;
    IBOutlet NSWindow *welcomeWindow;
    IBOutlet NSMenu *viewColumnsMenu;
        
    // Window controllers
   	IBOutlet PKMassWeightController *mwWindowController;
    NSWindowController *preferencesWindowController;
	PKBatchProcessWindowController *batchProcessWindowController;
    PKSummaryController *summaryController;
    PKRatiosController *ratiosController;
    PKGraphicalController *graphicalController;
    
    // Summary
    PKSummarizer *summarizer;
    
    // Libraries
    PKLibrary *library;
    NSMutableArray *availableDictionaries;
    NSString *libraryConfigurationLoaded;
    NSArray *autocompleteEntries;
    PKLibraryPanelController *libraryPanelController;
    
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
- (PKLibrary *)library;
- (PKLibrary *)libraryForConfiguration:(NSString *)libraryConfiguration;
- (void)loadLibraryForConfiguration:(NSString *)configuration;
- (BOOL)shouldLoadLibrary:(NSString *)fileName forConfiguration:(NSString *)configuration;
- (PKManagedLibraryEntry *)addLibraryEntryBasedOnPeak:(PKPeakRecord *)aPeak;
- (PKManagedLibraryEntry *)addLibraryEntryBasedOnJCAMPString:(NSString *)jcampString;
- (PKManagedLibraryEntry *)libraryEntryForName:(NSString *)compoundString;

- (IBAction)editLibrary:(id)sender;
- (NSArray *)autocompleteEntries;
//- (void)setAutocompleteEntries:(NSArray *)aAutocompleteEntries;
//- (NSArray *)autocompleteEntriesForModel:(NSString *)model;

- (PKSummaryController *)summaryController;
- (PKSummarizer *)summarizer;
- (PKRatiosController *)ratiosController;
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
@property (retain) PKBatchProcessWindowController *batchProcessWindowController;
@property (retain,getter=summarizer) PKSummarizer *summarizer;
@property (retain) NSString *libraryConfigurationLoaded;
@property (retain) NSMenu *showPresetMenu;
@property (retain,getter=library) PKLibrary *library;
@property (retain) NSMenu *removeChromatogramMenu;
@property (retain) PKMassWeightController *mwWindowController;
@property (retain) NSWindow *welcomeWindow;
@property (retain) NSMenu *viewColumnsMenu;
@end
