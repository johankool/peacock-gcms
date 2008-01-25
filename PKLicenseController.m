//
//  PKLicenseController.m
//  Peacock
//
//  Created by Johan Kool on 22-01-08.
//  Copyright 2008 Johan Kool. All rights reserved.
//

#import "PKLicenseController.h"

#import "AquaticPrime.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBook/ABMultiValue.h>

// Name of the application support folder
static NSString * SUPPORT_FOLDER_NAME = @"Peacock";
static NSString * LIBRARY_FOLDER_NAME = @"Libraries";
static NSString * LICENSES_FOLDER_NAME = @"Licenses";
static NSString * LIBRARY_EXTENSION = @"peacock-library";
static NSString * LICENSE_EXTENSION = @"peacock-license";

static PKLicenseController *theSharedController;

@implementation PKLicenseController

+ (PKLicenseController *) sharedController {
    if (theSharedController == nil) {
        theSharedController = [[PKLicenseController alloc] init];
    }
	
    return (theSharedController);
} 

- (id)init {
    self = [super initWithWindowNibName:@"PKRegister"];
    if (self) {
        [self willChangeValueForKey:@"licences"];
        licenses = [[self gatherValidLicenses] retain];
        [self didChangeValueForKey:@"licences"];        
    }
    return self;
}

- (void) dealloc {
    [licenses release];
    [super dealloc];
}

#pragma mark -

#pragma mark Window Management
- (void)windowDidLoad {
    [begWindow center];
    [licenseWindow center];
}

- (NSArray *)gatherValidLicenses {
    NSMutableArray *licensesFound = [[NSMutableArray alloc] init];
    
    // This string is specially constructed to prevent key replacement 	
    // *** Begin Public Key ***
    NSMutableString *key = [NSMutableString string];
    [key appendString:@"0xEF53"];
    [key appendString:@"0"];
    [key appendString:@"0"];
    [key appendString:@"61CFA7A61077F5717FBA33"];
    [key appendString:@"1217BE3815"];
    [key appendString:@"2"];
    [key appendString:@"2"];
    [key appendString:@"A818106B478073B873"];
    [key appendString:@"C8C1581BC4C5E21"];
    [key appendString:@"3"];
    [key appendString:@"3"];
    [key appendString:@"FC4A8ED3402AC"];
    [key appendString:@"C6"];
    [key appendString:@"1"];
    [key appendString:@"1"];
    [key appendString:@"817443255378912C60D99B1C81"];
    [key appendString:@"90F63E6DE9E21"];
    [key appendString:@"A"];
    [key appendString:@"A"];
    [key appendString:@"FD6BF6B72DFDCF8"];
    [key appendString:@"98D9F"];
    [key appendString:@"2"];
    [key appendString:@"2"];
    [key appendString:@"CD80FAE92AC1440294FD3DF"];
    [key appendString:@"D3C0A31A6937ACB14B9A7"];
    [key appendString:@"4"];
    [key appendString:@"4"];
    [key appendString:@"ACCCB34"];
    [key appendString:@"C8DC54876C02F8D819D35"];
    [key appendString:@"1"];
    [key appendString:@"1"];
    [key appendString:@"C45F935"];
    [key appendString:@"B431410D793F34D945"];
    // *** End Public Key *** 
    
    // Instantiate AquaticPrime
    AquaticPrime *licenseValidator = [AquaticPrime aquaticPrimeWithKey:key];
    
    // Get the dictionary from the license file
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *searchpaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSAllDomainsMask, YES);
    for (NSString *searchpath in searchpaths) {
        // look for the Peacock support folder 
        NSString *path = [searchpath stringByAppendingPathComponent: SUPPORT_FOLDER_NAME];
        // look for the licenses folder 
        path = [path stringByAppendingPathComponent: LICENSES_FOLDER_NAME];
        
        // look for license files in the folder
        NSString *file;
        NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:path];
        int count = 0;
        int loadedCount = 0;
        while ((file = [dirEnum nextObject])) {
            if ([[file pathExtension] isEqualToString:LICENSE_EXTENSION]) {
                NSDictionary *licenseDictionary = [licenseValidator dictionaryForLicenseFile:[path stringByAppendingPathComponent:file]];
                if (licenseDictionary != nil) {
                    // check if license type is allowed at this domain
                    // check if license is valid for this version of the app
                    // check if license is not expired
                    [licensesFound addObject:licenseDictionary];
                } else {
                    // "corrupted" license
                }
            }
        }
    }

    return [licensesFound autorelease];
}

- (BOOL)validLicenseAvailable {
    if ([licenses count] < 1) {
        [self willChangeValueForKey:@"licences"];
        [self setLicenses:[self gatherValidLicenses]];
        [self didChangeValueForKey:@"licences"];
    }
    return ([licenses count] > 0);
}

- (void)begIfNeeded {
    if (![self validLicenseAvailable]) {
        [self begForRegistration];
    }
}

- (void)begForRegistration {
    ABPerson *aPerson = [[ABAddressBook sharedAddressBook] me];
  
    // email
    ABMultiValue *emails = [aPerson valueForProperty:kABEmailProperty];
     NSString *email = (NSString*) [emails valueAtIndex:[emails indexForIdentifier:[emails primaryIdentifier]]];

    // country
    ABMultiValue *anAddressList = [aPerson valueForProperty:kABAddressProperty];
    int primaryIndex =  [anAddressList indexForIdentifier:[anAddressList primaryIdentifier]];
    NSString *country = (NSString*) [[anAddressList valueAtIndex:primaryIndex] objectForKey:kABAddressCountryKey];
    
    [nameField setStringValue:NSFullUserName()];
    [emailField setStringValue:email];
    [countryField setStringValue:country];
    [NSApp runModalForWindow:begWindow];
}

- (IBAction)showLicenses:(id)sender {
    [licenseWindow makeKeyAndOrderFront:self];
}

- (IBAction)installLicenseFile:(id)sender {
    
}

- (IBAction)retrieveLostLicenseFile:(id)sender {
    
}

- (IBAction)registerOnline:(id)sender {
    [self begForRegistration];
}

- (IBAction)sendRegistration:(id)sender {
    [NSApp stopModal];
    [begWindow orderOut:self];
    NSRunAlertPanel(@"Thank you!", @"Your registration is sent. Your license will be mailed to you soon.", @"OK", nil, nil);
}

- (IBAction)registerLater:(id)sender {
    [NSApp stopModal];
    [begWindow orderOut:self];
}

@synthesize licenses;

@end
