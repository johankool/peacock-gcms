//
//  PKGraphicalController.h
//  Peacock
//
//  Created by Johan Kool on 20-11-07.
//  Copyright 2007-2008 Johan Kool.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>

@class PKGraphView;

@interface PKGraphicalController : NSWindowController {
    IBOutlet NSArrayController *chromatogramDataSeriesController;
    IBOutlet NSArrayController *peaksController;
    IBOutlet PKGraphView *graphView;
    IBOutlet NSScrollView *scrollView;
    
    NSMutableArray *chromatogramDataSeries;
    NSMutableArray *peaks;
}


- (PKGraphView *)graphView;

- (void)sharedPrintInfoUpdated;

@property (retain) NSMutableArray *chromatogramDataSeries;
@property (retain) NSMutableArray *peaks;

@end
