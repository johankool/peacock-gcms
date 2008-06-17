//
//  JKBond.m
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

#import "PKBond.h"
#import "AccessorMacros.h"

@implementation PKBond

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

@synthesize fromAtom;
@synthesize toAtom;
@synthesize bondKind;
@synthesize bondStereo;
@synthesize notUsed;
@synthesize bondTopology;
@synthesize reactingCenterStatus;

@end
