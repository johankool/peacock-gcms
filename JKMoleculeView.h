//
//  JKMoleculeView.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "AccessorMacros.h"
#import "JKMoleculeModel.h"

#import <LinkBack/LinkBack.h>

@interface JKMoleculeView : NSView <NSCoding> {
    float margin, scaleFactor;
    JKMoleculeModel *model;
    NSColor *backgroundColor, *textColor, *bondColor;
    BOOL fitToView;
	NSFont *font;
	
	// private!
	float xOffSet, yOffSet, xScaleFactor, yScaleFactor;
	float bondDistance, textHeight;
    BOOL _isTargettedForDrop;
}

//- (void)initWithString:(NSString *)inString;

- (void)drawMolecule;

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
@end
