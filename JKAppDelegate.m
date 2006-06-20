//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKAppDelegate.h"

#import "JKGCMSDocument.h"
#import "JKLog.h"
#import "JKPanelController.h"
#import "JKStatisticsDocument.h"

@implementation JKAppDelegate

+ (void)initialize  
{
	// Register default settings
	NSMutableDictionary *defaultValues = [NSMutableDictionary new];
	
	// Application level prefences
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"SUCheckAtStartup"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"showInspectorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"showMassCalculatorOnLaunch"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"autoSave"];
	[defaultValues setValue:[NSNumber numberWithInt:0] forKey:@"autoSaveDelay"]; 
	
	// Default preferences for initial document settings
	[defaultValues setValue:[NSNumber numberWithInt:30] forKey:@"baselineWindowWidth"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.05f] forKey:@"baselineDistanceThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.005f] forKey:@"baselineSlopeThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.5f] forKey:@"baselineDensityThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.1f] forKey:@"peakIdentificationThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:1.0f] forKey:@"retentionIndexSlope"];
	[defaultValues setValue:[NSNumber numberWithFloat:0.0f] forKey:@"retentionIndexRemainder"];
	[defaultValues setValue:@"" forKey:@"libraryAlias"];
	[defaultValues setValue:[NSNumber numberWithInt:0] forKey:@"scoreBasis"]; // Using formula 1 in Gan 2001
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"penalizeForRetentionIndex"];
	[defaultValues setValue:[NSNumber numberWithFloat:75.0] forKey:@"markAsIdentifiedThreshold"];
	[defaultValues setValue:[NSNumber numberWithFloat:50.0] forKey:@"minimumScoreSearchResults"];

	// Default presets
	[defaultValues setObject:[NSArray arrayWithObjects:[NSDictionary dictionaryWithObjectsAndKeys:@"test",@"name",@"1+2+3",@"massValue",nil],nil] forKey:@"presets"];
	
	// Default summary settings
	[defaultValues setValue:[NSNumber numberWithInt:3] forKey:@"peaksForSummary"]; // confirmed peaks
	[defaultValues setValue:[NSNumber numberWithInt:1] forKey:@"columnSorting"]; // Samplecode
	
	// Default batch settings
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"batchDeleteCurrentPeaksFirst"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"batchIdentifyPeaks"];
	[defaultValues setValue:[NSNumber numberWithBool:YES] forKey:@"batchIdentifyCompounds"];
	[defaultValues setValue:[NSNumber numberWithInt:0] forKey:@"batchUseSettings"];
	[defaultValues setValue:[NSNumber numberWithBool:NO] forKey:@"batchSaveAsPeacockFile"];

	// Hidden preference for logging verbosity
	[defaultValues setValue:[NSNumber numberWithInt:JK_VERBOSITY_INFO] forKey:@"JKVerbosity"];
	
//	[[NSUserDefaults standardUserDefaults] setInitialValues:defaultValues];
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
	[defaultValues release];
}

- (id)init  
{
	self = [super init];
	if (self != nil) {
		[self setDelegate:self];		
	}
	return self;
}

#pragma mark DELEGATE METHODS

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender  
{
    // Delegate method per NSApplication to suppress or allow untitled window at launch.
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {	
	// Execute startup preferences
#warning Custom level debug verbosity set.
    JKSetVerbosityLevel([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"JKVerbosity"] intValue]);
//#warning High level debug verbosity set.
//	JKSetVerbosityLevel(JK_VERBOSITY_ALL);

//    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSave"] boolValue] == YES) {
//        [[NSDocumentController sharedDocumentController] setAutosavingDelay:[[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"autoSaveDelay"] intValue]];
//    }
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showInspectorOnLaunch"] boolValue] == YES) {
        [[JKPanelController sharedController] showInspector:self];
    } else {
		[JKPanelController sharedController]; // Just so it's initiated in time to register for notifications
	}
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showMassCalculatorOnLaunch"] boolValue] == YES) {
        [mwWindowController showWindow:self];
    }    
		
	// Growl support
	[GrowlApplicationBridge setGrowlDelegate:self];
}


#pragma mark ACTIONS

- (IBAction)openPreferencesWindowAction:(id)sender  
{
    if (!preferencesWindowController) {
        preferencesWindowController = [[JKPreferencesWindowController alloc] init];
    }
    [preferencesWindowController showWindow:self];
}

- (IBAction)showInspector:(id)sender  
{
    [[JKPanelController sharedController] showInspector:self];
}

- (IBAction)showReadMe:(id)sender  
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

- (IBAction)showLicense:(id)sender  
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

- (IBAction)showBatchProcessAction:(id)sender  
{
	if (!batchProcessWindowController) {
        batchProcessWindowController = [[JKBatchProcessWindowController alloc] init];
    }
    [batchProcessWindowController showWindow:self];	
}

- (IBAction)showStatisticsAction:(id)sender  
{
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

#pragma mark GROWL SUPPORT

- (NSDictionary *) registrationDictionaryForGrowl  
{
	NSArray *defaultArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished", @"Statistical Analysis Finished",nil];
	NSArray *allArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished", @"Statistical Analysis Finished",nil];
	NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:defaultArray, GROWL_NOTIFICATIONS_DEFAULT, allArray, GROWL_NOTIFICATIONS_ALL,nil];
	return dictionary;
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem  
{
	if ([anItem action] == @selector(showInspector:)) {
		if ([[[JKPanelController sharedController] window] isVisible] == YES) {
			[anItem setTitle:NSLocalizedString(@"Hide Inspector",@"Menutitle when inspector is visible")];
		} else {
			[anItem setTitle:NSLocalizedString(@"Show Inspector",@"Menutitle when inspector is not visible")];
		}			
		return YES;
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

- (int)numberOfItemsInMenu:(NSMenu *)menu
{
	if (menu == showPresetMenu) {
		return [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"presets"] count];
	} else if (menu == removeChromatogramMenu) {
		id currentDocument = [[NSDocumentController sharedDocumentController] currentDocument];
		if ((currentDocument != nil) && ([currentDocument isKindOfClass:[JKGCMSDocument class]])) {
			return [[currentDocument chromatograms] count];
		}
	}
	return 0;
}

- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)item atIndex:(int)x shouldCancel:(BOOL)shouldCancel
{
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
			[item setTitle:[[[currentDocument chromatograms] objectAtIndex:x] valueForKey:@"seriesTitle"]];
			[item setTag:x];
			[item setAction:@selector(removeChromatogram:)];
			return YES;
		}
	}
	return NO;
}

@end
