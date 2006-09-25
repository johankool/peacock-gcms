//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright (c) 2003-2005 Johan Kool. All rights reserved.
//

@class JKDataModel;
@class JKGCMSDocument;
@class JKLibraryEntry;
@class JKLibrarySearch;
@class JKPeakRecord;
@class JKSpectrum;
@class JKMoleculeView;
@class RBSplitSubview;

#import "MyGraphView.h"

enum JKPeakSelection {
	JKAllPeaks,
	JKIdenitifiedPeaks,
	JKUnidentifiedPeaks,
	JKConfirmedPeaks,
	JKUnconfirmedPeaks
};

@interface JKMainWindowController : NSWindowController <MyGraphViewDelegateProtocol> {
	IBOutlet NSView *mainWindowSplitView;
	
	// Chromatogram
    IBOutlet MyGraphView *chromatogramView;
    IBOutlet NSArrayController *baselineController;
    IBOutlet NSArrayController *chromatogramDataSeriesController;

	// Spectrum
	IBOutlet MyGraphView *spectrumView;
	IBOutlet NSArrayController *spectrumDataSeriesController;

	// Peak list
	IBOutlet NSArrayController *peakController;    
    IBOutlet NSTableView *peaksTable;    

    // Details
    IBOutlet RBSplitSubview *detailsSplitSubview;
    IBOutlet NSTabView *detailsTabView;
    IBOutlet NSView *searchResultsTabViewItemView;
    IBOutlet NSView *detailsTabViewItemView;
    
	// MoleculeView
    IBOutlet JKMoleculeView *moleculeView;
    IBOutlet RBSplitSubview *moleculeSplitSubview;

	// Library
	IBOutlet NSArrayController *searchResultsController;    
    IBOutlet NSTableView *resultsTable;    
	
	// Sheets
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
	
	// Misc
	BOOL abortAction;	
		
	// View options
	BOOL showTICTrace;
	BOOL showSpectrum;
	BOOL showCombinedSpectrum;
	BOOL showLibraryHit;
	BOOL showNormalizedSpectra;
	int showPeaks;
	
	// Printing
	IBOutlet NSView *printAccessoryView;
}

#pragma mark IBACTIONS
- (IBAction)obtainBaseline:(id)sender;
- (IBAction)identifyPeaks:(id)sender;
- (IBAction)renumberPeaks:(id)sender;
- (void)undoRenumberPeaks:(NSArray *)array;
- (IBAction)showMassChromatogram:(id)sender;	
- (void)addMassChromatogram:(id)object;
- (void)removeMassChromatogram:(id)object;
- (IBAction)confirm:(id)sender;
- (IBAction)discard:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)other:(id)sender;
- (IBAction)abort:(id)sender;
- (IBAction)editLibrary:(id)sender;
- (IBAction)fitChromatogramDataToView:(id)sender;
- (IBAction)fitSpectrumDataToView:(id)sender;

#pragma mark NSTOOLBAR MANAGEMENT
- (void)setupToolbar;

#pragma mark ACCESSORS
- (MyGraphView *)chromatogramView;
- (NSArrayController *)baselineController;
- (NSArrayController *)chromatogramDataSeriesController;
- (NSTableView *)peaksTable;
- (NSArrayController *)peakController;
- (NSTableView *)resultsTable;
- (NSArrayController *)searchResultsController;

#pragma mark ACCESSORS (MACROSTYLE)
boolAccessor_h(abortAction, setAbortAction)	
boolAccessor_h(showTICTrace, setShowTICTrace)
boolAccessor_h(showSpectrum, setShowSpectrum)
boolAccessor_h(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor_h(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor_h(showLibraryHit, setShowLibraryHit)
intAccessor_h(showPeaks, setShowPeaks)
idAccessor_h(printAccessoryView, setPrintAccessoryView)
@end
