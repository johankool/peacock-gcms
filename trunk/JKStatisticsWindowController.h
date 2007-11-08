//
//  JKStatisticsWindowController.h
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005-2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JKGCMSDocument;
@class PKGraphView;
@class JKRatio;
@class JKCombinedPeak;

@interface JKStatisticsWindowController : NSWindowController {
    // Encoded >>> move to JKStatisticsDocument!!
	NSMutableArray *combinedPeaks;
	NSMutableArray *ratioValues;
	NSMutableArray *metadata;
	NSMutableArray *files;
	NSMutableArray *logMessages;
	int peaksToUse;
    int columnSorting;
    BOOL penalizeForRetentionIndex;
    NSNumber *maximumRetentionIndexDifference;
    BOOL setPeakSymbolToNumber;
    NSNumber *matchThreshold;
    int scoreBasis;
    int valueToUse;
    BOOL closeDocuments;
    BOOL calculateRatios;
    BOOL sanityCheck;
    BOOL combinePeaks;
    NSString *keyForValueInSummary;
    BOOL comparePeaks;
    BOOL performSanityCheck;
    BOOL rerunNeeded;
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
    IBOutlet NSTabView *tabView;
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
	IBOutlet id splitView;
    
	// Ratios editor
	IBOutlet NSWindow *ratiosEditor;
	
	// Chromatogram comparison window
    IBOutlet NSScrollView *comparisonScrollView;
    
    IBOutlet NSArrayController *chromatogramDataSeriesController;
    IBOutlet NSArrayController *peaksController;
    IBOutlet PKGraphView *altGraphView;
    
    IBOutlet PKGraphView *loadingsGraphView;
    IBOutlet NSArrayController *loadingsDataSeriesController;
    IBOutlet PKGraphView *scoresGraphView;
    IBOutlet NSArrayController *scoresDataSeriesController;
    
    IBOutlet NSView *printAccessoryView;
}

#pragma mark ACTIONS

- (void)runStatisticalAnalysis;
- (void)collectMetadataForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)collectCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)updateCombinedPeaksForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)doSanityCheckForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)calculateRatiosForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)setupComparisonWindowForDocument:(JKGCMSDocument *)document atIndex:(int)index;
- (void)sortCombinedPeaks;
- (void)insertTableColumns;
- (void)insertGraphDataSeries;

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
- (IBAction)repopulate:(id)sender;
- (IBAction)combinePeaksAction:(id)sender;

#pragma mark IBOutlets
- (NSView *)printAccessoryView;
- (PKGraphView *)altGraphView;
- (PKGraphView *)loadingsGraphView;
- (PKGraphView *)scoresGraphView;
#pragma mark -

#pragma mark CALCULATED ACCESSORS
- (NSPredicate *)filterPredicate;

#pragma mark ACCESSORS
// Mutable To-Many relationship combinedPeak
- (NSMutableArray *)combinedPeaks;
- (void)setCombinedPeaks:(NSMutableArray *)inValue;
- (int)countOfCombinedPeaks;
- (JKCombinedPeak *)objectInCombinedPeaksAtIndex:(int)index;
- (void)getCombinedPeak:(JKCombinedPeak **)someCombinedPeaks range:(NSRange)inRange;
- (void)insertObject:(JKCombinedPeak *)aCombinedPeak inCombinedPeaksAtIndex:(int)index;
- (void)removeObjectFromCombinedPeaksAtIndex:(int)index;
- (void)replaceObjectInCombinedPeaksAtIndex:(int)index withObject:(JKCombinedPeak *)aCombinedPeak;
- (BOOL)validateCombinedPeak:(JKCombinedPeak **)aCombinedPeak error:(NSError **)outError;


// Mutable To-Many relationship ratioValue
- (NSMutableArray *)ratioValues;
- (void)setRatioValues:(NSMutableArray *)inValue;
- (int)countOfRatioValues;
- (NSDictionary *)objectInRatioValuesAtIndex:(int)index;
- (void)getRatioValue:(NSDictionary **)someRatioValues range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aRatioValue inRatioValuesAtIndex:(int)index;
- (void)removeObjectFromRatioValuesAtIndex:(int)index;
- (void)replaceObjectInRatioValuesAtIndex:(int)index withObject:(NSDictionary *)aRatioValue;
- (BOOL)validateRatioValue:(NSDictionary **)aRatioValue error:(NSError **)outError;

// Mutable To-Many relationship ratio
- (NSMutableArray *)ratios;
- (void)setRatios:(NSMutableArray *)inValue;
- (int)countOfRatios;
- (JKRatio *)objectInRatiosAtIndex:(int)index;
- (void)getRatio:(JKRatio **)someRatios range:(NSRange)inRange;
- (void)insertObject:(JKRatio *)aRatio inRatiosAtIndex:(int)index;
- (void)removeObjectFromRatiosAtIndex:(int)index;
- (void)replaceObjectInRatiosAtIndex:(int)index withObject:(JKRatio *)aRatio;
- (BOOL)validateRatio:(JKRatio **)aRatio error:(NSError **)outError;

// Mutable To-Many relationship metadata
- (NSMutableArray *)metadata;
- (void)setMetadata:(NSMutableArray *)inValue;
- (int)countOfMetadata;
- (NSDictionary *)objectInMetadataAtIndex:(int)index;
- (void)getMetadata:(NSDictionary **)someMetadata range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aMetadata inMetadataAtIndex:(int)index;
- (void)removeObjectFromMetadataAtIndex:(int)index;
- (void)replaceObjectInMetadataAtIndex:(int)index withObject:(NSDictionary *)aMetadata;
- (BOOL)validateMetadata:(NSDictionary **)aMetadata error:(NSError **)outError;

// Mutable To-Many relationship file
- (NSMutableArray *)files;
- (void)setFiles:(NSMutableArray *)inValue;
- (int)countOfFiles;
- (NSDictionary *)objectInFilesAtIndex:(int)index;
- (void)getFile:(NSDictionary **)someFiles range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aFile inFilesAtIndex:(int)index;
- (void)removeObjectFromFilesAtIndex:(int)index;
- (void)replaceObjectInFilesAtIndex:(int)index withObject:(NSDictionary *)aFile;
- (BOOL)validateFile:(NSDictionary **)aFile error:(NSError **)outError;

// Mutable To-Many relationship logMessage
- (NSMutableArray *)logMessages;
- (void)setLogMessages:(NSMutableArray *)inValue;
- (int)countOfLogMessages;
- (NSDictionary *)objectInLogMessagesAtIndex:(int)index;
- (void)getLogMessage:(NSDictionary **)someLogMessages range:(NSRange)inRange;
- (void)insertObject:(NSDictionary *)aLogMessage inLogMessagesAtIndex:(int)index;
- (void)removeObjectFromLogMessagesAtIndex:(int)index;
- (void)replaceObjectInLogMessagesAtIndex:(int)index withObject:(NSDictionary *)aLogMessage;
- (BOOL)validateLogMessage:(NSDictionary **)aLogMessage error:(NSError **)outError;

- (BOOL)abortAction;
- (void)setAbortAction:(BOOL)abortAction;

- (BOOL)setPeakSymbolToNumber;
- (void)setSetPeakSymbolToNumber:(BOOL)setPeakSymbolToNumber;

- (NSString *)keyForValueInSummary;
- (void)setKeyForValueInSummary:(NSString *)keyForValueInSummary;

#pragma mark ACCESSORS (MACROSTYLE)

//idAccessor_h(combinedPeaks, setCombinedPeaks)
//idAccessor_h(ratioValues, setRatioValues)
//idAccessor_h(ratios, setRatios)
//idAccessor_h(metadata, setMetadata)
//idAccessor_h(files, setFiles)
//idAccessor_h(logMessages, setLogMessages)
//boolAccessor_h(abortAction, setAbortAction)
//boolAccessor_h(setPeakSymbolToNumber, setSetPeakSymbolToNumber)
intAccessor_h(valueToUse, setValueToUse)
intAccessor_h(peaksToUse, setPeaksToUse)
intAccessor_h(scoreBasis, setScoreBasis)
intAccessor_h(columnSorting, setColumnSorting)
boolAccessor_h(penalizeForRetentionIndex, setPenalizeForRetentionIndex)
idAccessor_h(matchThreshold, setMatchThreshold)
idAccessor_h(maximumRetentionIndexDifference, setMaximumRetentionIndexDifference)
boolAccessor_h(closeDocuments, setCloseDocuments)
boolAccessor_h(calculateRatios, setCalculateRatios)

@property BOOL comparePeaks;
@property BOOL sanityCheck;
@property (retain,getter=scoresGraphView) PKGraphView *scoresGraphView;
@property (retain) NSProgressIndicator *fileProgressIndicator;
@property int unknownCount;
@property (retain) NSTabView *tabView;
@property (retain) NSArrayController *combinedPeaksController;
@property BOOL scrollingViewProgrammatically;
@property (retain) NSWindow *progressSheet;
@property (getter=scoreBasis,setter=setScoreBasis:) int scoreBasis;
@property BOOL combinePeaks;
@property (retain) NSButton *addButton;
@property (getter=setPeakSymbolToNumber,setter=setSetPeakSymbolToNumber:) BOOL setPeakSymbolToNumber;
@property (getter=columnSorting,setter=setColumnSorting:) int columnSorting;
@property BOOL performSanityCheck;
@property (retain,getter=printAccessoryView) NSView *printAccessoryView;
@property (getter=abortAction,setter=setAbortAction:) BOOL abortAction;
@property (retain) NSWindow *ratiosEditor;
@property (getter=valueToUse,setter=setValueToUse:) int valueToUse;
@property BOOL movingColumnsProgramatically;
@property (getter=penalizeForRetentionIndex,setter=setPenalizeForRetentionIndex:) BOOL penalizeForRetentionIndex;
@property (retain) NSTableView *ratiosTable;
@property BOOL rerunNeeded;
@property (retain) NSTableView *resultsTable;
@property (retain) NSArrayController *peaksController;
@property (retain) id splitView;
@property (retain,getter=loadingsGraphView) PKGraphView *loadingsGraphView;
@property (retain) NSTextField *fileStatusTextField;
@property (retain) NSArrayController *metadataController;
@property (retain) NSButton *runBatchButton;
@property (retain) NSButton *doneButton;
@property (retain) NSArrayController *ratiosValuesController;
@property (retain) NSScrollView *ratiosTableScrollView;
@property (retain,getter=altGraphView) PKGraphView *altGraphView;
@property (retain) NSScrollView *metadataTableScrollView;
@property (getter=calculateRatios,setter=setCalculateRatios:) BOOL calculateRatios;
@property (retain) NSButton *stopButton;
@property (retain) NSButton *searchOptionsButton;
@property (retain) NSScrollView *comparisonScrollView;
@property (retain) NSTableView *metadataTable;
@property (retain) NSScrollView *resultsTableScrollView;
@property (retain) NSWindow *summarizeOptionsSheet;
@property (getter=peaksToUse,setter=setPeaksToUse:) int peaksToUse;
@property (retain) NSWindow *optionsSheet;
@property (retain) NSArrayController *chromatogramDataSeriesController;
@property (retain) NSTextField *detailStatusTextField;
@property (retain) NSArrayController *ratiosController;
@property (retain) NSArrayController *loadingsDataSeriesController;
@property (retain) NSTableView *filesTableView;
@property (retain) NSArrayController *scoresDataSeriesController;
@property (getter=closeDocuments,setter=setCloseDocuments:) BOOL closeDocuments;
@end
