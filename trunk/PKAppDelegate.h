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

@class PKBatchProcessWindowController;
@class PKGraphicalController;
@class PKLibrary;
@class PKLibraryEntry;
@class PKLibraryPanelController;
@class PKManagedLibraryEntry;
@class PKMassWeightController;
@class PKPanelController;
@class PKPeakRecord;
@class PKPreferencesWindowController;
@class PKRatiosController;
@class PKSummarizer;
@class PKSummaryController;

@interface PKAppDelegate : NSApplication {
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


#pragma mark IBActions
- (IBAction)openPreferencesWindowAction:(id)sender;
- (IBAction)showReadMe:(id)sender;
- (IBAction)showLicense:(id)sender;
- (IBAction)showOnlineHelp:(id)sender;
- (IBAction)showProductWebsite:(id)sender;
- (IBAction)showBatchProcessAction:(id)sender;
- (IBAction)showStatisticsAction:(id)sender;
- (IBAction)openTestFile:(id)sender;
#pragma mark -

#pragma mark Library Management
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
#pragma mark -

#pragma mark Summary Management
- (PKSummaryController *)summaryController;
- (PKSummarizer *)summarizer;
- (PKRatiosController *)ratiosController;
- (PKGraphicalController *)graphicalController;
#pragma mark -

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

#pragma mark Debug
- (void)printStackTrace:(NSException *)e;
#pragma mark -

#pragma mark Properties
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
#pragma mark -

@end
