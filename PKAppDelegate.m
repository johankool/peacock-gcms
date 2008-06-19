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

#import "PKAppDelegate.h"

#import "PKBatchProcessWindowController.h"
#import "PKBooleanToStringTransformer.h"
#import "PKDocumentController.h"
#import "PKGCMSDocument.h"
#import "PKGraphicalController.h"
#import "PKLibrary.h"
#import "PKLibraryEntry.h"
#import "PKLibraryPanelController.h"
#import "PKLog.h"
#import "PKMainWindowController.h"
#import "PKManagedLibraryEntry.h"
#import "PKPanelController.h"
#import "PKPeakRecord.h"
#import "PKPluginProtocol.h"
#import "PKPreferencesWindowController.h"
#import "PKRatiosController.h"
#import "PKSummarizer.h"
#import "PKSummaryController.h"
#import <ExceptionHandling/NSExceptionHandler.h>

// Name of the application support folders and extenstion of library
static NSString * SUPPORT_FOLDER_NAME = @"Peacock";
static NSString * LIBRARY_FOLDER_NAME = @"Libraries";
static NSString * LIBRARY_EXTENSION = @"peacock-library";

@implementation PKAppDelegate

#pragma mark Initialisation and deallocation
+ (void)initialize {
	// Register default settings
	NSMutableDictionary *defaultValues = [NSMutableDictionary new];
	
	// Application level prefences
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"skipWelcomeDialog"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"showInspectorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"showMassCalculatorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"showLibraryPanelOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"autoSave"];
	[defaultValues setValue:[NSNumber numberWithInt:10] forKey:@"autoSaveDelay"]; 
	
	// Default preferences for initial document settings
	[defaultValues setValue:[NSNumber numberWithInt:30] forKey:@"baselineWindowWidth"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.05f] forKey:@"baselineDistanceThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.005f] forKey:@"baselineSlopeThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.5f] forKey:@"baselineDensityThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.1f] forKey:@"peakIdentificationThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:1.0f] forKey:@"retentionIndexSlope"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.0f] forKey:@"retentionIndexRemainder"];
	[defaultValues setValue:NSLocalizedString(@"All",@"") forKey:@"libraryConfiguration"];
	[defaultValues setValue:NSLocalizedString(@"All",@"") forKey:@"searchTemplate"];
	[defaultValues setValue:[[NSString stringWithString:@"~/Desktop/Test Library.jdx"] stringByExpandingTildeInPath] forKey:@"libraryAlias"];
	[defaultValues setValue:[NSNumber numberWithInt:JKAbundanceScoreBasis] forKey:@"scoreBasis"]; // Using formula 1 in Gan 2001
	[defaultValues setValue:[NSNumber numberWithInt:JKForwardSearchDirection] forKey:@"searchDirection"];
	[defaultValues setValue:[NSNumber numberWithInt:PKSpectrumSearchSpectrum] forKey:@"spectrumToUse"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"penalizeForRetentionIndex"];
	[defaultValues setValue:[NSNumber numberWithFloat:75.0f] forKey:@"markAsIdentifiedThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:50.0f] forKey:@"minimumScoreSearchResults"];
	[defaultValues setValue:[NSNumber numberWithFloat:45.0f] forKey:@"minimumScannedMassRange"];
	[defaultValues setValue:[NSNumber numberWithFloat:650.0f] forKey:@"maximumScannedMassRange"];
	[defaultValues setValue:[NSNumber numberWithFloat:200.0f] forKey:@"maximumRetentionIndexDifference"];

	// Default presets
	[defaultValues setObject:[NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:@"Alkanes",@"name",@"57+71",@"massValue",nil],
        [NSDictionary dictionaryWithObjectsAndKeys:@"Alkenes",@"name",@"55+69",@"massValue",nil],
        [NSDictionary dictionaryWithObjectsAndKeys:@"Fatty acids",@"name",@"129+185",@"massValue",nil],
        [NSDictionary dictionaryWithObjectsAndKeys:@"Methylketones",@"name",@"58+59",@"massValue",nil],
        nil] forKey:@"presets"];

    // Default ratios
    [defaultValues setObject:[NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:@"Example Ratio",@"label",@"[Compound A]/[Compound B]*100%",@"formula",nil],
         nil] forKey:@"ratios"];
    
	// Default summary settings
    // Default statistics analysis
	[defaultValues setValue:[NSNumber numberWithInt:3] forKey:@"statisticsAnalysisPeaksForSummary"]; // confirmed peaks
	[defaultValues setValue:[NSNumber numberWithInt:1] forKey:@"statisticsAnalysisColumnSorting"]; // Samplecode
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"statisticsAnalysisPenalizeForRetentionIndex"];
	[defaultValues setValue:[NSNumber numberWithFloat:75.0] forKey:@"statisticsAnalysisMatchThreshold"];
	[defaultValues setValue:[NSNumber numberWithInt:0] forKey:@"statisticsAnalysisScoreBasis"]; // Using formula 1 in Gan 2001
	
	// Default batch settings
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"batchDeleteCurrentPeaksFirst"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"batchIdentifyBaseline"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"batchIdentifyPeaks"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"batchIdentifyCompounds"];
	[defaultValues setValue:[NSNumber numberWithInt:0] forKey:@"batchUseSettings"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"batchSaveAsPeacockFile"];

    // Default graph view settings
    [defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"shouldDrawAxes"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawAxesHorizontal"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawAxesVertical"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawFrame"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawFrameLeft"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawFrameBottom"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawMajorTickMarks"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawMinorTickMarks"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawGrid"];
    [defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"shouldDrawLabels"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawLegend"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawLabelsOnFrame"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawShadow"];
  
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor clearColor]] forKey:@"backColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:@"plottingAreaColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"axesColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor clearColor]] forKey:@"frameColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor gridColor]] forKey:@"gridColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"labelsColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor blackColor]] forKey:@"labelsOnFrameColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:@"legendAreaColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]] forKey:@"legendFrameColor"];
    [defaultValues setValue:[NSArchiver archivedDataWithRootObject:[NSColor greenColor]] forKey:@"baselineColor"];
				
    // Additions to PKGraphView for Peacock
    [defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"shouldDrawBaseline"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawPeaks"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"drawLabelsAlways"];
    
	// Hidden preference for logging verbosity
	[defaultValues setValue:[NSNumber numberWithInt:JK_VERBOSITY_INFO] forKey:@"JKVerbosity"];
	
    // Set initial values
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
	[defaultValues release];
}

- (id)init {
	self = [super init];
	if (self != nil) {
        // Set ourselves as the app delegate
        [self setDelegate:self];
        
        // Create and register font name value transformer
        NSValueTransformer *transformer = [[PKBooleanToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"BooleanToStringTransformer"];
                
        availableDictionaries = [[NSMutableArray alloc] init];
        autocompleteEntries = [[NSArray alloc] init];
        libraryConfigurationLoaded = [@"" retain];
     
        summarizer = [[PKSummarizer alloc] init];
        baselineDetectionMethods = [[NSMutableDictionary alloc] init];
        peakDetectionMethods = [[NSMutableDictionary alloc] init];        
        spectraMatchingMethods = [[NSMutableDictionary alloc] init];
        
        [[NSExceptionHandler defaultExceptionHandler] setDelegate:self];
        [[NSExceptionHandler defaultExceptionHandler] setExceptionHandlingMask:NSHandleOtherExceptionMask];
	}
	return self;
}

- (void)dealloc {
    // Release objects
    [availableDictionaries release];
    [autocompleteEntries release];
    [libraryConfigurationLoaded release];
    
    [summarizer release];
    [baselineDetectionMethods release]; 
    [peakDetectionMethods release];
    [spectraMatchingMethods release];
    
    [super dealloc];
}
#pragma mark -

#pragma mark Delegate Methods
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    // Delegate method per NSApplication to suppress or allow untitled window at launch.
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {	
	// Execute startup preferences
    
    // Custom level debug verbosity
    JKSetVerbosityLevel([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"JKVerbosity"] intValue]);
    
#warning [BUG] Auto-save disabled
    // Auto-save doesn't seem to work because it seems to get confused about the file-type it should use to save the file
    
//    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSave"] boolValue] == YES) {
//        [[NSDocumentController sharedDocumentController] setAutosavingDelay:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSaveDelay"] intValue]*60];
//    } else {
//        [[NSDocumentController sharedDocumentController] setAutosavingDelay:0];
//    }
	
    // Show inspector panel
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showInspectorOnLaunch"] boolValue] == YES) {
        [[PKPanelController sharedController] showInspector:self];
    } else {
		[PKPanelController sharedController]; // Just so it's initiated in time to register for notifications
	}
	
    // Show mass calculator
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showMassCalculatorOnLaunch"] boolValue] == YES) {
        [mwWindowController showWindow:self];
    } 
     
    // Make the main window main 
    [[[PKDocumentController sharedDocumentController] window] makeKeyAndOrderFront:self];

    // Show welcome window
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"skipWelcomeDialog"] boolValue] == NO) {
        [welcomeWindow center];
        [welcomeWindow makeKeyAndOrderFront:self];
    }	
       
    // Load plugins
    [self loadAllPlugins];
        
    // Load library configuration
    [self loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"libraryConfiguration"]];
    
    // Show library panel
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showLibraryPanelOnLaunch"] boolValue] == YES) {
        [[PKLibraryPanelController sharedController] showInspector:self];
    }    
 
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    // Prevent user from accidentally closing Peacock when he has files open
    if ([[[PKDocumentController sharedDocumentController] documents] count] > 0) {
        NSString *msgString;
        if ([[[PKDocumentController sharedDocumentController] documents] count] == 1) {
            msgString = [NSString localizedStringWithFormat:NSLocalizedString(@"There is one document open in Peacock. Do you want to quit anyway?", @"")];
        } else {
            msgString = [NSString localizedStringWithFormat:NSLocalizedString(@"There are %d documents open in Peacock. Do you want to quit anyway?", @""),[[[PKDocumentController sharedDocumentController] documents] count]];            
        }
        int answer = NSRunAlertPanel(@"Are you sure you want to quit Peacock?", msgString, @"Quit",@"Cancel",nil);
        if (answer == NSCancelButton) {
            return NSTerminateCancel;
        } else {
            return NSTerminateNow;
        }
    }
    return NSTerminateNow;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Save changes made to the library
    if ([library isSuperDocumentEdited]) {
        PKLogInfo(@"Saving library...");
        [[library managedObjectContext] save:NULL];
    }
}
#pragma mark  -

#pragma mark IBActions
- (IBAction)openPreferencesWindowAction:(id)sender {
    if (!preferencesWindowController) {
        preferencesWindowController = [[PKPreferencesWindowController alloc] init];
    }
    [preferencesWindowController showWindow:self];
}

- (IBAction)showInspector:(id)sender {
    [[PKPanelController sharedController] showInspector:self];
}

- (IBAction)showLibraryPanel:(id)sender {
    [[PKLibraryPanelController sharedController] showInspector:self];
}

- (IBAction)showReadMe:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Credits" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

- (IBAction)showLicense:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

- (IBAction)showOnlineHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://johankool.nl/software/peacock/documentation/"]];
}

- (IBAction)showProductWebsite:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://johankool.nl/software/peacock/"]];
}


//- (IBAction)showLicenses:(id)sender {
//    [[PKLicenseController sharedController] showLicenses:self];
//}

- (IBAction)showBatchProcessAction:(id)sender {
	if (!batchProcessWindowController) {
        batchProcessWindowController = [[PKBatchProcessWindowController alloc] init];
    }
    [batchProcessWindowController showWindow:self];	
}

- (IBAction)showStatisticsAction:(id)sender {
	if (!summaryController) {
        summaryController = [[PKSummaryController alloc] init];
    }
    [summaryController showWindow:self];	
}

- (PKSummaryController *)summaryController {
    if (!summaryController) {
        summaryController = [[PKSummaryController alloc] init];
    }
    return summaryController;
}

- (PKRatiosController *)ratiosController {
    if (!ratiosController) {
        ratiosController = [[PKRatiosController alloc] init];
    }
    return ratiosController;
}

- (PKGraphicalController *)graphicalController {
    if (!graphicalController) {
        graphicalController = [[PKGraphicalController alloc] init];
    }
    return graphicalController;
}

- (IBAction)openTestFile:(id)sender {
    // Copies test files to the desktop for users wanting to explore Peacock without data at hand
    NSString *desktopDirectory;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)  {
        desktopDirectory = [paths objectAtIndex:0];
    } else {
        PKLogError(@"Cannot locate desktop directory");
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[desktopDirectory stringByAppendingPathComponent:@"Peacock Test Files"]]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[desktopDirectory stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]]) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[desktopDirectory stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]] display:YES error:NULL];
            [welcomeWindow orderOut:self];
            return;
        }
        
        NSRunAlertPanel(@"Folder already exists",@"A folder with the name \"Peacock Test Files\" already exists on your desktop.",@"OK",nil,nil);
        return;
    }
    if (![[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Peacock Test Files"] toPath:[desktopDirectory stringByAppendingPathComponent:@"Peacock Test Files"] handler:nil]) {
         NSRunAlertPanel(@"Error during copying of folder",@"An error occurred during the copying of the folder with the name \"Peacock Test Files\" to your desktop.",@"OK",nil,nil);
    }
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[desktopDirectory stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]] display:YES error:NULL];
    
    [welcomeWindow orderOut:self];
}

- (void)runPageLayout:(id)sender {
    NSPageLayout *pl = [NSPageLayout pageLayout];
    NSPrintInfo *printInfo = [NSPrintInfo sharedPrintInfo];
    if ([pl runModalWithPrintInfo:printInfo] == NSOKButton) {
        [NSPrintInfo setSharedPrintInfo:printInfo];
        [[self graphicalController] sharedPrintInfoUpdated];
    }
}
#pragma mark  -

#pragma mark Interface validation
- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
    if ([NSApp modalWindow]) { // Disable menuitems because they cause a crash when running the modal registration window + its *MODAL*! anyway
        return NO;
    }
	if ([anItem action] == @selector(showInspector:)) {
		if ([[[PKPanelController sharedController] window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Inspector",@"Menutitle when inspector is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Inspector",@"Menutitle when inspector is not visible")];
		}			
		return YES;
    } else if ([anItem action] == @selector(showLibraryPanel:)) {
		if ([[[PKLibraryPanelController sharedController] window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Library Panel",@"Menutitle when Library Panel is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Library Panel",@"Menutitle when Library Panel is not visible")];
		}			
		return YES;
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

- (int)numberOfItemsInMenu:(NSMenu *)menu{
	if (menu == showPresetMenu) {
		return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] count];
	} else if (menu == removeChromatogramMenu) {
		id currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
		if ((currentDocument != nil) && ([currentDocument isKindOfClass:[PKGCMSDocument class]])) {
			return [[currentDocument chromatograms] count]-1;
		}
	}
	return 0;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)x shouldCancel:(BOOL)shouldCancel{
	if (menu == showPresetMenu) {
		id preset = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] objectAtIndex:x];
		if (![preset valueForKey:@"name"]) {
			[item setTitle:@"No name"];
		} else {
			[item setTitle:[preset valueForKey:@"name"]];			
		}
		[item setTag:x];
		[item setAction:@selector(showPreset:)];
		if (x < 9) {
			[item setKeyEquivalentModifierMask:NSCommandKeyMask];
			[item setKeyEquivalent:[NSString stringWithFormat:@"%d",x+1]];			
		}
		return YES;
	} else if (menu == removeChromatogramMenu) {
		id currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
		if ((currentDocument != nil) && ([currentDocument isKindOfClass:[PKGCMSDocument class]])) {
			[item setTitle:[[[currentDocument chromatograms] objectAtIndex:x+1] valueForKey:@"model"]];
			[item setTag:x+1];
			[item setAction:@selector(removeChromatogram:)];
			return YES;
		}
	} 
	return NO;
}
#pragma mark -

#pragma mark Library Management
- (void)showInFinder {
    // Open up the default store
    NSArray *searchpaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([searchpaths count] > 0) {        
        // Look for the Peacock support folder (and create if not there)
        NSString *path = [[searchpaths objectAtIndex:0] stringByAppendingPathComponent: SUPPORT_FOLDER_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path attributes:nil];
        }
        
        // Look for the library folder (and create if not there)
        path = [path stringByAppendingPathComponent: LIBRARY_FOLDER_NAME];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path attributes:nil];
        }
        [[NSWorkspace sharedWorkspace] selectFile:path inFileViewerRootedAtPath:path];
    } else {
        NSBeep();
    }        
}

- (void)loadLibraryForConfiguration:(NSString *)configuration {
    if ([libraryConfigurationLoaded isEqualToString:configuration]) {
        PKLogDebug(@"Loading configuration %@ ignored (already current configuration)",configuration);
    	return;
    }
        
    PKLogDebug(@"configuration %@",configuration);
    [self willChangeValueForKey:@"library"];
    [self willChangeValueForKey:@"availableDictionaries"];
    [self willChangeValueForKey:@"availableConfigurations"];
    
    if (!library) {
        library = [[PKLibrary alloc] init];
    } else {
        [library close];
        library = [[PKLibrary alloc] init];
        [availableDictionaries removeAllObjects];
    }
    
    // open up the default store
    NSArray *searchpaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    if ([searchpaths count] > 0) {
        
        // look for the Peacock support folder (and create if not there)
        NSString *path = [[searchpaths objectAtIndex:0] stringByAppendingPathComponent: SUPPORT_FOLDER_NAME];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path attributes:nil];
        }
        
        // look for the library folder (and create if not there)
        path = [path stringByAppendingPathComponent: LIBRARY_FOLDER_NAME];
        if (![fileManager fileExistsAtPath:path]) {
            [fileManager createDirectoryAtPath:path attributes:nil];
        }
        
        NSString *file;
        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
        int count = 0;
        int loadedCount = 0;
        while ((file = [dirEnum nextObject])) {
            if ([[file pathExtension] isEqualToString:LIBRARY_EXTENSION]) {// || [[file pathExtension] isEqualToString: @"jdx"] ||[[file pathExtension] isEqualToString: @"hpj"]
                count++;
                if ([self shouldLoadLibrary:[file stringByDeletingPathExtension] forConfiguration:configuration]) {
                    if (![[[library managedObjectContext] persistentStoreCoordinator] addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:file]] options:nil error:nil]) {
                        PKLogError(@"Can't add '%@' to library persistent store coordinator.", file);
                    } else {
                        loadedCount++;
                        PKLogInfo(@"Loaded Library %@",[file stringByDeletingPathExtension]);
                    }
                }
                [availableDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[path stringByAppendingPathComponent:file], @"path", [file stringByDeletingPathExtension], @"name", nil]];
            }
            if ([[file pathExtension] isEqualToString: @"jdx"] ||[[file pathExtension] isEqualToString: @"hpj"]) {
                NSRunAlertPanel(NSLocalizedString(@"Library not in Peacock-Library format",@""),NSLocalizedString(@"Libraries should be stored in the Peacock-Library format in order for Peacock to be able to use it for identifying compounds. You can open the JCAMP-file in Peacock and save the file as a Peacock Library.",@""),@"OK",nil,nil);
            }
        }
        
        if (![configuration isEqualToString:@""]) { // Empty string used to force reload, but should not load anything or cause creation of default library
            if (count == 0) {            
                PKLogWarning(@"No libraries found.");
                NSPersistentStoreCoordinator *psc = [[library managedObjectContext] persistentStoreCoordinator];
                if (![psc addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:[NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"Default.peacock-library"]] options:nil error:nil]) {
                    PKLogError(@"Default Library could not be created.");
                } else {
                    [availableDictionaries addObject:[NSDictionary dictionaryWithObjectsAndKeys:[path stringByAppendingPathComponent:@"Default.peacock-library"], @"path", @"Default", @"name", nil]];
                    PKLogInfo(@"Loaded Library Default");
                    loadedCount++;
                }
            }
            if (loadedCount == 0 && ![configuration isEqualToString:@"None"]) { 
                NSRunAlertPanel(NSLocalizedString(@"No Libraries could be opened or created",@""),NSLocalizedString(@"This is not good. Identifying compounds isn't going to work.",@""),@"OK, I guess...",nil,nil);
            }        
        }
    }        
        
    // Store configuration
    [libraryConfigurationLoaded release];
    [configuration retain];
    libraryConfigurationLoaded = configuration;
    [self didChangeValueForKey:@"library"];
    [self didChangeValueForKey:@"availableDictionaries"];
    [self didChangeValueForKey:@"availableConfigurations"];
}

- (PKLibrary *)libraryForConfiguration:(NSString *)libraryConfiguration {
    PKLogDebug(@"libraryConfigurationLoaded %@",libraryConfigurationLoaded);
    PKLogDebug(@"libraryConfiguration %@",libraryConfiguration);
    
    if (![libraryConfiguration isEqualToString:libraryConfigurationLoaded]) {
        if ([library isDocumentEdited])
            [[library managedObjectContext] save:NULL];

        [self loadLibraryForConfiguration:libraryConfiguration];
    }
    return library;
}

- (PKLibrary *)library {
    return library;
}

- (BOOL)shouldLoadLibrary:(NSString *)fileName forConfiguration:(NSString *)configuration {
    if ([configuration isEqualToString:NSLocalizedString(@"All",@"")]) {
        return YES;
    } else if ([configuration isEqualToString:fileName]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSArray *)availableDictionaries {
    return availableDictionaries;
}

- (NSArray *)availableConfigurations {
    return [[NSArray arrayWithObject:NSLocalizedString(@"All",@"")] arrayByAddingObjectsFromArray:[availableDictionaries valueForKey:@"name"]];
}

- (PKManagedLibraryEntry *)addLibraryEntryBasedOnPeak:(PKPeakRecord *)aPeak {
    NSString *path = nil;
    PKManagedLibraryEntry *libEntry = nil;
    int answer = NSRunAlertPanel(NSLocalizedString(@"Peak without library hit being confirmed",@""),NSLocalizedString(@"You are confirming a peak for which you do not have a library hit. Do you want to store your identification as a library entry so it can be used for future compound identifications? ",@""),@"Add Library Entry",@"Cancel",nil);
    if (answer == NSOKButton) {
        libEntry = [NSEntityDescription insertNewObjectForEntityForName:@"JKManagedLibraryEntry" inManagedObjectContext:[library managedObjectContext]];
        NSString *defaultLibrary = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibraryForNewEntries"];
        NSArray *searchpaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([searchpaths count] > 0) {
            // look for the Peacock support folder (and create if not there)
            path = [[[[searchpaths objectAtIndex:0] stringByAppendingPathComponent: SUPPORT_FOLDER_NAME] stringByAppendingPathComponent: LIBRARY_FOLDER_NAME] stringByAppendingPathComponent:[defaultLibrary stringByAppendingPathExtension:LIBRARY_EXTENSION]];
        } else {
            return nil;
        }      
        PKLogInfo(@"Saving new library entry to %@", path);
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            id persistentStore = [[[library managedObjectContext] persistentStoreCoordinator] persistentStoreForURL:[NSURL fileURLWithPath:path]];
            if (persistentStore) {
                [[library managedObjectContext] assignObject:libEntry toPersistentStore:persistentStore];            
            }
        } else {
            PKLogError(@"Saving new library entry to '%@' failed. No such library exists.", path);
        }
        [libEntry setJCAMPString:[[aPeak libraryEntryRepresentation] jcampString]];
        return libEntry; 
    } else {
        return nil;
    }
}

- (PKManagedLibraryEntry *)addLibraryEntryBasedOnJCAMPString:(NSString *)jcampString {
    NSString *path = nil;
    PKManagedLibraryEntry *libEntry = nil;
    int answer = NSRunAlertPanel(NSLocalizedString(@"Unknown library entry encountered",@""),NSLocalizedString(@"The document refers to a library entry that is not or no longer in you libraries. Should it be added to your default library?",@""),@"Add to Library",@"Cancel",nil);
    if (answer == NSOKButton) {
        libEntry = [NSEntityDescription insertNewObjectForEntityForName:@"JKManagedLibraryEntry" inManagedObjectContext:[library managedObjectContext]];
        NSString *defaultLibrary = [[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibraryForNewEntries"];
        NSArray *searchpaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        if ([searchpaths count] > 0) {
            // look for the Peacock support folder (and create if not there)
            path = [[[[searchpaths objectAtIndex:0] stringByAppendingPathComponent: SUPPORT_FOLDER_NAME] stringByAppendingPathComponent: LIBRARY_FOLDER_NAME] stringByAppendingPathComponent:[defaultLibrary stringByAppendingPathExtension:LIBRARY_EXTENSION]];
        } else {
            return nil;
        }      
        PKLogInfo(@"Saving new library entry to %@", path);
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            id persistentStore = [[[library managedObjectContext] persistentStoreCoordinator] persistentStoreForURL:[NSURL fileURLWithPath:path]];
            if (persistentStore) {
                [[library managedObjectContext] assignObject:libEntry toPersistentStore:persistentStore];            
            }
        } else {
            PKLogError(@"Saving new library entry to '%@' failed. No such library exists.", path);
        }
        [libEntry setJCAMPString:jcampString];
        return libEntry;     
    } else {
        return nil;
    }
}

- (IBAction)editLibrary:(id)sender {
    [self loadLibraryForConfiguration:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"libraryConfiguration"]];
    if (![[[NSDocumentController sharedDocumentController] documents] containsObject:[self library]]) {        
        [[NSDocumentController sharedDocumentController] addDocument:[self library]];
    }
    if ([[[self library] windowControllers] count] == 0) {
        [[self library] makeWindowControllers];
    }
    [[self library] setFileName:NSLocalizedString(@"Peacock Library",@"")];
    [[self library] showWindows];
}

- (PKManagedLibraryEntry *)libraryEntryForName:(NSString *)compoundString {
    // Note that this returns the first match only and ignores that a compound may occur more than once in a library
    NSArray *libraryEntries = [library libraryEntries];
    
    for (PKManagedLibraryEntry *managedLibEntry in libraryEntries) {
    	if ([managedLibEntry isCompound:compoundString]) {
            return managedLibEntry;
        }
    }
    return nil;
}

- (NSArray *)autocompleteEntries {
    return [[summarizer combinedPeaks] valueForKey:@"label"];
}
#pragma mark -

#pragma mark Plugins

NSString *ext = @"peacock-plugin"; 
NSString *appSupportSubpath = @"Peacock/PlugIns"; 

- (void)loadAllPlugins { 
    [self willChangeValueForKey:@"baselineDetectionMethodNames"];
    [self willChangeValueForKey:@"peakDetectionMethodNames"]; 
    [self willChangeValueForKey:@"spectraMatchingMethodNames"];
    
    NSMutableArray *bundlePaths; 
    NSEnumerator *pathEnum; 
    NSString *currPath; 
    NSBundle *currBundle; 
    Class currPrincipalClass; 
    id currInstance; 
    bundlePaths = [NSMutableArray array]; 
    [bundlePaths addObjectsFromArray:[self allBundles]]; 
    pathEnum = [bundlePaths objectEnumerator]; 
    while (currPath = [pathEnum nextObject]) { 
        currBundle = [NSBundle bundleWithPath:currPath]; 
        NSError *error = nil;
        if (![currBundle loadAndReturnError:&error]) {
            [self presentError:error];
            continue;
        }
        [error release];
        if(currBundle) { 
            currPrincipalClass = [currBundle principalClass]; 
            if (currPrincipalClass && 
               [self plugInClassIsValid:currPrincipalClass]) { // Validation { 
                currInstance = [[currPrincipalClass alloc] init]; 
                if (currInstance) { 
                    PKLogDebug(@"Plugin started loading: %@",currBundle);
                    NSString *methodName;
                    for (methodName in [currInstance baselineDetectionMethodNames]) {
                        [baselineDetectionMethods setObject:currInstance forKey:methodName];
                    }
                    for (methodName in [currInstance peakDetectionMethodNames]) {
                        [peakDetectionMethods setObject:currInstance forKey:methodName];
                    }
                    for (methodName in [currInstance spectraMatchingMethodNames]) {
                        [spectraMatchingMethods setObject:currInstance forKey:methodName];
                    }
                 } else {
                     error = [[[NSError alloc] initWithDomain:@"Peacock" code:800 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Plugin failed to initialize", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
                    [self presentError:error];
                }
            } else {
                error = [[[NSError alloc] initWithDomain:@"Peacock" code:801 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Invalid Plugin", NSLocalizedDescriptionKey, @"", NSLocalizedFailureReasonErrorKey, @"This plugin is not recognized by Peacock.", NSLocalizedRecoverySuggestionErrorKey, nil]] autorelease];
                [self presentError:error];
           }
        }
    } 
    PKLogDebug(@"baselineDetectionMethods: %@", [self baselineDetectionMethodNames]);
    PKLogDebug(@"peakDetectionMethods: %@", [self peakDetectionMethodNames]);
    PKLogDebug(@"spectraMatchingMethods: %@", [self spectraMatchingMethodNames]);
    [self didChangeValueForKey:@"baselineDetectionMethodNames"];
    [self didChangeValueForKey:@"peakDetectionMethodNames"]; 
    [self didChangeValueForKey:@"spectraMatchingMethodNames"];
    
} 

- (NSMutableArray *)allBundles { 
    NSArray *librarySearchPaths; 
    NSEnumerator *searchPathEnum; 
    NSString *currPath; 
    NSMutableArray *bundleSearchPaths = [NSMutableArray array]; 
    NSMutableArray *allBundles = [NSMutableArray array]; 
    librarySearchPaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask - NSSystemDomainMask, YES); 
    searchPathEnum = [librarySearchPaths objectEnumerator]; 
    while(currPath = [searchPathEnum nextObject]) 
    { 
        [bundleSearchPaths addObject: 
         [currPath stringByAppendingPathComponent:appSupportSubpath]]; 
    } 
    [bundleSearchPaths addObject:[[NSBundle mainBundle] builtInPlugInsPath]]; 
    searchPathEnum = [bundleSearchPaths objectEnumerator]; 
    while(currPath = [searchPathEnum nextObject]) 
    { 
        NSDirectoryEnumerator *bundleEnum; 
        NSString *currBundlePath; 
        bundleEnum = [[NSFileManager defaultManager] 
                      enumeratorAtPath:currPath]; 
        if(bundleEnum) 
        { 
            while(currBundlePath = [bundleEnum nextObject]) 
            { 
                if([[currBundlePath pathExtension] isEqualToString:ext]) 
                { 
                    [allBundles addObject:[currPath stringByAppendingPathComponent:currBundlePath]]; 
                } 
            } 
        } 
    } 
    return allBundles; 
} 

- (BOOL)plugInClassIsValid:(Class)plugInClass { 
    if ([plugInClass conformsToProtocol:@protocol(PKPluginProtocol)]) { 
        return YES;
    } 
    return NO; 
}

- (NSArray *)baselineDetectionMethodNames {
    return [baselineDetectionMethods allKeys];
}

/*!
 @abstract   Returns an array of NSStrings for peak detection methods implemented through plugins.
 */
- (NSArray *)peakDetectionMethodNames {
    return [peakDetectionMethods allKeys];
}

/*!
 @abstract   Returns an array of NSStrings for forward search methods implemented through the plugin.
 */
- (NSArray *)spectraMatchingMethodNames {
    return [spectraMatchingMethods allKeys];
}

- (NSDictionary *)baselineDetectionMethods {
    return baselineDetectionMethods;
}

/*!
 @abstract   Returns an array of NSStrings for peak detection methods implemented through plugins.
 */
- (NSDictionary *)peakDetectionMethods {
    return peakDetectionMethods;
}

/*!
 @abstract   Returns an array of NSStrings for forward search methods implemented through the plugin.
 */
- (NSDictionary *)spectraMatchingMethods {
    return spectraMatchingMethods;
}
#pragma mark -


#pragma mark JKSummarizer
- (PKSummarizer *)summarizer {
    return summarizer;
}
#pragma mark -

#pragma mark Exception Handling
//
// Disable ?, because it can be very noisy
//
- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldHandleException:(NSException *)exception mask:(unsigned int)aMask {
    if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"JKVerbosity"] intValue] >= JK_VERBOSITY_DEBUG) {
        [self printStackTrace:exception];
        return YES;
    } else {
        return NO;
    }
}

- (BOOL)exceptionHandler:(NSExceptionHandler *)sender shouldLogException:(NSException *)exception mask:(unsigned int)mask {
    if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"JKVerbosity"] intValue] >= JK_VERBOSITY_DEBUG) {
        [self printStackTrace:exception];
        return YES;
    } else {
        return NO;
    }
}

- (void)printStackTrace:(NSException *)e {
    NSString *stack = [[e userInfo] objectForKey:NSStackTraceKey];
    if (stack) {
        NSTask *ls = [[NSTask alloc] init];
        NSString *pid = [[NSNumber numberWithInt:[[NSProcessInfo processInfo] processIdentifier]] stringValue];
        NSMutableArray *args = [NSMutableArray arrayWithCapacity:20];
        
        [args addObject:@"-p"];
        [args addObject:pid];
        [args addObjectsFromArray:[stack componentsSeparatedByString:@"  "]];
        // Note: function addresses are separated by double spaces, not a single space.
        
        [ls setLaunchPath:@"/usr/bin/atos"];
        [ls setArguments:args];
        [ls launch];
        [ls release];
        
    } else {
        PKLogDebug(@"No stack trace available.");
    }
}
#pragma mark -

#pragma mark Properties
@synthesize batchProcessWindowController;
@synthesize showPresetMenu;
@synthesize library;
@synthesize mwWindowController;
@synthesize removeChromatogramMenu;
@synthesize viewColumnsMenu;
@synthesize welcomeWindow;
@synthesize preferencesWindowController;
@synthesize libraryConfigurationLoaded;
@synthesize summarizer;
#pragma mark -
@end
