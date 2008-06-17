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

@interface PKMassWeightController : NSWindowController {
    IBOutlet id contents;
    IBOutlet id formula;
    IBOutlet id lowerCase;
    IBOutlet id status;
    IBOutlet id statusIcon;
    IBOutlet id weight;
    IBOutlet id panelWindow;
}
- (IBAction)calculate:(id)sender;
- (IBAction)clear:(id)sender;
- (void)showError:(BOOL)input;
- (IBAction)openPanel:(id)sender;

@property (retain) id lowerCase;
@property (retain) id panelWindow;
@property (retain) id formula;
@property (retain) id contents;
@property (retain) id statusIcon;
@property (retain) id weight;
@property (retain) id status;
@end
