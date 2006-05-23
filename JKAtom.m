//
//  JKAtom.m
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "JKAtom.h"
#import "AccessorMacros.h"

@implementation JKAtom

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInt:1 forKey:@"version"];
	[coder encodeFloat:x forKey:@"x"];
	[coder encodeFloat:y forKey:@"y"];
	[coder encodeFloat:z forKey:@"z"];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeInt:massDifference forKey:@"massDifference"];
	[coder encodeInt:charge forKey:@"charge"];
	[coder encodeInt:atomStereoParity forKey:@"atomStereoParity"];
	[coder encodeInt:hydrogenCount forKey:@"hydrogenCount"];
	[coder encodeInt:stereoCareBox forKey:@"stereoCareBox"];
	[coder encodeInt:valence forKey:@"valence"];
	[coder encodeInt:H0Designator forKey:@"H0Designator"];
	[coder encodeInt:notUsed1 forKey:@"notUsed1"];
	[coder encodeInt:notUsed2 forKey:@"notUsed2"];
	[coder encodeInt:atomAtomMappingNumber forKey:@"atomAtomMappingNumber"];
	[coder encodeInt:inversionRetentionFlag forKey:@"inversionRetentionFlag"];
	[coder encodeInt:exactChangeFlag forKey:@"exactChangeFlag"];
	
    return;
}

- (id)initWithCoder:(NSCoder *)coder
{
	x = [coder decodeFloatForKey:@"x"];
	y = [coder decodeFloatForKey:@"y"];
	z = [coder decodeFloatForKey:@"z"];
	name = [[coder decodeObjectForKey:@"name"] retain];
	massDifference = [coder decodeIntForKey:@"massDifference"];
	charge = [coder decodeIntForKey:@"charge"];
	atomStereoParity = [coder decodeIntForKey:@"atomStereoParity"];
	hydrogenCount = [coder decodeIntForKey:@"hydrogenCount"];
	stereoCareBox = [coder decodeIntForKey:@"stereoCareBox"];
	valence = [coder decodeIntForKey:@"valence"];
	H0Designator = [coder decodeIntForKey:@"H0Designator"];
	notUsed1 = [coder decodeIntForKey:@"notUsed1"];
	notUsed2 = [coder decodeIntForKey:@"notUsed2"];
	atomAtomMappingNumber = [coder decodeIntForKey:@"atomAtomMappingNumber"];
	inversionRetentionFlag = [coder decodeIntForKey:@"inversionRetentionFlag"];
	exactChangeFlag = [coder decodeIntForKey:@"exactChangeFlag"];
	
    return self;
}


floatAccessor(x,setX)
floatAccessor(y,setY)
floatAccessor(z,setZ)
idAccessor(name,setName)
intAccessor(massDifference, setMassDifference)
intAccessor(charge, setCharge)
intAccessor(atomStereoParity, setAtomStereoParity)
intAccessor(hydrogenCount, setHydrogenCount)
intAccessor(stereoCareBox, setStereoCareBox)
intAccessor(valence, setValence)
intAccessor(H0Designator, setH0Designator)
intAccessor(notUsed1, setNotUsed1)
intAccessor(notUsed2, setNotUsed2)
intAccessor(atomAtomMappingNumber, setAtomAtomMappingNumber)
intAccessor(inversionRetentionFlag, setInversionRetentionFlag)
intAccessor(exactChangeFlag, setExactChangeFlag)

@end
