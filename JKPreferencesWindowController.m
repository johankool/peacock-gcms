//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPreferencesWindowController.h"

@implementation JKPreferencesWindowController

# pragma mark INITIALIZATION

-(id)init {
    self = [super initWithWindowNibName:@"JKPreferences"];
    return self;
}

-(IBAction)closeButtonAction:(id)sender {
    [[self window] makeFirstResponder:[self window]];
    [[self window] close];
}

-(IBAction)browseForDefaultLibrary:(id)sender {
	int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"jdx"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"]
									 file:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"defaultLibrary"] types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            NSString *aFile = [filesToOpen objectAtIndex:i];
			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:aFile forKey:@"defaultLibrary"];
        }
    }
}

-(IBAction)browseForCustomLibrary:(id)sender {
	int result;
    NSArray *fileTypes = [NSArray arrayWithObject:@"jdx"];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    result = [oPanel runModalForDirectory:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"customLibrary"]
									 file:[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"customLibrary"] types:fileTypes];
    if (result == NSOKButton) {
        NSArray *filesToOpen = [oPanel filenames];
        int i, count = [filesToOpen count];
        for (i=0; i<count; i++) {
            NSString *aFile = [filesToOpen objectAtIndex:i];
			[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:aFile forKey:@"customLibrary"];
        }
		NSRunCriticalAlertPanel(@"Change ignored",@"This setting is currently not supported.",@"OK",nil,nil);
		//NSRunCriticalAlertPanel(@"Change effective for new files only",@"The newly selected custom library will be used only for files which are opened after you changed this setting.",@"OK",nil,nil);
    }
}
# pragma mark WINDOW MANAGEMENT

-(void)awakeFromNib {
    [[self window] center];
}

@end
