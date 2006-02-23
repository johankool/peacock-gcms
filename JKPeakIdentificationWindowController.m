//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

#import "JKPeakIdentificationWindowController.h"
#import "JKMainWindowController.h"
#import "MyGraphView.h"
#import "SpectrumGraphDataSerie.h"
#import "JKPeakRecord.h"
#import "JKLibrarySearch.h"
#import "JKSpectrum.h"

@implementation JKPeakIdentificationWindowController

#pragma mark INITIALIZATION

-(id)init
{
    if (self = [super initWithWindowNibName:@"JKPeakIdentification"]) {
        [self setShouldCloseDocument:NO]; // Only close document with the last window to be closed
		[self setShowIdentificationWindow:NO];
		
		[self setLibSearch:[[JKLibrarySearch alloc] init]];		
		[libSearch setProgressIndicator:progressBar];
		
	}

    return self;
}

-(void)windowDidLoad {
	[previousButton bind:@"enabled" toObject:[[[self document] mainWindowController] peakController] withKeyPath:@"canSelectPrevious" options:nil];
	[nextButton bind:@"enabled" toObject:[[[self document] mainWindowController] peakController] withKeyPath:@"canSelectNext" options:nil];

	[[self window] center];
	
//	[spectrumDataSeriesController bind:@"content" toObject: spectrumDataSeriesController				   withKeyPath:@"arrangedObjects" options:nil];
	
	[spectrumView bind:@"dataSeries" toObject: spectrumDataSeriesController
		   withKeyPath:@"arrangedObjects" options:nil];
	[spectrumView bind:@"dataSeriesSelectionIndexes" toObject: spectrumDataSeriesController
		   withKeyPath:@"selectionIndexes" options:nil];

	[resultsView bind:@"dataSeries" toObject: resultsDataSeriesController
		   withKeyPath:@"arrangedObjects" options:nil];
	[resultsView bind:@"dataSeriesSelectionIndexes" toObject: resultsDataSeriesController
		   withKeyPath:@"selectionIndexes" options:nil];
	
	
	
	[spectrumView setShouldDrawLabels:NO];
	[spectrumView setShouldDrawLegend:NO];
	[spectrumView setPlottingArea:NSMakeRect(30,20,[spectrumView bounds].size.width-40,[spectrumView bounds].size.height-30)];
	[spectrumView setBackColor:[NSColor clearColor]];
	[resultsView setShouldDrawLabels:NO];
	[resultsView setShouldDrawLegend:NO];
	[resultsView setPlottingArea:NSMakeRect(30,20,[resultsView bounds].size.width-40,[resultsView bounds].size.height-30)];
	[resultsView setBackColor:[NSColor clearColor]];

	[[[[self document] mainWindowController] peakController] addObserver:self forKeyPath:@"selection" options:nil context:nil];
	[[self searchResultsController] addObserver:self forKeyPath:@"selection" options:nil context:nil];
	[self addObserver:self forKeyPath:@"currentPeak" options:nil context:nil];
	
	if ([[[[self document] mainWindowController] peakController] selectionIndex] != NSNotFound) {
		[self setCurrentPeak:[[[[[self document] mainWindowController] peakController] selectedObjects] objectAtIndex:0]];			
	} else {
		[self setCurrentPeak:[[[[[self document] mainWindowController] peakController] arrangedObjects] objectAtIndex:0]];			
		[[[[self document] mainWindowController] peakController] setSelectionIndex:0];
	}
	
}


-(void)dealloc {
    [super dealloc];
}

#pragma mark ACCESSORS

-(JKDataModel *)dataModel{
    return [[self document] dataModel];
}

-(NSTableView *)resultsTable {
	return resultsTable;
}

-(JKPeakRecord *)currentPeak {
    return currentPeak;
}
-(void)setCurrentPeak:(JKPeakRecord *)inValue {
	[inValue retain];
	[currentPeak autorelease];
	currentPeak = inValue;
}

-(NSArrayController *)searchResultsController {
    return searchResultsController;
}
boolAccessor(abortAction, setAbortAction)
boolAccessor(showIdentificationWindow, setShowIdentificationWindow)


# pragma mark IBACTIONS

-(IBAction)confirm:(id)sender {
	NSAssert(currentPeak != NULL, @"CurrentPeak is not defined.");
	if ([[[self currentPeak] valueForKey:@"identified"] boolValue] == NO) {
		[currentPeak setValue:[NSNumber numberWithBool:YES] forKey:@"identified"];
		[[self currentPeak] setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"score"] forKey:@"score"];
		[[self currentPeak] setLibraryHit:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"libraryHit"]];
		[[self currentPeak] setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.name"] forKey:@"label"];
		[[self currentPeak] setValue:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKeyPath:@"libraryHit.symbol"] forKey:@"symbol"];
		[[self currentPeak] setValue:[[[NSUserDefaults standardUserDefaults] valueForKey:@"defaultLibrary"] lastPathComponent] forKey:@"library"];
		
	}
	[currentPeak setValue:[NSNumber numberWithBool:YES] forKey:@"confirmed"];
	
}

-(IBAction)next:(id)sender{
	int i;
	i = [[[[self document] mainWindowController] peakController] selectionIndex]; 
	[[[[self document] mainWindowController] peakController] setSelectionIndex:i+1]; 
}

-(IBAction)previous:(id)sender{
	int i;
	i = [[[[self document] mainWindowController] peakController] selectionIndex]; 
	[[[[self document] mainWindowController] peakController] setSelectionIndex:i-1]; 
}

-(IBAction)search:(id)sender{
	NSAssert(currentPeak != NULL, @"currentPeak is not defined.");
	NSAssert(libSearch != NULL, @"libSearch is not defined.");
	NSAssert([[self document] mainWindowController] != NULL, @"[[self document] mainWindowController] is not defined.");
	NSAssert(searchResultsController != NULL, @"searchResultsController is not defined.");
	[searchingIndicator startAnimation:self];
	
	// Reset any previous search results
	[[self currentPeak] setValue:@"" forKey:@"label"];
	[[self currentPeak] setValue:@"" forKey:@"score"];
	[[self currentPeak] setValue:@"" forKey:@"symbol"];
	[[self currentPeak] setLibraryHit:[[[JKLibraryEntry alloc] init] autorelease]];
	[[self currentPeak] setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
	[[self currentPeak] setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];

	
	[NSThread detachNewThreadSelector:@selector(search) toTarget:self withObject:nil];
	[searchingIndicator stopAnimation:self];
//	// Reset any previous search results
////	[[self currentPeak] setValue:@"" forKey:@"label"];
//	[[self currentPeak] setValue:@"" forKey:@"score"];
//	[[self currentPeak] setLibraryHit:[NSMutableDictionary dictionary]];
//	[[self currentPeak] setValue:[NSNumber numberWithBool:NO] forKey:@"identified"];
//	[[self currentPeak] setValue:[NSNumber numberWithBool:NO] forKey:@"confirmed"];
//
//	JKSpectrum *spectrum;
//	spectrum = [[[self document] mainWindowController] getSpectrumForPeak:[self currentPeak]];
//	
//	NSMutableArray *results;
//	results = [self searchLibraryForSpectrum:spectrum inTimeRadius:0.5];
//	
//	// Sort the array
//	NSSortDescriptor *scoreDescriptor = [[[NSSortDescriptor alloc] initWithKey:@"score"  ascending:NO] autorelease];
//	NSArray *sortDescriptors=[NSArray arrayWithObject:scoreDescriptor];
//	results = [[results sortedArrayUsingDescriptors:sortDescriptors] mutableCopy];
//	
//	[searchResultsController setContent:results];
}

-(IBAction)searchOptions:(id)sender{
    [NSApp beginSheet: searchOptionsSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}


-(IBAction)displayAutopilotSheet:(id)sender{
    [NSApp beginSheet: autopilotSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}

-(IBAction)autopilotAction:(id)sender{
	[NSApp endSheet:autopilotSheet];

    [NSApp beginSheet: progressSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop

	[NSThread detachNewThreadSelector:@selector(autopilot) toTarget:self withObject:nil];
}
-(IBAction)other:(id)sender{
    [NSApp beginSheet: addSheet
	   modalForWindow: [self window]
		modalDelegate: self
	   didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
		  contextInfo: nil];
    // Sheet is up here.
    // Return processing to the event loop
}

-(IBAction)closeAutopilotSheet:(id)sender {
    [NSApp endSheet:autopilotSheet];
}

-(IBAction)closeAddSheet:(id)sender {
    [NSApp endSheet:addSheet];
}
-(IBAction)closeSearchOptionsSheet:(id)sender{
    [NSApp endSheet:searchOptionsSheet];
}

-(IBAction)abort:(id)sender {
    [[self libSearch] setAbortAction:YES];
}

# pragma mark SHEETS
- (void)didEndSheet:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    [sheet orderOut:self];
}
- (void)windowWillBeginSheet:(NSNotification *)notification {
	return;
}
- (void)windowDidEndSheet:(NSNotification *)notification {
	return;
}


# pragma mark ACTIONS
-(void)search {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	[libSearch setMainWindowController:[[self document] mainWindowController]];

	
	[searchResultsController setSelectsInsertedObjects:NO];
	[searchResultsController setContent:[[libSearch searchLibraryForPeak:currentPeak] retain]];
	[searchResultsController setSelectsInsertedObjects:YES];
	[searchResultsController setSelectionIndex:0];
	[resultsTable reloadData];
	
	[pool release]; 
}


-(void)autopilot {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSArray *peaksArray = [[[[self document] mainWindowController] peakController] arrangedObjects];
	[libSearch setMainWindowController:[[self document] mainWindowController]];
	[libSearch setProgressIndicator:progressBar];

	[libSearch searchLibraryForPeaks:peaksArray];

	if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"soundWhenFinished"] boolValue]) NSBeep();	
	[NSApp endSheet:progressSheet];	
	[pool release]; 
}

-(void)displaySpectrum:(JKSpectrum *)spectrum {
	SpectrumGraphDataSerie *spectrumDataSerie;
	
	// Clear current content
	[(NSArrayController*)[spectrumView dataSeriesContainer] remove:self];
	
	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
//	[spectrumDataSerie setDataArray:[spectrum points]];
	[spectrumDataSerie loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];

	[(NSArrayController*)[spectrumView dataSeriesContainer] addObject:spectrumDataSerie];
	
	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
	
	[spectrumView setKeyForXValue:@"Mass"];
	[spectrumView setKeyForYValue:@"Intensity"];
	
	[spectrumDataSerie setKeyForXValue:[spectrumView keyForXValue]];
	[spectrumDataSerie setKeyForYValue:[spectrumView keyForYValue]];
	
    //set plot properties object  
	//	[spectrum setSeriesTitle:[peak valueForKey:@"label"]]; BAD!!! because seriestitle expects attributed string?!
	[spectrumView showAll:self];
	[spectrumView setNeedsDisplay:YES];	
	[spectrumDataSerie release];
}

-(void)displayResult:(JKLibraryEntry *)spectrum {
				[resultsView setHidden:NO];

	SpectrumGraphDataSerie *spectrumDataSerie;
	
	// Clear current content
	[(NSArrayController*)[resultsView dataSeriesContainer] remove:self];
	
	spectrumDataSerie = [[SpectrumGraphDataSerie alloc] init];
//	if ([resultsPopup selectedTag] == 0) {
//		
//	} else if ([resultsPopup selectedTag] == 1) {
//		JKSpectrum *spectrumPeak;
//		spectrumPeak = [[[self document] mainWindowController] getSpectrumForPeak:[self currentPeak]];
//		[spectrumPeak normalizeSpectrum];
//		[spectrum normalizeSpectrum];
//		spectrum = [spectrum spectrumBySubtractingSpectrum:spectrumPeak];
//	}
	
//	[spectrumDataSerie setDataArray:[spectrum points]];
	NSAssert([spectrum isKindOfClass:[JKLibraryEntry class]], @"spectrum isn't a JKLibraryEntry");
	NSAssert(spectrum != NULL, @"spectrum is nil");
	[spectrumDataSerie loadDataPoints:[spectrum numberOfPoints] withXValues:[spectrum masses] andYValues:[spectrum intensities]];
	
	[(NSArrayController*)[resultsView dataSeriesContainer] addObject:spectrumDataSerie];
	
	[spectrumDataSerie setSeriesType:2]; // Spectrum kind of plot
	
	[resultsView setKeyForXValue:@"Mass"];
	[resultsView setKeyForYValue:@"Intensity"];
	
	[spectrumDataSerie setKeyForXValue:[resultsView keyForXValue]];
	[spectrumDataSerie setKeyForYValue:[resultsView keyForYValue]];

    //set plot properties object  
	//	[spectrum setSeriesTitle:[peak valueForKey:@"label"]]; BAD!!! because seriestitle expects attributed string?!
	[resultsView showAll:self];
	[resultsView setXMinimum:[spectrumView xMinimum]];
	[resultsView setXMaximum:[spectrumView xMaximum]];

	[resultsView setNeedsDisplay:YES];	
	[spectrumDataSerie release];

}

# pragma mark KEY VALUE OBSERVATION
- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)object
						change:(NSDictionary *)change
					   context:(void *)context {
	if (object == [self searchResultsController]) {
		if ([searchResultsController selectionIndex] != NSNotFound) {
			[self displayResult:[[[searchResultsController selectedObjects] objectAtIndex:0] valueForKey:@"libraryHit"]];
		}
	} else if (object == [[[self document] mainWindowController] peakController]) {
		if ([[[[self document] mainWindowController] peakController] selectionIndex] != NSNotFound) {
			[self setCurrentPeak:[[[[[self document] mainWindowController] peakController] selectedObjects] objectAtIndex:0]];			
		} else {
			[self setCurrentPeak:[[[[[self document] mainWindowController] peakController] arrangedObjects] objectAtIndex:0]];			
			[[[[self document] mainWindowController] peakController] setSelectionIndex:0];
		}
	} else if ([keyPath isEqualToString:@"currentPeak"]) {
		JKSpectrum *spectrum;
		spectrum = [[[self document] mainWindowController] getSpectrumForPeak:[self currentPeak]];
		
		[spectrum normalizeSpectrum];
		[self displaySpectrum:spectrum];

		// Is there already a searchresult?	
		if ([[self currentPeak] identified] == NO) {
			[resultsView setHidden:YES];
			//[self search:self];		
		} else {
			[self displayResult:[[self currentPeak] valueForKeyPath:@"libraryHit"]];			
		}
	}
}


# pragma mark WINDOW MANAGEMENT

-(NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
    return [displayName stringByAppendingString:NSLocalizedString(@" - Peak Identification",@"Description added to title of Peak Identification window")];
}

#pragma mark ACCESSORS
idAccessor(libSearch, setLibSearch)

@end
