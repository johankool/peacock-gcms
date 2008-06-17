//
//  JKBond.h
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
