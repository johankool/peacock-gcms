//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

@class JKDataModel;
@class JKGCMSDocument;
@class JKLibraryEntry;
@class JKLibrarySearch;
@class JKPeakRecord;
@class JKSpectrum;
@class JKMoleculeView;
@class RBSplitSubview;

#import "PKGraphView.h"

enum JKPeakSelection {
	JKAllPeaks,
	JKIdenitifiedPeaks,
	JKUnidentifiedPeaks,
	JKConfirmedPeaks,
	JKUnconfirmedPeaks,
    JKFlaggedPeaks
};

@interface JKMainWindowController : NSWindowController <MyGraphViewDelegateProtocol> {
	IBOutlet NSView *mainWindowSplitView;
	
	// Chromatogram
    IBOutlet PKGraphView *chromatogramView;
    IBOutlet NSTableView *chromatogramsTable;
    IBOutlet NSArrayController *chromatogramDataSeriesController;

	// Spectrum
	IBOutlet PKGraphView *spectrumView;
	IBOutlet NSArrayController *spectrumDataSeriesController;

	// Peak list
	IBOutlet NSArrayController *peakController;    
    IBOutlet NSTableView *peaksTable;    

    // Details
    IBOutlet RBSplitSubview *detailsSplitSubview;
    IBOutlet NSTabView *detailsTabView;
    IBOutlet NSView *searchResultsTabViewItemView;
    IBOutlet NSView *detailsTabViewItemView;
    IBOutlet NSScrollView *detailsTabViewItemScrollView;
    IBOutlet NSBox *identifyCompoundBox;
    IBOutlet NSScrollView *resultsTableScrollView;
    IBOutlet NSButton *confirmLibraryHitButton;
    IBOutlet NSButton *discardLibraryHitButton;
    
	// MoleculeView
    IBOutlet JKMoleculeView *moleculeView;
    IBOutlet RBSplitSubview *moleculeSplitSubview;

	// Library
	IBOutlet NSArrayController *searchResultsController;    
    IBOutlet NSTableView *resultsTable;    
	
	// Sheets
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSTextField *progressText;
	IBOutlet NSWindow *chromatogramSelectionSheet;
	IBOutlet NSButton *chromatogramSelectionSheetButton;
    IBOutlet NSArrayController *chromatogramsController; 
    
    IBOutlet RBSplitSubview *chromatogramsTableSplitView;
    
	// Misc
	BOOL abortAction;	
		
	// View options
	BOOL showTICTrace;
	BOOL showCombinedSpectrum;
	BOOL showLibraryHit;
	BOOL showNormalizedSpectra;
	BOOL showSelectedChromatogramsOnly;
	int showPeaks;
    
	// Printing
	IBOutlet NSView *printAccessoryView;
    
    NSMutableArray *chromatogramDataSeries;
    NSMutableArray *hiddenColumnsPeaksTable;
    
    float _lastDetailsSplitSubviewDimension;
}

#pragma mark IBACTIONS
- (IBAction)obtainBaseline:(id)sender;
- (void)obtainBaselineForSelectedChromatograms:(id)sender;
- (IBAction)identifyPeaks:(id)sender;
- (void)identifyPeaksForSelectedChromatograms:(id)sender;
- (void)identifyCompounds;
- (IBAction)cancel:(id)sender;
- (IBAction)renumberPeaks:(id)sender;
- (IBAction)showMassChromatogram:(id)sender;
- (void)showChromatogramForModel:(NSString *)modelString;
- (void)addMassChromatogram:(id)object;
- (void)removeMassChromatogram:(id)object;
- (IBAction)confirm:(id)sender;
- (IBAction)discard:(id)sender;
- (IBAction)next:(id)sender;
- (IBAction)previous:(id)sender;
- (IBAction)other:(id)sender;
- (IBAction)abort:(id)sender;
//- (IBAction)editLibrary:(id)sender;
- (IBAction)fitChromatogramDataToView:(id)sender;
- (IBAction)fitSpectrumDataToView:(id)sender;
- (IBAction)showSelectedChromatogramsOnlyAction:(id)sender;
- (IBAction)identifyCompound:(id)sender;

- (NSPredicate *)predicateForPeakTypeShow;
- (void)setupChromatogramDataSeries;

#pragma mark NSTOOLBAR MANAGEMENT
- (void)setupToolbar;

#pragma mark ACCESSORS
- (PKGraphView *)chromatogramView;
- (PKGraphView *)spectrumView;
- (NSArrayController *)chromatogramDataSeriesController;
- (NSTableView *)peaksTable;
- (NSArrayController *)peakController;
- (NSArrayController *)chromatogramsController;
- (NSTableView *)resultsTable;
- (NSArrayController *)searchResultsController;
- (NSMutableArray *)hiddenColumnsPeaksTable;
- (NSProgressIndicator *)progressIndicator;
- (NSTextField *)progressText;

#pragma mark ACCESSORS (MACROSTYLE)
boolAccessor_h(abortAction, setAbortAction)	
boolAccessor_h(showTICTrace, setShowTICTrace)
boolAccessor_h(showNormalizedSpectra, setShowNormalizedSpectra)
boolAccessor_h(showCombinedSpectrum, setShowCombinedSpectrum)
boolAccessor_h(showLibraryHit, setShowLibraryHit)
intAccessor_h(showPeaks, setShowPeaks)
idAccessor_h(printAccessoryView, setPrintAccessoryView)
boolAccessor_h(showSelectedChromatogramsOnly, setShowSelectedChromatogramsOnly)

@property (retain) RBSplitSubview *chromatogramsTableSplitView;
@property (retain,getter=chromatogramDataSeriesController) NSArrayController *chromatogramDataSeriesController;
@property (retain,getter=chromatogramsController) NSArrayController *chromatogramsController;
@property (retain,getter=progressText) NSTextField *progressText;
@property (retain) NSTableView *chromatogramsTable;
@property (retain,getter=resultsTable) NSTableView *resultsTable;
@property (retain) NSWindow *chromatogramSelectionSheet;
@property (retain,getter=searchResultsController) NSArrayController *searchResultsController;
@property (getter=showNormalizedSpectra,setter=setShowNormalizedSpectra:) BOOL showNormalizedSpectra;
@property (getter=showLibraryHit,setter=setShowLibraryHit:) BOOL showLibraryHit;
@property (getter=showSelectedChromatogramsOnly,setter=setShowSelectedChromatogramsOnly:) BOOL showSelectedChromatogramsOnly;
@property (retain) NSButton *discardLibraryHitButton;
@property (retain) NSView *detailsTabViewItemView;
@property (retain) RBSplitSubview *detailsSplitSubview;
@property (retain) NSScrollView *detailsTabViewItemScrollView;
@property (retain) NSBox *identifyCompoundBox;
@property (retain) NSScrollView *resultsTableScrollView;
@property (retain,getter=peakController) NSArrayController *peakController;
@property (retain) NSView *mainWindowSplitView;
@property (retain,getter=spectrumView) PKGraphView *spectrumView;
@property (retain) JKMoleculeView *moleculeView;
@property (retain) NSButton *chromatogramSelectionSheetButton;
@property (retain) NSArrayController *spectrumDataSeriesController;
@property (getter=showPeaks,setter=setShowPeaks:) int showPeaks;
@property (getter=abortAction,setter=setAbortAction:) BOOL abortAction;
@property (retain) NSTabView *detailsTabView;
@property (retain,getter=peaksTable) NSTableView *peaksTable;
@property (getter=showCombinedSpectrum,setter=setShowCombinedSpectrum:) BOOL showCombinedSpectrum;
@property float _lastDetailsSplitSubviewDimension;
@property (retain) NSWindow *progressSheet;
@property (retain,getter=hiddenColumnsPeaksTable) NSMutableArray *hiddenColumnsPeaksTable;
@property (retain,getter=progressIndicator) NSProgressIndicator *progressBar;
@property (retain) NSView *searchResultsTabViewItemView;
@property (retain,getter=chromatogramView) PKGraphView *chromatogramView;
@property (retain) NSButton *confirmLibraryHitButton;
@property (retain) RBSplitSubview *moleculeSplitSubview;
@property (getter=showTICTrace,setter=setShowTICTrace:) BOOL showTICTrace;
@end
