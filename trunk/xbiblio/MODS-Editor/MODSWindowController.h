//
//  MODSWindowController.h
//  MODS Editor
//
//  Created by Johan Kool on 7-10-05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AccessorMacros.h"
#import "MODSEntryXMLModel.h"

@interface MODSWindowController : NSWindowController {
	IBOutlet NSTableView *entriesTableView;
	IBOutlet NSView *detailedView;
	
	IBOutlet NSArrayController *entriesController;
}

#pragma mark NSTOOLBAR MANAGEMENT
-(void)setupToolbar;

-(void)setupDetailedViewForEntry:(MODSEntryXMLModel *)entry;
-(NSView *)detailViewOfType:(int)viewType forElement:(id)element;
-(NSView *)detailViewOfType:(int)viewType;

@end
