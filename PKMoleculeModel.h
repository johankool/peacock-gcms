//
//  JKMoleculeModel.h
//  MoleculeView
//
//  Created by Johan Kool on Wed Dec 03 2003.
//  Copyright 2003-2007 Johan Kool. All rights reserved.
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
