//
//  JKBatchProcessWindowController.m
//  Peacock
//
//  Created by Johan Kool on 14-12-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
//

#import "PKBatchProcessWindowController.h"

#import "PKGCMSDocument.h"
#import "PKMainWindowController.h"
#import "PKDocumentController.h"
#import "PKGraphView.h"

@implementation PKBatchProcessWindowController

- (id)init {
	self = [super initWithWindowNibName:@"PKBatchProcess"];
    if (self != nil) {
		files = [[NSMutableArray alloc] init];
		[self setAbortAction:NO];
	}
	
    return self;
}

- (void) dealloc {
	[files release];
	[super dealloc];
}

#pragma mark IBACTIONS

- (IBAction)addButtonAction:(id)sender {
	NSArray *fileTypes = [NSArray arrayWithObjects:@"cdf", @"peacock",nil];
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:YES];
	[oPanel beginSheetForDirectory:nil file:nil types:fileTypes modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
    if (returnCode == NSOKButton) {
        NSArray *filesToOpen = [sheet filenames];
        for (NSString *aFile in filesToOpen) {
			NSMutableDictionary *mutDict = [[NSMutableDictionary alloc] init];
			[mutDict setValue:[aFile lastPathComponent] forKey:@"filename"];
			[mutDict setValue:aFile forKey:@"path"];
			[mutDict setObject:[[NSWorkspace sharedWorkspace] iconForFile:aFile] forKey:@"icon"];
			[self willChangeValueForKey:@"files"];
			[files addObject:mutDict];
			[self didChangeValueForKey:@"files"];
			[mutDict release];
        }
	}	
}

- (IBAction)runBatchButtonAction:(id)sender {
	[NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
	
	[NSThread detachNewThreadSelector:@selector(runBatch) toTarget:self withObject:nil];
	
}

- (IBAction)stopButtonAction:(id)sender {
	[self setAbortAction:YES];
}

#pragma mark ACTIONS

- (void)runBatch {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	BOOL errorOccurred = NO;	
	[self setAbortAction:NO];
	int i;
	int filesCount = [files count];
	[fileProgressIndicator setMaxValue:filesCount*8.0];
	[fileProgressIndicator setDoubleValue:0.0];
	
	NSError *error = [[NSError alloc] init];
	PKGCMSDocument *document;
    PKGraphView *chromatogramView;
	NSString *path;

	for (i=0; i < filesCount; i++) {
		document = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:[[files objectAtIndex:i] valueForKey:@"path"]] display:YES error:&error];
        [[PKDocumentController sharedDocumentController] showDocument:document];
//		[[self window] makeKeyAndOrderFront:self];
		if (document == nil) {
			PKLogError(@"ERROR: File at %@ could not be opened.",[[files objectAtIndex:i] valueForKey:@"path"]);
			errorOccurred = YES;
			[fileProgressIndicator setDoubleValue:(i+1)*8.0];
			continue;	
		}
		[fileStatusTextField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Processing file \"%@\" (%d of %d)",@"Batch process status text"),[[files objectAtIndex:i] valueForKey:@"filename"],i+1,filesCount]];
		[detailStatusTextField setStringValue:@"Starting Processing"];
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchUseSettings"] intValue] == 1) {
			[document resetToDefaultValues];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchIdentifyBaseline"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Identifying Baseline",@"")];
            [[document chromatograms] makeObjectsPerformSelector:@selector(obtainBaseline)];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchDeleteCurrentPeaksFirst"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Deleting Current Peaks",@"")];
            [document setPeaks:nil];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchIdentifyPeaks"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Identifying Peaks",@"")];
            [[document chromatograms] makeObjectsPerformSelector:@selector(identifyPeaks)];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchIdentifyCompounds"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Identifying Compounds",@"")];
            [[[document mainWindowController] chromatogramsController] setSelectedObjects:[[[document mainWindowController] chromatogramsController] arrangedObjects]];
            [[document mainWindowController] identifyCompounds];
//            [[document mainWindowController] identifyCompoundsForSelectedChromatograms:self];
//			[document performLibrarySearchForChromatograms:[document chromatograms]];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchSaveAsPeacockFile"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Saving Peacock File",@"")];
			path = [[[files objectAtIndex:i] valueForKey:@"path"] stringByDeletingPathExtension];
			path = [path stringByAppendingPathExtension:@"peacock"];
			if (![document saveToURL:[NSURL fileURLWithPath:path] ofType:@"Peacock File" forSaveOperation:NSSaveAsOperation error:&error]) {
				PKLogError(@"ERROR: File at %@ could not be saved as Peacock File.",[[files objectAtIndex:i] valueForKey:@"path"]);
				errorOccurred = YES;
			}
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchSaveAsTabDelimitedTextFile"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Saving Tab Delimited Text File",@"")];
			path = [[[files objectAtIndex:i] valueForKey:@"path"] stringByDeletingPathExtension];
			path = [path stringByAppendingPathExtension:@"txt"];
			int selectedTag = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchShowPeaksTextTag"] intValue];
			if (selectedTag == 1) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == YES"]];
			} else if (selectedTag == 2) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == NO"]];		
			} else if (selectedTag == 3) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"confirmed == YES"]];
			} else if (selectedTag == 4) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"(identified == YES) AND (confirmed == NO)"]];		
			} else {
				[[[document mainWindowController] peakController] setFilterPredicate:nil]; 
			}
			if (![document saveToURL:[NSURL fileURLWithPath:path] ofType:@"Tab Delimited Text File" forSaveOperation:NSSaveToOperation error:&error]) {
				PKLogError(@"ERROR: File at %@ could not be saved as Tab Delimited Text File.",[[files objectAtIndex:i] valueForKey:@"path"]);				
				errorOccurred = YES;
			}
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchSaveAsPDF"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Saving PDF File",@"")];
			path = [[[files objectAtIndex:i] valueForKey:@"path"] stringByDeletingPathExtension];
			path = [path stringByAppendingPathExtension:@"pdf"];
            chromatogramView = [[document mainWindowController] chromatogramView];
			int selectedTag = [[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchShowPeaksPDFTag"] intValue];
			if (selectedTag == 1) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == YES"]];
			} else if (selectedTag == 2) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"identified == NO"]];		
			} else if (selectedTag == 3) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"confirmed == YES"]];
			} else if (selectedTag == 4) {
				[[[document mainWindowController] peakController] setFilterPredicate:[NSPredicate predicateWithFormat:@"(identified == YES) AND (confirmed == NO)"]];		
			} else {
				[[[document mainWindowController] peakController] setFilterPredicate:nil]; 
			}
            NSPrintInfo *pInfo = [NSPrintInfo sharedPrintInfo];
            [pInfo setOrientation:NSLandscapeOrientation];
            NSRect originalFrame = [chromatogramView frame];
            NSAttributedString *originalTitle = [chromatogramView titleString];
            [chromatogramView setTitleString:[[[NSAttributedString alloc] initWithString:[[[document mainWindowController] window] title]] autorelease]];
			NSData *pdfData;
            [chromatogramView setFrame:[pInfo imageablePageBounds]];
            [chromatogramView showAll:self];
            [chromatogramView setShouldDrawShadow:NO];
            [chromatogramView setShouldDrawGrid:NO];
            [chromatogramView setShouldDrawPeaks:NO];
            [chromatogramView setShouldDrawLegend:NO];
            [chromatogramView setShouldDrawBaseline:NO];
            [chromatogramView setLabelFont:[NSFont systemFontOfSize:8.0]];
            pdfData = [chromatogramView dataWithPDFInsideRect:NSMakeRect(-[pInfo imageablePageBounds].origin.x,-[pInfo imageablePageBounds].origin.y,[pInfo paperSize].width,[pInfo paperSize].height)];
            [chromatogramView setFrame:originalFrame];
            [chromatogramView showAll:self];
             [chromatogramView setTitleString:originalTitle];
             [chromatogramView setShouldDrawShadow:YES];
             [chromatogramView setShouldDrawGrid:YES];
             [chromatogramView setShouldDrawPeaks:NO];
             [chromatogramView setShouldDrawLegend:YES];
             [chromatogramView setNeedsDisplay:YES];
             [chromatogramView setLabelFont:[NSFont systemFontOfSize:8.0]];
			if (![pdfData writeToFile:path atomically:YES]) {
				PKLogError(@"ERROR: File at %@ could not be saved as PDF File.",[[files objectAtIndex:i] valueForKey:@"path"]);				
				errorOccurred = YES;
			}
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}		
		if ([[[[NSUserDefaultsController sharedUserDefaultsController] values] valueForKey:@"batchCloseDocument"] boolValue]) {
			[detailStatusTextField setStringValue:NSLocalizedString(@"Closing Document",@"")];
			[document close];
			[fileProgressIndicator incrementBy:1.0];
		}
		if ([self abortAction]) {
			break;
		}
		[fileProgressIndicator setDoubleValue:(i+1)*8.0];
	}
	
	[error release];
	[[self window] makeKeyAndOrderFront:self];

	// This way we don't get bolded text!
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:progressSheet waitUntilDone:NO];
		
	if (errorOccurred) {
		NSRunCriticalAlertPanel(NSLocalizedString(@"Error(s) during batch processing",@""),NSLocalizedString(@"One or more errors occurred during batch processing your files. The console.log available from the Console application contains more details about the error. Common errors include files moved after being added to the list and full disks.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	}
	if ([self abortAction]) {
		NSRunInformationalAlertPanel(NSLocalizedString(@"Batch processing aborted",@""),NSLocalizedString(@"The execution of the batch processing was aborted by the user. Be advised to check the current state of the files that were being processed.",@""),NSLocalizedString(@"OK",@""),nil,nil);
	}
	[pool release];
}

#pragma mark ACCESSORS

idAccessor(files, setFiles)
boolAccessor(abortAction, setAbortAction)

#pragma mark WINDOW MANAGEMENT

- (void)awakeFromNib {
    [[self window] center];
}

#pragma mark SHEETS
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    [sheet orderOut:self];
}
- (void)windowWillBeginSheet:(NSNotification *)notification {
	return;
}
- (void)windowDidEndSheet:(NSNotification *)notification {
	return;
}
@synthesize fileStatusTextField;
@synthesize progressSheet;
@synthesize fileProgressIndicator;
@synthesize detailStatusTextField;
@synthesize addButton;
@synthesize filesTableView;
@synthesize stopButton;
@synthesize runBatchButton;
@end
