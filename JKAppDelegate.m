//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKAppDelegate.h"

#import "JKGCMSDocument.h"
#import "JKLog.h"
#import "JKPanelController.h"
#import "JKStatisticsDocument.h"
#import "JKMainWindowController.h"
#import "BooleanToStringTransformer.h"

@implementation JKAppDelegate

+ (void)initialize {
	// Register default settings
	NSMutableDictionary *defaultValues = [NSMutableDictionary new];
	
	// Application level prefences
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"skipWelcomeDialog"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"showInspectorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"showMassCalculatorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"showDocumentListOnLaunch"];
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
	[defaultValues setValue:[[NSString stringWithString:@"~/Desktop/Test Library.jdx"] stringByExpandingTildeInPath] forKey:@"libraryAlias"];
	[defaultValues setValue:[NSNumber numberWithInt:JKAbundanceScoreBasis] forKey:@"scoreBasis"]; // Using formula 1 in Gan 2001
	[defaultValues setValue:[NSNumber numberWithInt:JKForwardSearchDirection] forKey:@"searchDirection"];
	[defaultValues setValue:[NSNumber numberWithInt:JKSpectrumSearchSpectrum] forKey:@"spectrumToUse"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"penalizeForRetentionIndex"];
	[defaultValues setValue:[NSNumber numberWithFloat:75.0f] forKey:@"markAsIdentifiedThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:50.0f] forKey:@"minimumScoreSearchResults"];
	[defaultValues setValue:[NSNumber numberWithFloat:45.0f] forKey:@"minimumScannedMassRange"];
	[defaultValues setValue:[NSNumber numberWithFloat:650.0f] forKey:@"maximumScannedMassRange"];
	[defaultValues setValue:[NSNumber numberWithFloat:200.0f] forKey:@"maximumRetentionIndexDifference"];

	// Default presets
	[defaultValues setObject:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"Alkanes",@"name",@"55+57",@"massValue",nil],
        [NSDictionary dictionaryWithObjectsAndKeys:@"Alkenes",@"name",@"56+58",@"massValue",nil]
        ,nil] forKey:@"presets"];
	
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
				
    // Additions for Peacock
    [defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"shouldDrawBaseline"];
    [defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"shouldDrawPeaks"];
    
    
	// Hidden preference for logging verbosity
	[defaultValues setValue:[NSNumber numberWithInt:JK_VERBOSITY_INFO] forKey:@"JKVerbosity"];
	
//	[[NSUserDefaults standardUserDefaults] setInitialValues:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
	[defaultValues release];
}

- (id)init {
	self = [super init];
	if (self != nil) {
		[self setDelegate:self];		
        
        NSNotificationCenter *center;
		center = [NSNotificationCenter defaultCenter];
        
        [center addObserver: self
				   selector: @selector(documentActivateNotification:)
					   name: NSWindowDidBecomeMainNotification
					 object: nil];
        [center addObserver: self
				   selector: @selector(documentDeactivateNotification:)
					   name: NSWindowDidResignMainNotification
					 object: nil];
        
        // Create and register font name value transformer
        NSValueTransformer *transformer = [[BooleanToStringTransformer alloc] init];
        [NSValueTransformer setValueTransformer:transformer forName:@"BooleanToStringTransformer"];
                
	}
	return self;
}

- (void)dealloc
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center removeObserver: self
					  name: nil
					object: nil];
    [super dealloc];
}

#pragma mark DELEGATE METHODS

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    // Delegate method per NSApplication to suppress or allow untitled window at launch.
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {	
	// Execute startup preferences
//#warning Custom level debug verbosity set.
    JKSetVerbosityLevel([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"JKVerbosity"] intValue]);
//#warning High level debug verbosity set.
//	JKSetVerbosityLevel(JK_VERBOSITY_ALL);
    
    
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSave"] boolValue] == YES) {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSaveDelay"] intValue]*60];
    } else {
        [[NSDocumentController sharedDocumentController] setAutosavingDelay:0];
    }
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showInspectorOnLaunch"] boolValue] == YES) {
        [[JKPanelController sharedController] showInspector:self];
    } else {
		[JKPanelController sharedController]; // Just so it's initiated in time to register for notifications
	}
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showMassCalculatorOnLaunch"] boolValue] == YES) {
        [mwWindowController showWindow:self];
    } 
    
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showDocumentListOnLaunch"] boolValue] == YES) {
        [documentListPanel orderFront:self];
    } 
    
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"skipWelcomeDialog"] boolValue] == NO) {
        [welcomeWindow center];
        [welcomeWindow makeKeyAndOrderFront:self];
    }	
    
	// Growl support
	[GrowlApplicationBridge setGrowlDelegate:self];
    
//    [self loadPlugins];
    
    [documentListTableView setDoubleAction:@selector(doubleClickAction:)];

}


#pragma mark ACTIONS

- (IBAction)openPreferencesWindowAction:(id)sender {
    if (!preferencesWindowController) {
        preferencesWindowController = [[JKPreferencesWindowController alloc] init];
    }
    [preferencesWindowController showWindow:self];
}

- (IBAction)showInspector:(id)sender {
    [[JKPanelController sharedController] showInspector:self];
}

- (IBAction)showReadMe:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"rtf"];
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

- (IBAction)showBatchProcessAction:(id)sender {
	if (!batchProcessWindowController) {
        batchProcessWindowController = [[JKBatchProcessWindowController alloc] init];
    }
    [batchProcessWindowController showWindow:self];	
}

- (IBAction)showStatisticsAction:(id)sender {
	NSError *error = [[NSError alloc] init];
	JKStatisticsDocument *document = [[NSDocumentController sharedDocumentController] makeUntitledDocumentOfType:@"Peacock Statistics File" error:&error];
	[[NSDocumentController sharedDocumentController] addDocument:document];
	[document makeWindowControllers];
	[document showWindows];
	[error release];
		
//	if (!statisticsWindowController) {
//        statisticsWindowController = [[JKStatisticsWindowController alloc] init];
//    }
//    [statisticsWindowController showWindow:self];	
}

- (IBAction)openTestFile:(id)sender {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Peacock Test Files"]]) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]]) {
            [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]] display:YES error:NULL];
            [welcomeWindow orderOut:self];
            return;
        }
        
        NSRunAlertPanel(@"Folder already exists",@"A folder with the name \"Peacock Test Files\" already exists on your desktop.",@"OK",nil,nil);
        return;
    }
    if (![[NSFileManager defaultManager] copyPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Peacock Test Files"] toPath:[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Peacock Test Files"] handler:nil]) {
         NSRunAlertPanel(@"Error during copying of folder",@"An error occurred during the copying of the folder with the name \"Peacock Test Files\" to your desktop.",@"OK",nil,nil);
    }
    
    [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] stringByAppendingPathComponent:@"Peacock Test Files"] stringByAppendingPathComponent:@"Test File.cdf"]] display:YES error:NULL];
    
    [welcomeWindow orderOut:self];
}

- (void)runPageLayout:(id)sender {
    NSPageLayout *pl = [NSPageLayout pageLayout];
    NSPrintInfo *pi = [NSPrintInfo sharedPrintInfo];
    if ([pl runModalWithPrintInfo:pi] == NSOKButton) {
        JKLogDebug(@"%d", [pi orientation]);
        [NSPrintInfo setSharedPrintInfo:pi];
    }
}
#pragma mark GROWL SUPPORT

- (NSDictionary *) registrationDictionaryForGrowl {
	NSArray *defaultArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished", @"Statistical Analysis Finished",nil];
	NSArray *allArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished", @"Statistical Analysis Finished",nil];
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:defaultArray, GROWL_NOTIFICATIONS_DEFAULT, allArray, GROWL_NOTIFICATIONS_ALL,nil];
	return dictionary;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
	if ([anItem action] == @selector(showInspector:)) {
		if ([[[JKPanelController sharedController] window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Inspector",@"Menutitle when inspector is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Inspector",@"Menutitle when inspector is not visible")];
		}			
		return YES;
    } else if ([anItem action] == @selector(showDocumentList:)) {
		if ([documentListPanel isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Document List",@"Menutitle when Document List is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Document List",@"Menutitle when Document List is not visible")];
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
		if ((currentDocument != nil) && ([currentDocument isKindOfClass:[JKGCMSDocument class]])) {
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
		if ((currentDocument != nil) && ([currentDocument isKindOfClass:[JKGCMSDocument class]])) {
			[item setTitle:[[[currentDocument chromatograms] objectAtIndex:x+1] valueForKey:@"model"]];
			[item setTag:x+1];
			[item setAction:@selector(removeChromatogram:)];
			return YES;
		}
	} 
	return NO;
}

#pragma mark PLUGINS

//- (void)loadPlugins {
//    JKLogDebug(@"Loading plugins from %@",[[NSBundle mainBundle] builtInPlugInsPath]);
//    
//    NSEnumerator *enumerator = [[NSBundle pathsForResourcesOfType:@"peacock-plugin" inDirectory:[[NSBundle mainBundle] builtInPlugInsPath]] objectEnumerator];
//    NSString *path;
//
//    while ((path = [enumerator nextObject]) != nil) {
//        JKLogDebug(@"Loading bundle from %@",path);
//    	[self loadBundle:path];
//    }
//    
//}
//
//- (void)loadBundle:(NSString*)bundlePath {
//    Class exampleClass;
//    id newInstance;
//    NSBundle *bundleToLoad = [NSBundle bundleWithPath:bundlePath];
////JKLogDebug(@"bundle %@",[bundleToLoad infoDictionary]);
//    if (exampleClass = [bundleToLoad principalClass]) {
//        newInstance = [[exampleClass alloc] init];
//        // [newInstance doSomething];
//    } else {
//        JKLogDebug(@"No principalClass for bundle");
//    }
//}

- (NSArray *)documents {
    return [[NSDocumentController sharedDocumentController] documents];
}

#pragma mark NSTableView Datasource

- (int)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self documents] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex {
    NSDocument *doc = [[self documents] objectAtIndex:rowIndex];
    if ([[doc windowForSheet] windowController]) {
        return [[[doc windowForSheet] windowController] windowTitleForDocumentDisplayName:[doc displayName]];
    } else {
        return [doc displayName];        
    }
}
#pragma mark -

#pragma mark NSTableView Delegate
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if ([[aNotification object] selectedRow] != -1) {
        [[[self documents] objectAtIndex:[[aNotification object] selectedRow]] showWindows];        
    }
}

- (void)documentActivateNotification:(NSNotification *)aNotification
{
    [documentListTableView reloadData];
    int row = [[self documents] indexOfObject:[[aNotification object] document]];
    [documentListTableView selectRow:row byExtendingSelection:NO];
}

- (void)documentDeactivateNotification:(NSNotification *)aNotification
{
    [documentListTableView reloadData];
}

- (void)doubleClickAction:(id)sender
{
    int i, count = [[self documents] count];
    id doc;
    for (i=0; i < count; i++) {
        if (i != [documentListTableView selectedRow]) {
            doc = [[self documents] objectAtIndex:i];
            [[doc windowForSheet] orderOut:nil];            
        }
    }
    if ([documentListTableView selectedRow] != -1) {
        doc = [[self documents] objectAtIndex:[documentListTableView selectedRow]];
        [doc showWindows];
//        [[doc windowForSheet] setFrameTopLeftPoint:NSMakePoint([documentListPanel frame].origin.x+[documentListPanel frame].size.width,[documentListPanel frame].origin.y+[documentListPanel frame].size.height)];
//        NSIntersectionRect(<#NSRect rect0#>,<#NSRect rect1#>)
        NSRect visibleFrame = [[[doc windowForSheet] screen] visibleFrame];
        NSRect panelFrame = [documentListPanel frame];
        NSRect newRect;
        newRect.origin.x = panelFrame.origin.x + panelFrame.size.width;
        newRect.origin.y = visibleFrame.origin.y;
        newRect.size.height = visibleFrame.size.height;
        newRect.size.width = visibleFrame.size.width - (panelFrame.origin.x + panelFrame.size.width);
        [[doc windowForSheet] setFrame:newRect display:YES animate:YES];
    }
}

- (IBAction)showDocumentList:(id)sender
{
    if ([documentListPanel isVisible]) {
        [documentListPanel orderOut:nil];
    } else {
        [documentListPanel orderFront:nil];        
    }
}

@end
