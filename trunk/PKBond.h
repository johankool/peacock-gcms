//
//  JKBond.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessorMacros.h"

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


idAccessor_h(fromAtom,setFromAtom)
idAccessor_h(toAtom,setToAtom)
intAccessor_h(bondKind,setBondKind)
intAccessor_h(bondStereo,setBondStereo)
intAccessor_h(notUsed,setNotUsed)
intAccessor_h(bondTopology,setBondTopology)
intAccessor_h(reactingCenterStatus,setReactingCenterStatus)


@property (getter=bondKind,setter=setBondKind:) int bondKind;
@property (getter=notUsed,setter=setNotUsed:) int notUsed;
@property (getter=reactingCenterStatus,setter=setReactingCenterStatus:) int reactingCenterStatus;
@property (getter=bondTopology,setter=setBondTopology:) int bondTopology;
@property (getter=bondStereo,setter=setBondStereo:) int bondStereo;
@end
