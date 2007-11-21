//
//  PKGraphicalController.h
//  Peacock
//
//  Created by Johan Kool on 20-11-07.
//  Copyright 2007 Johan Kool. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PKGraphView;

@interface PKGraphicalController : NSWindowController {
    IBOutlet NSArrayController *chromatogramDataSeriesController;
    IBOutlet NSArrayController *peaksController;
    IBOutlet PKGraphView *graphView;
    
    NSMutableArray *chromatogramDataSeries;
    NSMutableArray *peaks;
}

@property (retain) NSMutableArray *chromatogramDataSeries;
@property (retain) NSMutableArray *peaks;

@end
