//
//  This file is part of the application with the working name:
//  Peacock
//
//  Created by Johan Kool.
//  Copyright 2003-2008 Johan Kool.
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

@class PKGraphView;
@class PKLibraryEntry;
@class PKMoleculeView;

@interface PKLibraryWindowController : NSWindowController {
	IBOutlet NSArrayController *libraryController;
	IBOutlet NSArrayController *spectrumViewDataseriesController;
	IBOutlet PKGraphView *spectrumView;
	IBOutlet NSTableView *tableView;
	IBOutlet PKMoleculeView *moleculeView;
    IBOutlet NSTextField *casNumberField;
    IBOutlet NSWindow *addCasNumberSheet;
    IBOutlet NSScrollView *detailsScrollView;
    BOOL showNormalizedSpectra;
}

#pragma mark ACITONS
- (IBAction)addCasNumber:(id)sender;
- (IBAction)showAddCasNumber:(id)sender;
- (IBAction)cancelCasNumber:(id)sender;
//- (void)displaySpectrum:(JKLibraryEntry *)spectrum;
- (BOOL)validateCASNumber:(id *)ioValue error:(NSError **)outError;

#pragma mark ACCESSORS
- (NSArrayController *)libraryController;

@property (retain) PKGraphView *spectrumView;
@property (retain) NSTableView *tableView;
@property BOOL showNormalizedSpectra;
@property (retain,getter=libraryController) NSArrayController *libraryController;
@property (retain) NSWindow *addCasNumberSheet;
@property (retain) PKMoleculeView *moleculeView;
@property (retain) NSTextField *casNumberField;
@property (retain) NSArrayController *spectrumViewDataseriesController;
@end
