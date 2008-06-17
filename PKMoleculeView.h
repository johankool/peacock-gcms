//
//  JKMoleculeView.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
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

#import <AppKit/AppKit.h>
#import "AccessorMacros.h"
#import "PKMoleculeModel.h"

#import <LinkBack/LinkBack.h>

@interface PKMoleculeView : NSView <NSCoding> {
    float margin, scaleFactor;
    PKMoleculeModel *model;
    NSColor *backgroundColor, *textColor, *bondColor;
    BOOL fitToView;
	NSFont *font;
	
    // Bindings support
	NSObjectController *moleculeStringContainer;
    NSString *moleculeStringKeyPath;
    
	// private!
	float xOffSet, yOffSet, xScaleFactor, yScaleFactor;
	float bondDistance, textHeight;
    BOOL _isTargettedForDrop;
}


- (void)drawMolecule;
- (void)updateModel;

#pragma mark BINDINGS
- (NSString *)moleculeString;
- (void)setMoleculeString:(NSString *)aMoleculeString;
- (NSObjectController *)moleculeStringContainer;
- (void)setMoleculeStringContainer:(NSArrayController *)aMoleculeStringContainer;
- (NSString *)moleculeStringKeyPath;
- (void)setMoleculeStringKeyPath:(NSString *)aMoleculeStringKeyPath;

floatAccessor_h(margin, setMargin)
floatAccessor_h(scaleFactor, setScaleFactor)
floatAccessor_h(xOffSet, setXOffSet)
floatAccessor_h(yOffSet, setYOffSet)
floatAccessor_h(xScaleFactor, setXScaleFactor)
floatAccessor_h(yScaleFactor, setYScaleFactor)
floatAccessor_h(bondDistance, setBondDistance)
floatAccessor_h(textHeight, setTextHeight)
idAccessor_h(model, setModel)
idAccessor_h(backgroundColor, setBackgroundColor)
idAccessor_h(textColor, setTextColor)
idAccessor_h(bondColor, setBondColor)
idAccessor_h(font, setFont)
boolAccessor_h(fitToView, setFitToView)
@property (getter=fitToView,setter=setFitToView:) BOOL fitToView;
@property BOOL _isTargettedForDrop;
@end
