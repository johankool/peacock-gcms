//
//  JKStatisticsWindowController.h
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGCMSDocument;
@class MyGraphView;

@interface JKStatisticsWindowController : NSWindowController {
    // Encoded
	NSMutableArray *combinedPeaks;
	NSMutableArray *ratioValues;
	NSMutableArray *metadata;
	NSMutableArray *files;
	NSMutableArray *logMessages;
	int peaksToUse;
    int columnSorting;
    BOOL penalizeForRetentionIndex;
    BOOL setPeakSymbolToNumber;
    NSNumber *matchThreshold;
    int scoreBasis;
    int valueToUse;
    BOOL closeDocuments;
    BOOL calculateRatios;
    // end Encoded
    
    NSMutableArray *ratios;
	BOOL abortAction;
	BOOL movingColumnsProgramatically;
	BOOL scrollingViewProgrammatically;
	int unknownCount;
	
	// Main window
	IBOutlet NSButton *addButton;
	IBOutlet NSButton *searchOptionsButton;
	IBOutlet NSButton *runBatchButton;
	IBOutlet NSTableView *filesTableView;
	
	// Search Options sheet
	IBOutlet NSWindow *optionsSheet;
	IBOutlet NSWindow *summarizeOptionsSheet;
	IBOutlet NSButton *doneButton;
	
	// Progress sheet
	IBOutlet NSWindow *progressSheet;
	IBOutlet NSProgressIndicator *fileProgressIndicator;
	IBOutlet NSButton *stopButton;
	IBOutlet NSTextField *fileStatusTextField;
	IBOutlet NSTextField *detailStatusTextField;

	// Summary window
	IBOutlet NSWindow *summaryWindow;
	IBOutlet NSTableView *resultsTable;
	IBOutlet NSScrollView *resultsTableScrollView;
	IBOutlet NSArrayController *combinedPeaksController;
	IBOutlet NSTableView *ratiosTable;
	IBOutlet NSScrollView *ratiosTableScrollView;
	IBOutlet NSArrayController *ratiosValuesController;
	IBOutlet NSArrayController *ratiosController;
	IBOutlet NSTableView *metadataTable;
	IBOutlet NSScrollView *metadataTableScrollView;
	IBOutlet NSArrayController *metadataController;
	
	// Ratios editor
	IBOutlet NSWindow *ratiosEditor;
	
	// Chromatogram comparison window
	IBOutlet NSWindow *comparisonWindow;
	IBOutlet NSScrollView *comparisonScrollView;
    
    IBOutlet NSArrayController *chromatogramDataSeriesController;
    IBOutlet NSArrayController *peaksController;
    IBOutlet MyGraphView *altGraphView;
}

#pragma mark ACTIONS

- (void)runStatisticalAnalysis;
- (void)collectMetadataForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)collectCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)doSanityCheckForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)calculateRatiosForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)setupComparisonWindowForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)sortCombinedPeaks;
- (void)insertTableColumns;

#pragma mark IBACTIONS

- (IBAction)addButtonAction:(id)sender;
- (IBAction)editRatios:(id)sender;
- (IBAction)cancelEditRatios:(id)sender;
- (IBAction)saveEditRatios:(id)sender;
- (IBAction)options:(id)sender;
- (IBAction)summarizeOptionsDoneAction:(id)sender;
- (IBAction)exportSummary:(id)sender;
- (IBAction)runStatisticalAnalysisButtonAction:(id)sender;
- (IBAction)stopButtonAction:(id)sender;

#pragma mark ACCESSORS

- (NSWindow *)summaryWindow;

#pragma mark ACCESSORS (MACROSTYLE)

idAccessor_h(combinedPeaks, setCombinedPeaks)
idAccessor_h(ratioValues, setRatioValues)
idAccessor_h(ratios, setRatios)
idAccessor_h(metadata, setMetadata)
idAccessor_h(files, setFiles)
idAccessor_h(logMessages, setLogMessages)
boolAccessor_h(abortAction, setAbortAction)
boolAccessor_h(setPeakSymbolToNumber, setSetPeakSymbolToNumber)
intAccessor_h(valueToUse, setValueToUse)
intAccessor_h(peaksToUse, setPeaksToUse)
intAccessor_h(scoreBasis, setScoreBasis)
intAccessor_h(columnSorting, setColumnSorting)
boolAccessor_h(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor_h(matchThreshold, setMatchThreshold)
boolAccessor_h(closeDocuments, setCloseDocuments)
boolAccessor_h(calculateRatios, setCalculateRatios)

@end
