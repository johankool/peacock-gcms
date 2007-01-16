//
//  JKBond.m
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "JKBond.h"
#import "AccessorMacros.h"

@implementation JKBond

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeInt:1 forKey:@"version"];
	[coder encodeObject:fromAtom forKey:@"fromAtom"];
	[coder encodeObject:toAtom forKey:@"toAtom"];
	[coder encodeInt:bondKind forKey:@"bondKind"];
	[coder encodeInt:bondStereo forKey:@"bondStereo"];
	[coder encodeInt:notUsed forKey:@"notUsed"];
	[coder encodeInt:bondTopology forKey:@"bondTopology"];
	[coder encodeInt:reactingCenterStatus forKey:@"reactingCenterStatus"];
	
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
	fromAtom = [[coder decodeObjectForKey:@"fromAtom"] retain];
	toAtom = [[coder decodeObjectForKey:@"toAtom"] retain];
	bondKind = [coder decodeIntForKey:@"bondKind"];
	bondStereo = [coder decodeIntForKey:@"bondStereo"];
	notUsed = [coder decodeIntForKey:@"notUsed"];
	bondTopology = [coder decodeIntForKey:@"bondTopology"];
	reactingCenterStatus = [coder decodeIntForKey:@"reactingCenterStatus"];
	
    return self;
}

idAccessor(fromAtom,setFromAtom)
idAccessor(toAtom,setToAtom)
intAccessor(bondKind,setBondKind)
intAccessor(bondStereo,setBondStereo)
intAccessor(notUsed,setNotUsed)
intAccessor(bondTopology,setBondTopology)
intAccessor(reactingCenterStatus,setReactingCenterStatus)
@end
