//
//  JKBond.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessorMacros.h"

#import "JKAtom.h"

@interface JKBond : NSObject <NSCoding> {
    JKAtom *fromAtom;
    JKAtom *toAtom;
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


@end
