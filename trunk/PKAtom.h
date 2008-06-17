//
//  JKAtom.h
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

#import <Foundation/Foundation.h>

@interface PKAtom : NSObject <NSCoding> {
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

@property (copy) NSString *name;
@property (getter=stereoCareBox,setter=setStereoCareBox:) BOOL stereoCareBox;
@property (getter=exactChangeFlag,setter=setExactChangeFlag:) BOOL exactChangeFlag;
@property (getter=H0Designator,setter=setH0Designator:) BOOL H0Designator;
@property (getter=notUsed1,setter=setNotUsed1:) int notUsed1;
@property (getter=atomStereoParity,setter=setAtomStereoParity:) int atomStereoParity;
@property (getter=inversionRetentionFlag,setter=setInversionRetentionFlag:) int inversionRetentionFlag;
@property (getter=notUsed2,setter=setNotUsed2:) int notUsed2;
@property (getter=valence,setter=setValence:) int valence;
@property (getter=charge,setter=setCharge:) int charge;
@property (getter=atomAtomMappingNumber,setter=setAtomAtomMappingNumber:) int atomAtomMappingNumber;
@property (getter=x,setter=setX:) float x;
@property (getter=hydrogenCount,setter=setHydrogenCount:) int hydrogenCount;
@property (getter=massDifference,setter=setMassDifference:) int massDifference;
@property (getter=z,setter=setZ:) float z;
@property (getter=y,setter=setY:) float y;

@end
