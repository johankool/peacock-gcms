//
//  JKMoleculeModel.h
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
#import "AccessorMacros.h"
#import "PKAtom.h"
#import "PKBond.h"

@interface PKMoleculeModel : NSObject <NSCoding> {
    NSMutableArray *atoms;
    NSMutableArray *bonds;
	NSString *name, *comment;
}

- (id)initWithMoleculeString:(NSString *)inString;

- (NSRect)rectForBounds;
- (float)estimateLengthOfBonds;

idAccessor_h(atoms, setAtoms)
idAccessor_h(bonds, setBonds) 
idAccessor_h(name, setName)
idAccessor_h(comment, setComment)

@end
