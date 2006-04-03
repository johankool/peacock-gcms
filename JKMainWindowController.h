//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKMainDocument;
@class MyGraphView;
@class JKDataModel;
@class JKSpectrum;
@class JKPeakRecord;
@class JKLibrarySearch;
@class JKLibraryEntry;

enum JKPeakSelection {
	JKAllPeaks,
	JKIdenitifiedPeaks,
	JKUnidentifiedPeaks,
	JKConfirmedPeaks,
	JKUnconfirmedPeaks
};

@interface JKMainWindowController : NSWindowController {
	IBOutlet NSView *mainWindowSplitView;
	
	// Chromatogram
    IBOutlet MyGraphView *chromatogramView;
	IBOutlet NSObjectController *mainController;
    IBOutlet NSArrayController *baselineController;
    IBOutlet NSArrayController *chromatogramDataSeriesController;

	// Spectrum
	IBOutlet MyGraphView *spectrumView;
	IBOutlet NSArrayController *spectrumDataSeriesController;

	// Peak list
	IBOutlet NSArrayController *peakController;    
    IBOutlet NSTableView *peaksTable;    
	
	// Library
	IBOutlet NSArrayController *searchResultsController;    
    IBOutlet NSTableView *resultsTable;    
	
	// Sheets
	IBOutlet NSWindow *addSheet;
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
	IBOutlet NSWindow *searchOptionsSheet;
	
	// Misc
	BOOL abortAction;	
	JKLibrarySearch *libSearch;
		
	BOOL showTICTrace;
	BOOL showSpectrum;
	BOOL showCombinedSpectrum;
	BOOL showLibraryHit;
	BOOL showNormalizedSpectra;
	int showPeaks;
	
	IBOutlet NSView *printAccessoryView;

}


# pragma mark ACTIONS
-(void)identifyPeaks;
-(void)displaySpectrum:(JKSpectrum *)spectrum;
-(void)displayResult:(JKLibraryEntry *)libraryEntry;

#pragma mark IBACTIONS
-(IBAction)identifyPeaks:(id)sender;
-(IBAction)renumberPeaks:(id)sender;
-(void)undoRenumberPeaks:(NSArray *)array;
-(IBAction)showMassChromatogram:(id)sender;	
-(void)addMassChromatogram:(id)object;
-(void)removeMassChromatogram:(id)object;
-(IBAction)confirm:(id)sender;
-(IBAction)next:(id)sender;
-(IBAction)previous:(id)sender;
-(IBAction)search:(id)sender;
-(IBAction)searchOptions:(id)sender;
-(IBAction)other:(id)sender;
-(IBAction)closeAddSheet:(id)sender;
-(IBAction)closeSearchOptionsSheet:(id)sender;
-(IBAction)browseForDefaultLibrary:(id)sender;
-(IBAction)abort:(id)sender;
-(IBAction)editLibrary:(id)sender;
-(IBAction)fitChromatogramDataToView:(id)sender;
-(IBAction)fitSpectrumDataToView:(id)sender;

#pragma mark NSTOOLBAR MANAGEMENT
-(void)setupToolbar;

#pragma mark ACCESSORS
-(JKDataModel *)dataModel;
-(MyGraphView *)chromatogramView;
-(NSArrayController *)baselineController;
-(NSArrayController *)chromatogramDataSeriesController;
-(NSTableView *)peaksTable;
-(NSArrayController *)peakController;
-(NSTableView *)resultsTable;
-(NSArrayController *)searchResultsController;

#pragma mark ACCESSORS (MACROSTYLE)
idAccessor_h(libSearch, setLibSearch)
boolAccessor_h(abortAction, setAbortAction)	
boolAccessor_h(showTICTrace, setShowTICTrace)
boolAccessor_h(showSpectrum, setShowSpectrum)
boolAccessor_h(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor_h(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor_h(showLibraryHit, setShowLibraryHit)
intAccessor_h(showPeaks, setShowPeaks)
idAccessor_h(printAccessoryView, setPrintAccessoryView);
@end
