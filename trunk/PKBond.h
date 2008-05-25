//
//  JKBond.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PKAtom.h"

@interface PKBond : NSObject <NSCoding> {
    PKAtom *fromAtom;
    PKAtom *toAtom;
    int bondKind;
	int bondStereo;
	int notUsed;
	int bondTopology;
	int reactingCenterStatus;
}

@property (retain) PKAtom *fromAtom;
@property (retain) PKAtom *toAtom;
@property (getter=bondKind,setter=setBondKind:) int bondKind;
@property (getter=notUsed,setter=setNotUsed:) int notUsed;
@property (getter=reactingCenterStatus,setter=setReactingCenterStatus:) int reactingCenterStatus;
@property (getter=bondTopology,setter=setBondTopology:) int bondTopology;
@property (getter=bondStereo,setter=setBondStereo:) int bondStereo;

@end
