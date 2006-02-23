//
//  JKStatisticsWindowController.h
//  Peacock
//
//  Created by Johan Kool on 17-12-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JKStatisticsWindowController : NSWindowController {
	NSMutableArray *combinedPeaks;
	NSMutableArray *ratioValues;
	NSMutableArray *ratios;
	NSMutableArray *metadata;
	IBOutlet NSTableView *resultsTable;
	IBOutlet NSArrayController *combinedPeaksController;
	IBOutlet NSTableView *ratiosTable;
	IBOutlet NSArrayController *ratiosValuesController;
	IBOutlet NSArrayController *ratiosController;
	IBOutlet NSTableView *metadataTable;
	IBOutlet NSArrayController *metadataController;
	
	IBOutlet NSWindow *ratiosEditor;
	IBOutlet NSWindow *optionsSheet;
	
	BOOL movingColumnsProgramatically;
	BOOL scrollingViewProgrammatically;
}

-(IBAction)refetch:(id)sender;
-(IBAction)editRatios:(id)sender;
//-(IBAction)cancelEditRatios:(id)sender;
-(IBAction)saveEditRatios:(id)sender;
-(IBAction)options:(id)sender;
-(IBAction)doneOptions:(id)sender;

-(void)collectMetadata;
-(void)collectCombinedPeaks;
-(void)calculateRatios;


idAccessor_h(combinedPeaks, setCombinedPeaks);
idAccessor_h(ratioValues, setRatioValues);
idAccessor_h(ratios, setRatios);

@end
