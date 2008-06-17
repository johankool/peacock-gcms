//
//  JKAtom.m
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

#import "PKAtom.h"

@implementation PKAtom

- (void)encodeWithCoder:(NSCoder *)coder{
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

- (id)initWithCoder:(NSCoder *)coder{
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

@synthesize x;
@synthesize y;
@synthesize z;
@synthesize name;
@synthesize massDifference;
@synthesize charge;
@synthesize atomStereoParity;
@synthesize hydrogenCount;
@synthesize stereoCareBox;
@synthesize valence;
@synthesize H0Designator;
@synthesize notUsed1;
@synthesize notUsed2;
@synthesize atomAtomMappingNumber;
@synthesize inversionRetentionFlag;
@synthesize exactChangeFlag;

@end