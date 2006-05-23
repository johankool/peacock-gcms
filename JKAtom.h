//
//  JKAtom.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccessorMacros.h"

@interface JKAtom : NSObject <NSCoding> {
    float x;
    float y;
    float z; // ignored big time!! ;-)
	NSString *name;			// entry in periodic table or L for atom list, 
							// A, Q, * for unspecified atom, and LP for 
							// lone pair, or R# for Rgroup label [Generic, Query, 3D, Rgroup] 
	int massDifference;		//	Difference from mass in periodic table.
	int charge;
	int atomStereoParity;
	int hydrogenCount;
	BOOL stereoCareBox;
	int valence;
	BOOL H0Designator;
	int notUsed1;
	int notUsed2;
	int atomAtomMappingNumber;
	int inversionRetentionFlag;
	BOOL exactChangeFlag;
}

floatAccessor_h(x,setX)
floatAccessor_h(y,setY)
floatAccessor_h(z,setZ)
idAccessor_h(name,setName)
intAccessor_h(massDifference, setMassDifference)
intAccessor_h(charge, setCharge)
intAccessor_h(atomStereoParity, setAtomStereoParity)
intAccessor_h(hydrogenCount, setHydrogenCount)
intAccessor_h(stereoCareBox, setStereoCareBox)
intAccessor_h(valence, setValence)
intAccessor_h(H0Designator, setH0Designator)
intAccessor_h(notUsed1, setNotUsed1)
intAccessor_h(notUsed2, setNotUsed2)
intAccessor_h(atomAtomMappingNumber, setAtomAtomMappingNumber)
intAccessor_h(inversionRetentionFlag, setInversionRetentionFlag)
intAccessor_h(exactChangeFlag, setExactChangeFlag)

@end
