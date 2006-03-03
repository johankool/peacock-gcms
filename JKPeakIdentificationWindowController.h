//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKDataModel;
@class JKSpectrum;
@class MyGraphView;
@class JKPeakRecord;
@class JKLibrarySearch;
@class JKLibraryEntry;

@interface JKPeakIdentificationWindowController : NSWindowController {
    IBOutlet NSArrayController *searchResultsController;    
    IBOutlet NSTableView *resultsTable;    
	IBOutlet MyGraphView *spectrumView;
	IBOutlet NSArrayController *spectrumDataSeriesController;

	IBOutlet MyGraphView *resultsView;
	IBOutlet NSArrayController *resultsDataSeriesController;

	IBOutlet NSPopUpButton *spectrumPopup;
	IBOutlet NSPopUpButton *resultsPopup;
	IBOutlet NSWindow *addSheet;
	IBOutlet NSWindow *autopilotSheet;
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSProgressIndicator *searchingIndicator;
	IBOutlet NSWindow *searchOptionsSheet;
	
	IBOutlet NSButton *nextButton;
	IBOutlet NSButton *previousButton;
	
//	NSMutableArray *theLibrary;
	NSData *theLibrary;
	JKPeakRecord *currentPeak;
	BOOL abortAction;
	BOOL showIdentificationWindow;
	
	JKLibrarySearch *libSearch;
}

#pragma mark ACCESSORS

-(JKDataModel *)dataModel;
-(NSTableView *)resultsTable;
-(JKPeakRecord *)currentPeak;
-(void)setCurrentPeak:(JKPeakRecord *)inValue;
-(NSArrayController *)searchResultsController;
idAccessor_h(libSearch, setLibSearch)
boolAccessor_h(abortAction, setAbortAction)
boolAccessor_h(showIdentificationWindow, setShowIdentificationWindow)

# pragma mark ACTIONS
-(IBAction)confirm:(id)sender;
-(IBAction)next:(id)sender;
-(IBAction)previous:(id)sender;
-(IBAction)search:(id)sender;
-(IBAction)displayAutopilotSheet:(id)sender;
-(IBAction)searchOptions:(id)sender;
-(IBAction)other:(id)sender;
-(IBAction)closeAddSheet:(id)sender;
-(IBAction)closeAutopilotSheet:(id)sender;
-(IBAction)closeSearchOptionsSheet:(id)sender;
-(IBAction)autopilotAction:(id)sender;
-(IBAction)abort:(id)sender;
-(void)autopilot;

//-(NSMutableArray *)searchLibraryForSpectrum:(JKSpectrum *)inSpectrum inTimeRadius:(float)timeRadius;
-(void)displaySpectrum:(JKSpectrum *)spectrum;
-(void)displayResult:(JKLibraryEntry *)spectrum;
@end
