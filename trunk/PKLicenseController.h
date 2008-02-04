//
//  PKLicenseController.h
//  Peacock
//
//  Created by Johan Kool on 22-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PKLicenseController : NSWindowController {
    NSArray *licenses;
    IBOutlet NSWindow *begWindow;
    IBOutlet NSWindow *licenseWindow;
    
    IBOutlet NSTextField *nameField;
    IBOutlet NSTextField *emailField;
    IBOutlet NSTextField *countryField;
    IBOutlet NSPopUpButton *typeField;
    IBOutlet NSButton *includeInfoField;
}

+ (PKLicenseController *)sharedController;

- (NSArray *)gatherValidLicenses;
- (void)begForRegistration;
- (BOOL)validLicenseAvailable;
- (IBAction)showLicenses:(id)sender;
- (IBAction)installLicenseFile:(id)sender;
- (IBAction)retrieveLostLicenseFile:(id)sender;
- (IBAction)registerOnline:(id)sender;
- (IBAction)sendRegistration:(id)sender;
- (IBAction)registerLater:(id)sender;

@property (retain) NSArray *licenses;

@end
