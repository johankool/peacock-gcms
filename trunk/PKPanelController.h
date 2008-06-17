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

@interface PKPanelController : NSWindowController {
	
	IBOutlet NSView *infoPanelView;
	IBOutlet NSView *processingPanelView;
	IBOutlet NSView *viewPanelView;
	IBOutlet NSView *displayPanelView;
	IBOutlet NSView *naPanelView;
	
    // Info Panel
    IBOutlet NSTableView *infoTableView;

	// Processing Panel
	IBOutlet NSPopUpButton *libraryPopUpButton;
	
    // Display Panel
	IBOutlet NSTextField *titleTextField;
	IBOutlet NSTextField *subTitleTextField;
	IBOutlet NSTextField *xAxisTextField;
	IBOutlet NSTextField *yAxisTextField;
	IBOutlet NSButton *labelFontButton;
    IBOutlet NSButton *legendFontButton;
    IBOutlet NSButton *axesLabelFontButton;
    
	IBOutlet NSObjectController *inspectedDocumentController;
    PKGraphView *inspectedGraphView;
	NSDocument *inspectedDocument;
    
} 

#pragma mark INITIALIZATION

+ (PKPanelController *) sharedController;

#pragma mark IBACTIONS
- (void)changeTextFont:(id)sender;
- (IBAction)showInspector:(id)sender;
- (IBAction)resetToDefaultValues:(id)sender;
- (IBAction)changePanes:(id)sender;

#pragma mark ACCESSORS
idAccessor_h(inspectedGraphView, setInspectedGraphView)
idAccessor_h(inspectedDocument, setInspectedDocument)
- (NSTableView *)infoTableView ;

#pragma mark MENU VALIDATION
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@property (retain) NSTextField *yAxisTextField;
@property (retain) NSButton *legendFontButton;
@property (retain) NSView *viewPanelView;
@property (retain,getter=infoTableView) NSTableView *infoTableView;
@property (retain) NSTextField *titleTextField;
@property (retain) NSView *infoPanelView;
@property (retain) NSPopUpButton *libraryPopUpButton;
@property (retain) NSView *naPanelView;
@property (retain) NSTextField *xAxisTextField;
@property (retain) NSButton *labelFontButton;
@property (retain) NSView *processingPanelView;
@property (retain) NSView *displayPanelView;
@property (retain) NSTextField *subTitleTextField;
@property (retain) NSButton *axesLabelFontButton;
@property (retain) NSObjectController *inspectedDocumentController;
@end
