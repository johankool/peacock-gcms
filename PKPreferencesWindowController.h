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

@interface PKPreferencesWindowController : NSWindowController {
	IBOutlet NSView *generalPreferencesView;
	IBOutlet NSView *processingPreferencesView;
	IBOutlet NSView *presetsPreferencesView;
	IBOutlet NSView *ratiosPreferencesView;
	IBOutlet NSView *displayPreferencesView;
	IBOutlet NSView *searchTemplatesPreferencesView;
}

- (IBAction)changeAutoSaveAction:(id)sender;
- (IBAction)changeLogLevelAction:(id)sender;
- (IBAction)showInFinder:(id)sender;
- (IBAction)reloadLibrary:(id)sender;

@property (retain) NSView *presetsPreferencesView;
@property (retain) NSView *displayPreferencesView;
@property (retain) NSView *searchTemplatesPreferencesView;
@property (retain) NSView *generalPreferencesView;
@property (retain) NSView *ratiosPreferencesView;
@property (retain) NSView *processingPreferencesView;
@end
