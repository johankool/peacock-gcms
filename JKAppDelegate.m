//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKAppDelegate.h"
#import "JKPanelController.h"
//#import "SmartCrashReportsInstall.h"
//#import <Growl/GrowlApplicationBridge.h>

@implementation JKAppDelegate

-(id)init {
	self = [super init];
	[self setDelegate:self];
	return self;
}

#pragma mark DELEGATE METHODS

-(BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
    // Delegate method per NSApplication to suppress or allow untitled window at launch.
    return NO;
}

-(void)applicationDidFinishLaunching:(NSNotification *)notification {	
	// Register default settings
	NSMutableDictionary *mutDict = [NSMutableDictionary new];
	[mutDict setValue:[NSNumber numberWithBool:NO] forKey:@"SUCheckAtStartup"];
	[mutDict setValue:[NSNumber numberWithBool:NO] forKey:@"showInspectorOnLaunch"];
	[mutDict setValue:[NSNumber numberWithBool:NO] forKey:@"showMassCalculatorOnLaunch"];
	[mutDict setValue:[NSNumber numberWithBool:NO] forKey:@"dontInstallSCR"];
//	[mutDict setValue:[NSNumber numberWithBool:0.9] forKey:@"acceptLevel"];
	[mutDict setValue:[NSNumber numberWithBool:YES] forKey:@"soundWhenFinished"];
	[mutDict setValue:[NSNumber numberWithInt:0] forKey:@"scoreBasis"]; // Using formula 1 in Gan 2001
	[mutDict setValue:[NSNumber numberWithInt:3] forKey:@"peaksForSummary"]; // confirmed peaks
	[mutDict setValue:[NSNumber numberWithInt:1] forKey:@"columnSorting"]; // Samplecode
	[mutDict setValue:@"" forKey:@"defaultLibrary"];
	[mutDict setValue:@"" forKey:@"customLibrary"];
	// Hidden preference for logging verbosity
	[mutDict setValue:[NSNumber numberWithInt:JK_VERBOSITY_INFO] forKey:JKLogVerbosityUserDefault];
	
	[[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:mutDict];
	[mutDict release];
	
	// Execute startup preferences
//    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"checkForUpdates"] boolValue]== YES) {
//        [self checkVersion:TRUE];
//    }
    JKSetVerbosityLevel([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:JKLogVerbosityUserDefault] intValue]);
	
//    if (!panelWindowController) {
//        panelWindowController = [[JKPanelController alloc] init];
//    }    
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showInspectorOnLaunch"] boolValue] == YES) {
        [[JKPanelController sharedController] showInspector:self];
    }
	
    if([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"showMassCalculatorOnLaunch"] boolValue] == YES) {
        [mwWindowController showWindow:self];
    }    
		
//	// Install bug reporting from Unsanity if needed
//	Boolean authenticationWillBeRequired = FALSE;
//	if (UnsanitySCR_CanInstall(&authenticationWillBeRequired) && [[NSFileManager defaultManager] fileExistsAtPath:[[NSString stringWithString:@"~/Library/Logs/CrashReporter/Peacock.crash.log"] stringByExpandingTildeInPath]] && ![[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"dontInstallSCR"] boolValue]) {
//		  // Ask user to install SCR
//		int button = NSRunAlertPanel(NSLocalizedString(@"May Peacock install Smart Crash Reports?", @"Title of alert when a crash was detected."),
//									 NSLocalizedString(@"By installing Smart Crash Reports from Unsanity you are enabled to sent future crash reports to the developer of Peacock so he can focus his work on improving the quality of Peacock.", @"SCR explanation"),
//									 NSLocalizedString(@"Install", @"Install"),
//									 NSLocalizedString(@"Cancel", @"Cancel"), 
//									 NSLocalizedString(@"More Info", @"More Info on SCR"));
//		if(NSOKButton == button)
//		{
//			UnsanitySCR_Install(authenticationWillBeRequired);
//			JKLogInfo(@"Peacock installed Unsanity's Smart Crash Report.");
//		} else if (NSCancelButton != button) {
//			[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.unsanity.com/smartcrashreports/"]];
//		} else if (NSCancelButton == button)  {
//			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithBool:YES] forKey:@"dontInstallSCR"];
//		}
//		
//	}
//	
	// Growl support
	[GrowlApplicationBridge setGrowlDelegate:self];
}


#pragma mark ACTIONS

-(IBAction)openPreferencesWindowAction:(id)sender {
    if (!preferencesWindowController) {
        preferencesWindowController = [[JKPreferencesWindowController alloc] init];
    }
    [preferencesWindowController showWindow:self];
}

-(IBAction)showInspector:(id)sender {
//    if (!panelWindowController) {
//        panelWindowController = [[JKPanelController alloc] init];
//    }
    [[JKPanelController sharedController] showInspector:self];
}

-(IBAction)showReadMe:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"ReadMe" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

-(IBAction)showLicense:(id)sender {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"License" ofType:@"rtf"];
    if (path) {
        if (![[NSWorkspace sharedWorkspace] openFile:path withApplication:@"TextEdit"]) NSBeep();
    }
}

-(IBAction)showBatchProcessAction:(id)sender {
	if (!batchProcessWindowController) {
        batchProcessWindowController = [[JKBatchProcessWindowController alloc] init];
    }
    [batchProcessWindowController showWindow:self];	
}

-(IBAction)showStatisticsAction:(id)sender {
	if (!statisticsWindowController) {
        statisticsWindowController = [[JKStatisticsWindowController alloc] init];
    }
    [statisticsWindowController showWindow:self];	
}



//-(IBAction)checkForNewVersion:(id)sender {
//    [self checkVersion:FALSE];
//}
//
//-(void)checkVersion:(BOOL)quiet {
//    NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]]
//        infoDictionary] objectForKey:@"CFBundleVersion"];    
//    NSDictionary *productVersionDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:@"http://www.geo.vu.nl/~jkool/peacock/version.xml"]];
//    NSString *latestVersionNumber = [productVersionDict valueForKey:@"peacock"];
//    
//    if([productVersionDict count] > 0 ) { // did we get anything?
//        if([latestVersionNumber isEqualTo: currVersionNumber] && !quiet)
//        {
//            // tell user software is up to date
//            NSRunAlertPanel(NSLocalizedString(@"Your Software is up-to-date", @"Title of alert when a the user's software is up to date."),
//                NSLocalizedString(@"You have the most recent version of Peacock.", @"Alert text when the user's software is up to date."),
//                NSLocalizedString(@"OK", @"OK"), nil, nil);
//        }
//        else if( ![latestVersionNumber isEqualTo: currVersionNumber])
//        {
//            // tell user to download a new version
//            int button = NSRunAlertPanel(NSLocalizedString(@"A New Version is Available", @"Title of alert when a the user's software is not up to date."),
//                [NSString stringWithFormat:NSLocalizedString(@"A new version of Peacock is available (version %@). Would you like to download the new version now?", @"Alert text when the user's software is not up to date."), latestVersionNumber],
//                NSLocalizedString(@"OK", @"OK"),
//                NSLocalizedString(@"Cancel", @"Cancel"), nil);
//            if(NSOKButton == button)
//            {
//                [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.geo.vu.nl/~jkool/peacock/"]];
//            }
//        }
//    } else {
//        if (!quiet) {
//            // tell user error occured
//            NSRunAlertPanel(NSLocalizedString(@"Version Check has Failed", @"Title of alert when the version check has failed."),
//                NSLocalizedString(@"An error occured whilst trying to retrieve the current version number from the internet.", @"Alert text when the when the version check has failed."),
//                NSLocalizedString(@"OK", @"OK"), nil, nil);
//        }
//    }
//}

#pragma mark GROWL SUPPORT
-(NSDictionary *) registrationDictionaryForGrowl {
	NSArray *defaultArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished",nil];
	NSArray *allArray = [NSArray arrayWithObjects:@"Batch Process Finished", @"Identifying Compounds Finished",nil];
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
	} else if ([self respondsToSelector:[anItem action]]) {
		return YES;
	} else {
		return NO;
	}
}

@end
