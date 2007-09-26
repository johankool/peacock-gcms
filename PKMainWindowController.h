//
//  PKMainWindowController.h
//  Peacock1
//
//  Created by Johan Kool on 11-09-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKChromatogramView;
@class PKSpectrumView;

@interface PKMainWindowController : NSWindowController {
    NSMutableArray *tree;
    
    IBOutlet NSOutlineView *treeView;
    IBOutlet NSTabView *mainTabView;
    IBOutlet NSView *measurementsView;
    IBOutlet NSTableView *measurementsTableView;
    IBOutlet NSView *measurementView;
    IBOutlet PKChromatogramView *chromatogramView;
    IBOutlet NSTabView *measurementTabView;
    IBOutlet NSTableView *peaksTableView;
    IBOutlet PKSpectrumView *spectrumView;
    
}

@end
