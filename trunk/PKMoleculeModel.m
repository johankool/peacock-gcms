//
//  JKMoleculeModel.m
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

#import "PKMoleculeModel.h"
#import "AccessorMacros.h"
#import "PKAtom.h"
#import "PKBond.h"

@implementation PKMoleculeModel

- (id)init{
    atoms = [[NSMutableArray array] retain];
    bonds = [[NSMutableArray array] retain];
    return self;
}

- (id)initWithMoleculeString:(NSString *)inString{
	self = [super init];
	if (self != nil) {
		atoms = [[NSMutableArray array] retain];
		bonds = [[NSMutableArray array] retain];

		int i;
		int atomsCount, bondsCount, lineCount;
		NSArray *fileArray;
		
		fileArray = [inString componentsSeparatedByString:@"\n"];
		lineCount = [fileArray count];
		
		if (lineCount < 4) {
			return self;
		}
		// Read first 3 lines, the header lines
		[self setName:[fileArray objectAtIndex:0]];
		[self setComment:[fileArray objectAtIndex:2]];
		
		// Read line with counters
		atomsCount = [[[fileArray objectAtIndex:3] substringWithRange:NSMakeRange(0,3)] intValue];
		bondsCount = [[[fileArray objectAtIndex:3] substringWithRange:NSMakeRange(3,3)] intValue];
		//PKLogDebug(@"a %d, b %d", atomsCount, bondsCount);
		
		// Read atoms
		if (lineCount < atomsCount+4) {
			return self;
		}		
		for (i=4; i<atomsCount+4; i++) {
			PKAtom *atom = [[PKAtom alloc] init];
			[atom setX:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(0,10)] floatValue]];
			[atom setY:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(10,10)] floatValue]];
			[atom setZ:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(20,10)] floatValue]];
			[atom setName:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(30,3)] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
			[atom setMassDifference:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(33,2)] intValue]];
			[atom setCharge:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(35,3)] intValue]];
			[atom setAtomStereoParity:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(38,3)] intValue]];
			[atom setHydrogenCount:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(41,3)] intValue]];
			[atom setStereoCareBox:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(44,3)] intValue]];
			[atom setValence:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(47,3)] intValue]];
			[atom setH0Designator:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(50,3)] intValue]];
			[atom setNotUsed1:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(53,3)] intValue]];
			[atom setNotUsed2:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(56,3)] intValue]];
			[atom setAtomAtomMappingNumber:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(59,3)] intValue]];
			//		[atom setInversionRetentionFlag:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(62,3)] intValue]];
			//		[atom setExactChangeFlag:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(65,3)] intValue]];
			[[self atoms] addObject:atom];
			[atom release];
		}
		
		// Read bonds
		if (lineCount < bondsCount+atomsCount+4) {
			return self;
		}		
		for (i=4+atomsCount; i<bondsCount+atomsCount+4; i++) {
			PKBond *bond = [[PKBond alloc] init];
			[bond setFromAtom:[[self atoms] objectAtIndex:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(0,3)] intValue]-1]];
			[bond setToAtom:[[self atoms] objectAtIndex:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(3,3)] intValue]-1]];
			[bond setBondKind:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(6,3)] intValue]];
			[bond setBondStereo:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(9,3)] intValue]];
			[bond setNotUsed:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(12,3)] intValue]];
			[bond setBondTopology:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(15,3)] intValue]];
			[bond setReactingCenterStatus:[[[fileArray objectAtIndex:i] substringWithRange:NSMakeRange(18,3)] intValue]];
			[[self bonds] addObject:bond];
			[bond release];
		}
		
		// There might be more coming! But we'll deal with that later.
		
		// We did it!	
	}
	return self;
}

	

- (NSRect)rectForBounds {
	// This doesn't take into account space needed for actually drawing a label!
	NSArray *xValues;
	NSArray *yValues;
	float minX, minY, maxX, maxY;
	int i, countX, countY;
	
	xValues = [[self atoms] valueForKey:@"x"];
	countX = [xValues count];
	maxX = [[xValues objectAtIndex:0] floatValue];
	minX = [[xValues objectAtIndex:0] floatValue];
	for (i=1; i<countX; i++) {
		if ([[xValues objectAtIndex:i] floatValue] > maxX) {
			maxX = [[xValues objectAtIndex:i] floatValue];
		}
		if ([[xValues objectAtIndex:i] floatValue] < minX) {
			minX = [[xValues objectAtIndex:i] floatValue];
		}
	}
	
	yValues = [[self atoms] valueForKey:@"y"];
	countY = [yValues count];
	maxY = [[yValues objectAtIndex:0] floatValue];
	minY = [[yValues objectAtIndex:0] floatValue];
	for (i=1; i<countY; i++) {
		if ([[yValues objectAtIndex:i] floatValue] > maxY) {
			maxY = [[yValues objectAtIndex:i] floatValue];
		}
		if ([[yValues objectAtIndex:i] floatValue] < minY) {
			minY = [[yValues objectAtIndex:i] floatValue];
		}
	}
	
	return NSMakeRect(minX,minY,maxX-minX,maxY-minY);
} 

- (float)estimateLengthOfBonds {
	// An estimate of the length of the bonds in the coordinate system used. The view can base the size of the labels and the width between double bonds using this value.
	// We simply return the value of the first bond for now.
	float fromX, fromY, toX, toY;

	fromX = [[[bonds objectAtIndex:0] fromAtom] x];
	fromY = [[[bonds objectAtIndex:0] fromAtom] y];
	toX = [[[bonds objectAtIndex:0] toAtom] x];
	toY = [[[bonds objectAtIndex:0] toAtom] y];
	
	return sqrt(pow((toX-fromX),2)+pow((toY-fromY),2));
}

- (void)encodeWithCoder:(NSCoder *)coder{
	[coder encodeInt:1 forKey:@"version"];
	[coder encodeObject:atoms forKey:@"atoms"];
	[coder encodeObject:bonds forKey:@"bonds"];
	[coder encodeObject:name forKey:@"name"];
	[coder encodeObject:comment forKey:@"comment"];
    return;
}

- (id)initWithCoder:(NSCoder *)coder{
	atoms = [[coder decodeObjectForKey:@"atoms"] retain];
	bonds = [[coder decodeObjectForKey:@"bonds"] retain];
	name = [[coder decodeObjectForKey:@"name"] retain];
	comment = [[coder decodeObjectForKey:@"comment"] retain];
    return self;
}

idAccessor(atoms, setAtoms)
idAccessor(bonds, setBonds)
idAccessor(name, setName)
idAccessor(comment, setComment)

@end
