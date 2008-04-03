//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import "JKLibraryWindowController.h"

#import "JKLibrary.h"
#import "JKManagedLibraryEntry.h"
#import "JKMoleculeModel.h"
#import "JKMoleculeView.h"
#import "PKGraphView.h"
#import "PKSpectrumDataSeries.h"


@implementation JKLibraryWindowController

- (id)init {
	self = [super initWithWindowNibName:@"JKLibrary"];
    if (self != nil) {
        [self setShouldCloseDocument:YES];
    }
    return self;
}

- (void)windowDidLoad {
    [[self window] setDelegate:self];
	[spectrumView setShouldDrawLegend:NO];
	[spectrumView setShouldDrawFrame:YES];
	[spectrumView setShouldDrawFrameBottom:NO];
    [spectrumView setShouldDrawLabels:NO];
    [spectrumView setShouldDrawLabelsOnFrame:YES];
    [spectrumView setShouldDrawAxes:YES];
    [spectrumView setShouldDrawAxesVertical:NO];
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	[spectrumView setPlottingArea:NSMakeRect(30,20,[spectrumView bounds].size.width-40,[spectrumView bounds].size.height-30)];
	[spectrumView setBackColor:[NSColor clearColor]];
	
	[spectrumView bind:@"dataSeries" toObject:spectrumViewDataseriesController withKeyPath:@"arrangedObjects" options:nil];
	
	[libraryController addObserver:self forKeyPath:@"selection" options:0 context:nil];

    [moleculeView bind:@"moleculeString" toObject: libraryController
		   withKeyPath:@"selection.molString" options:nil];
    
//    [tableView registerForDraggedTypes:[NSArray arrayWithObjects:@"JKLibraryEntryTableViewDataType", nil]]; 
}

- (void) dealloc {
    [[self libraryController] removeObserver:self forKeyPath:@"selection"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if (object == libraryController) {
//		[moleculeView setModel:[[JKMoleculeModel alloc] initWithMoleculeString:[[[[self libraryController] selectedObjects] objectAtIndex:0] valueForKey:@"molString"]]];
        [moleculeView setNeedsDisplay:YES];
      
        [spectrumViewDataseriesController removeObjects:[spectrumViewDataseriesController arrangedObjects]];
        NSMutableArray *spectrumArray = [NSMutableArray array];
        
        PKSpectrumDataSeries *sgds;
        
        for (JKManagedLibraryEntry *libraryEntry in [libraryController selectedObjects]) {
            sgds = [[[PKSpectrumDataSeries alloc] initWithSpectrum:libraryEntry] autorelease];
            if (showNormalizedSpectra) {
                [sgds setNormalizeYData:YES];
            }
            [spectrumArray addObject:sgds];
        }
        
        [spectrumViewDataseriesController setContent:spectrumArray];
        
         // spectrumView resizes to show all data
        [spectrumView showAll:self];
        [spectrumView setNeedsDisplay:YES];
 	} else if (object == moleculeView) {
      //  [[[[self libraryController] selectedObjects] objectAtIndex:0] setMolString:[[moleculeView model] molString]];
	} else {
//		[moleculeView setModel:nil];
        [moleculeView setNeedsDisplay:YES];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification {
    [spectrumViewDataseriesController setContent:nil];
}

#pragma mark IBACTIONS
- (IBAction)showAddCasNumber:(id)sender {
    [NSApp beginSheet: addCasNumberSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
}

- (IBAction)addCasNumber:(id)sender {
    NSError *outError;
    NSString *casNumber = [casNumberField stringValue];
    if ([self validateCASNumber:&casNumber error:&outError]) {
        JKLogDebug([casNumberField stringValue]);
        NSString *string = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-Mass.jdx?JCAMP=C%@&Index=0&Type=Mass",[casNumberField stringValue],[casNumberField stringValue]]]];
        JKLogDebug(string);
        if (string && ![string isEqualToString:@""]) {
            JKManagedLibraryEntry *libEntry = [NSEntityDescription insertNewObjectForEntityForName:@"JKManagedLibraryEntry" inManagedObjectContext:[[self document] managedObjectContext]];
            [libEntry setJCAMPString:string];
            [libEntry setMolString:[NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://webbook.nist.gov/cgi/cbook.cgi/%@-2d.mol?Str2File=C%@",[casNumberField stringValue],[casNumberField stringValue]]]]];        
            [NSApp endSheet:addCasNumberSheet];
        } else {
            NSString *errorString = NSLocalizedString(@"No Entry Found in NIST Webbook",@"not found error");
            NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"There was no entry found in the online NIST Webbook for this CAS Number. Not all entries have mass spectrometric data available. Another possibility is the lack of a working connection to the NIST Webbook server.",@"not found error")];
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                         code:118
                                                     userInfo:userInfoDict] autorelease];
            [self presentError:error];
        }
    }
    else {
        // inform the user that the value is invalid
        [self presentError:outError];
    }
    
}

#pragma mark Validation
- (BOOL)validateCASNumber:(id *)ioValue error:(NSError **)outError {
    if ([*ioValue isEqualToString:@""]) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"no input error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"A CAS Number consists of three numbers separated by hyphens.",@"no input error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:117
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    // Only numbers and hyphen allowed
    NSString *fixedString = [*ioValue stringByTrimmingCharactersInSet:[[NSCharacterSet characterSetWithCharactersInString:@"1234567890-"] invertedSet]];
    
    // There should be 2 hyphens
    NSArray *parts = [fixedString componentsSeparatedByString:@"-"];
    if ([parts count] != 3) {
        // Remove all hyphens
        fixedString = [fixedString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
        int length = [fixedString length];
        if (length >= 5) {
            parts = [NSArray arrayWithObjects:[fixedString substringToIndex:length-3], [fixedString substringWithRange:NSMakeRange(length-3, 2)], [fixedString substringFromIndex:length-1], nil];
        } else {
            NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"malformed input error");
            NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"A CAS Number consists of three numbers separated by hyphens.",@"malformed input error")];
            NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
            NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                         code:110
                                                     userInfo:userInfoDict] autorelease];
            *outError = error;
            return NO;
        }
    }
    
    int first_length = [[parts objectAtIndex:0] length];
    int second_length = [[parts objectAtIndex:1] length];
    int third_length = [[parts objectAtIndex:2] length];
    
    // max 7, min 2 digits before 1st hyphen
    if (first_length < 2) {
        
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"too few digits before first hyphen error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"Not enough digits found before the first hyphen. Use at least 2 digits.",@"too few digits before first hyphen error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:111
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    } 
    if (first_length > 7) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"too many digits before first hyphen error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"Too many digits found before the first hyphen. Do not use more than 7 digits.",@"too many digits before first hyphen error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:112
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    // 2 digits between hyphens
    if (second_length != 2) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"not two digits between first hyphen and second hyphen error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"Use two digits between first hyphen and second hyphen.",@"not two digits between first hyphen and second hyphen error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:113
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    // 1 digit after hyphen
    if (third_length != 1) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"not just one digit after second hyphen error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"Use just one digit after the second hyphen.",@"not just one digit after second hyphen error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:114
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    
    // check if last digit is correct
    int first_part = [[parts objectAtIndex:0] intValue];
    int second_part = [[parts objectAtIndex:1] intValue];
    int third_part = [[parts objectAtIndex:2] intValue];
    
    int checked_int = first_part * 100 + second_part;
    if (checked_int == 0) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"check digit cannot be computed error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The check digit could not be computed, check if you entered a valid CAS number.",@"check digit cannot be computed error")];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:115
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    
    int sum = 0;
    int i, factor, digit;
    for (i = 0; i < 9; i++) {
        factor = 9-i;
        digit = (int)(checked_int / pow(10, 8-i)) % 10;
        
        sum += factor * digit;
    }
    int expected = (int)(sum / pow(10, 0)) % 10;
    
    if (third_part != expected) {
        NSString *errorString = NSLocalizedString(@"Invalid value for CAS Number",@"check digit incorrect error");
        NSString *recoverySuggestionString = [NSString stringWithFormat:NSLocalizedString(@"The check digit is incorrect, check if you entered a valid CAS number. (found \"%d\", expected \"%d\")",@"check digit cannot be computed error"), third_part, expected];
        NSDictionary *userInfoDict = [NSDictionary dictionaryWithObjectsAndKeys:errorString,NSLocalizedDescriptionKey,recoverySuggestionString,NSLocalizedRecoverySuggestionErrorKey,nil];
        NSError *error = [[[NSError alloc] initWithDomain:@"Peacock"
                                                     code:116
                                                 userInfo:userInfoDict] autorelease];
        *outError = error;
        return NO;
    }
    fixedString = [NSString stringWithFormat:@"%d-%d-%d", first_part, second_part, expected];
    *ioValue = fixedString;
    return YES;
}
#pragma mark -

- (IBAction)cancelCasNumber:(id)sender {
    [NSApp endSheet:addCasNumberSheet];
}

#pragma mark UNDO MANAGEMENT

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { 
    return [[self document] undoManager];
}
#pragma mark -

#pragma mark Drag-'n-drop
- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard*)pboard
{
    if ([rowIndexes count] != 1) {
        return NO;
    }
    if (aTableView != tableView) {
        return NO;
    }
    
	// declare our own pasteboard types
    NSArray *typesArray = [NSArray arrayWithObjects:@"JKManagedLibraryEntryURIType", nil];
    [pboard declareTypes:typesArray owner:self];
    
    NSString *uriString = [[[[[libraryController arrangedObjects] objectAtIndex:[rowIndexes firstIndex]] objectID] URIRepresentation] absoluteString];
    [pboard setString:uriString forType:@"JKManagedLibraryEntryURIType"];
	
    return YES;
}
#pragma mark -

#pragma mark SHEETS
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (void)windowWillBeginSheet:(NSNotification *)notification {
	return;
}

- (void)windowDidEndSheet:(NSNotification *)notification {
	return;
}

#pragma mark ACCESSORS

- (NSArrayController *)libraryController {
	return libraryController;
}
@synthesize addCasNumberSheet;
@synthesize showNormalizedSpectra;
@synthesize casNumberField;
@synthesize spectrumViewDataseriesController;
@synthesize spectrumView;
@synthesize libraryController;
@synthesize moleculeView;
@synthesize tableView;
@end
